import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_config.dart';
import 'storage_service.dart';

/// Countdown alerts as the bus closes on the parent's own stop.
///
/// Fires at 30 / 20 / 10 / 5 minutes out and again on arrival, each with a
/// louder vibration than the last, so a parent can tell how urgent it is from a
/// pocket without looking at the screen.
///
/// **Why this exists client-side at all**, when the backend already pushes the
/// same thresholds over FCM: a push is a best-effort delivery on someone else's
/// infrastructure. When the map is open and the socket is live, the app already
/// knows the ETA to the second — waiting on a round trip through FCM to buzz the
/// phone would be slower and would fail outright on a device with a stale token.
/// So both fire, and both debounce against the same [alertKey], first one wins.
/// See `stop_progress._send_proximity_alert`, which stamps `alert_key` into the
/// push data for exactly this handshake.
class EtaAlertService {
  EtaAlertService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Dedicated channel so a parent can silence chat without silencing "your
  /// child's bus is here", and so the vibration pattern below is honoured.
  static const String channelId = 'go_drop_bus_eta_channel';
  static const String channelName = 'Bus arrival alerts';
  static const String channelDescription =
      'Countdown and arrival alerts for your child\'s school bus';

  /// Minutes-out ladder, descending. Must match `ETA_ALERT_THRESHOLD_MINUTES`
  /// in the backend settings, or the two sides will debounce on different keys
  /// and a parent gets each alert twice.
  static const List<int> thresholdMinutes = [30, 20, 10, 5];

  static const String _firedKeysStorageKey = 'eta_alert_fired_keys';

  /// Alert keys already fired, in `tripId:stopId:threshold` form. Held in memory
  /// for the hot path and mirrored to storage so an app restart mid-trip does
  /// not replay the whole ladder.
  static final Set<String> _fired = <String>{};
  static bool _loaded = false;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _createChannel();
      await _loadFiredKeys();
      _initialized = true;
    } catch (e) {
      debugPrint('❌ EtaAlertService: init failed: $e');
    }
  }

  static Future<void> _createChannel() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    // No custom sound asset: the channel uses the device's default alert tone,
    // which is already the sound this user has chosen to react to. A bundled
    // chime would also be frozen at install time — Android caches channel sound
    // on creation, so changing it later needs a new channel id anyway.
    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await android.createNotificationChannel(channel);
  }

  static Future<void> _loadFiredKeys() async {
    if (_loaded) return;
    try {
      final stored = StorageService.getStringList(_firedKeysStorageKey);
      if (stored != null) _fired.addAll(stored);
    } catch (e) {
      debugPrint('⚠️ EtaAlertService: could not restore fired keys: $e');
    }
    _loaded = true;
  }

  static Future<void> _persistFiredKeys() async {
    try {
      // Cap the history — one trip is a handful of keys, but a device that runs
      // for months would otherwise accumulate them forever.
      final keys = _fired.toList();
      final trimmed = keys.length > 200
          ? keys.sublist(keys.length - 200)
          : keys;
      await StorageService.setStringList(_firedKeysStorageKey, trimmed);
    } catch (e) {
      debugPrint('⚠️ EtaAlertService: could not persist fired keys: $e');
    }
  }

  static String alertKey(String tripId, Object stopId, String threshold) =>
      '$tripId:$stopId:$threshold';

  /// Marks a key fired without alerting — used when an FCM push for the same
  /// threshold lands first, so the local alert doesn't double-buzz.
  static Future<void> claim(String key) async {
    await _loadFiredKeys();
    if (_fired.add(key)) await _persistFiredKeys();
  }

  static bool hasFired(String key) => _fired.contains(key);

  /// Feed the live ETA to the parent's own stop. Call on every position update;
  /// it decides for itself whether anything is worth alerting about.
  ///
  /// [etaSeconds] is the countdown to *this parent's* stop (from `my_stop`, or
  /// resolved out of `eta_chain`), not to the bus's next stop.
  static Future<void> onEtaUpdate({
    required String tripId,
    required Object stopId,
    required String stopName,
    required int etaSeconds,
    String? childName,
    bool arrived = false,
  }) async {
    if (!_initialized) await init();
    await _loadFiredKeys();

    if (arrived) {
      await _fire(
        key: alertKey(tripId, stopId, 'arrived'),
        title: '🚌 Bus at the stop',
        body: childName != null
            ? 'The bus has arrived at $stopName for $childName.'
            : 'The bus has arrived at $stopName.',
        pattern: _vibrationFor(null),
      );
      return;
    }

    if (etaSeconds < 0) return;
    final etaMinutes = etaSeconds / 60.0;

    // Same "tightest rung wins" rule the backend uses: a bus can cross several
    // thresholds between two fixes (traffic clearing, a gap in GPS), and firing
    // 30/20/10 back to back would be three buzzes describing one moment.
    final due = thresholdMinutes
        .where((m) => etaMinutes <= m && !_fired.contains(alertKey(tripId, stopId, 'eta_$m')))
        .toList();
    if (due.isEmpty) return;

    final tightest = due.reduce((a, b) => a < b ? a : b);
    for (final minutes in due) {
      if (minutes != tightest) {
        _fired.add(alertKey(tripId, stopId, 'eta_$minutes'));
      }
    }

    // Report the *measured* ETA, not the rung. A bus first seen at 25 min out
    // trips the 30-minute rung, and "Bus 30 min away" over a map showing 25
    // teaches parents the number is decorative. The rung only picks the haptics.
    final shown = (etaSeconds / 60).round().clamp(1, 999);
    await _fire(
      key: alertKey(tripId, stopId, 'eta_$tightest'),
      title: '🚌 Bus $shown min away',
      body: childName != null
          ? 'The bus is about $shown min from $stopName for $childName.'
          : 'The bus is about $shown min from $stopName.',
      pattern: _vibrationFor(tightest),
    );
    await _persistFiredKeys();
  }

  /// Escalating haptics: a long-range heads-up is one soft buzz; arrival is an
  /// insistent triple. The parent learns the pattern without reading anything.
  static Int64List _vibrationFor(int? minutes) {
    // Pairs of (pause, buzz) in ms, starting with an initial pause of 0.
    switch (minutes) {
      case 30:
        return Int64List.fromList([0, 250]);
      case 20:
        return Int64List.fromList([0, 350]);
      case 10:
        return Int64List.fromList([0, 300, 150, 300]);
      case 5:
        return Int64List.fromList([0, 400, 150, 400]);
      default: // arrived
        return Int64List.fromList([0, 500, 200, 500, 200, 500]);
    }
  }

  static Future<void> _fire({
    required String key,
    required String title,
    required String body,
    required Int64List pattern,
  }) async {
    if (_fired.contains(key)) return;
    _fired.add(key);
    await _persistFiredKeys();

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: pattern,
        enableLights: true,
        color: const Color(0xFF0052CC),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await _notifications.show(
        key.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'bus_proximity:$key',
      );
      debugPrint('🔔 EtaAlertService: fired $key');
    } catch (e) {
      debugPrint('❌ EtaAlertService: failed to fire $key: $e');
    }
  }

  /// Show an alert that originated from an FCM push rather than the live feed.
  ///
  /// The caller has already claimed the dedupe key, so this skips the
  /// `_fired` bookkeeping and just renders on the alert channel with the
  /// vibration pattern matching the threshold the backend fired.
  static Future<void> showFromPush({
    required String title,
    required String body,
    required String threshold,
    String? payload,
  }) async {
    if (!_initialized) await init();

    int? minutes;
    if (threshold.startsWith('eta_')) {
      minutes = int.tryParse(threshold.substring(4));
    } else if (threshold == 'approaching') {
      // Distance-based rung, roughly a kilometre out — treat as a soft heads-up.
      minutes = 30;
    } else if (threshold == 'arriving') {
      minutes = 5;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationFor(minutes),
        enableLights: true,
        color: const Color(0xFF0052CC),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await _notifications.show(
        (payload ?? title + body).hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ EtaAlertService: failed to show push alert: $e');
    }
  }

  /// Drop a finished trip's keys so the same stop can alert again tomorrow.
  static Future<void> clearTrip(String tripId) async {
    await _loadFiredKeys();
    final before = _fired.length;
    _fired.removeWhere((key) => key.startsWith('$tripId:'));
    if (_fired.length != before) await _persistFiredKeys();
  }

  /// Test/debug hook — forget everything without touching a real trip's state.
  @visibleForTesting
  static void resetForTest() {
    _fired.clear();
    _loaded = false;
    _initialized = false;
  }
}

/// Kept here so the channel id is defined once and `AppConfig` stays the place
/// people look for it.
extension EtaAlertConfig on AppConfig {
  static String get etaChannelId => EtaAlertService.channelId;
}
