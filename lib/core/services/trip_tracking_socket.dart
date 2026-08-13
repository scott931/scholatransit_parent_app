import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config/api_endpoints.dart';
import 'storage_service.dart';

/// Live trip feed over the backend's Channels socket.
///
/// The driver's GPS POST fans out to the `trip_<trip_id>` group, which the
/// backoffice has consumed since day one; parents were left polling `/status/`
/// every 2 s per device. This is the same socket, same auth, same payloads —
/// see `scholatransit_backoffice/src/lib/trackingWebSocket.js` for the sibling
/// implementation the contract is shared with.
///
/// Two things the JS client does not have to worry about, which shape this one:
///
/// 1. **Ticks are partial.** The server broadcasts twice per fix: a fast one
///    carrying only lat/lng (so the marker moves before any DB work), then an
///    enriched one adding `next_stop` / `navigation` / `eta_chain`. Missing keys
///    mean "unchanged", *not* "cleared", so [TripFeedUpdate] leaves them null
///    and the consumer keeps its last value.
/// 2. **A phone loses its network constantly.** REST polling stays as a
///    fallback, but slowed to a heartbeat while the socket is healthy.
class TripFeedUpdate {
  TripFeedUpdate({
    required this.tripId,
    required this.receivedAt,
    this.latitude,
    this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    this.timestamp,
    this.nextStop,
    this.navigation,
    this.etaChain,
    this.myStop,
    this.stopEvent,
    this.source = TripFeedSource.socket,
    this.navigationAuthoritative = false,
  });

  final String tripId;

  /// Wall-clock receipt time, used to merge socket vs REST (newest wins).
  final DateTime receivedAt;

  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;

  /// Server-side timestamp of the fix, when the payload carried one.
  final DateTime? timestamp;

  /// Null means "this tick said nothing about it" — keep the previous value.
  final Map<String, dynamic>? nextStop;
  final Map<String, dynamic>? navigation;
  final List<Map<String, dynamic>>? etaChain;

  /// Only ever arrives from REST — the WS group is per trip, not per user.
  final Map<String, dynamic>? myStop;

  /// Set on `trip.stop_update` frames (arrived / departed / skipped).
  final Map<String, dynamic>? stopEvent;

  final TripFeedSource source;

  /// True when a null [navigation] means "there is no leg" rather than "this
  /// tick didn't mention it".
  ///
  /// `/status/` always includes the key, so REST can clear a drawn polyline.
  /// Socket ticks omit it unless the geometry changed, so they never can —
  /// without this flag every position-only frame would erase the road line.
  final bool navigationAuthoritative;

  bool get hasPosition => latitude != null && longitude != null;
}

enum TripFeedSource { socket, rest }

enum TripFeedStatus { idle, connecting, live, degraded }

/// Turns `ApiEndpoints.baseUrl` into the matching ws:// or wss:// origin.
///
/// The base URL is a plain HTTP origin with a trailing slash
/// (`http://host:8001/`), so scheme-swap and append rather than parse-and-rebuild.
String _wsOriginFromBaseUrl() {
  var base = ApiEndpoints.baseUrl.trim();
  if (base.endsWith('/')) base = base.substring(0, base.length - 1);
  if (base.startsWith('https://')) {
    return 'wss://${base.substring(8)}';
  }
  if (base.startsWith('http://')) {
    return 'ws://${base.substring(7)}';
  }
  return 'ws://$base';
}

class TripTrackingSocket {
  TripTrackingSocket({
    required this.tripId,
    required this.onUpdate,
    this.onStatusChange,
    this.baseReconnectDelay = const Duration(seconds: 2),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.silenceTimeout = const Duration(seconds: 45),
  });

  final String tripId;
  final void Function(TripFeedUpdate update) onUpdate;
  final void Function(TripFeedStatus status)? onStatusChange;

  final Duration baseReconnectDelay;
  final Duration maxReconnectDelay;

  /// A bus at a red light is legitimately silent, but a socket that has heard
  /// nothing this long is more likely half-open than parked. Reconnect rather
  /// than trust it — a TCP connection can stay "open" long after it is dead.
  final Duration silenceTimeout;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _silenceTimer;
  int _attempt = 0;
  bool _closed = false;
  TripFeedStatus _status = TripFeedStatus.idle;

  TripFeedStatus get status => _status;
  bool get isLive => _status == TripFeedStatus.live;

  void _setStatus(TripFeedStatus next) {
    if (_status == next) return;
    _status = next;
    onStatusChange?.call(next);
  }

  Future<void> connect() async {
    if (_closed) return;
    _cancelReconnect();
    _setStatus(TripFeedStatus.connecting);

    final token = StorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      // No credentials yet (cold start racing auth restore). Don't spin — the
      // REST fallback keeps the map alive and the next retry will have a token.
      _scheduleReconnect();
      return;
    }

    final url =
        '${_wsOriginFromBaseUrl()}/ws/tracking/trips/$tripId/'
        '?token=${Uri.encodeComponent(token)}';

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;

      // `ready` completes on a successful handshake and throws on rejection,
      // which is how we tell "server said 4403" from "Wi-Fi is down".
      await channel.ready;
      if (_closed) {
        await channel.sink.close(ws_status.goingAway);
        return;
      }

      _attempt = 0;
      _setStatus(TripFeedStatus.live);
      _armSilenceTimer();

      _subscription = channel.stream.listen(
        _handleFrame,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (e) {
      _channel = null;
      _handleDisconnect();
    }
  }

  void _handleFrame(dynamic raw) {
    _armSilenceTimer();
    if (_status != TripFeedStatus.live) _setStatus(TripFeedStatus.live);

    final update = parseFrame(raw, tripId);
    if (update != null) onUpdate(update);
  }

  /// Parses one socket frame. Returns null for control frames and anything
  /// addressed to a different trip.
  ///
  /// Static and public so the payload contract can be tested without a socket.
  static TripFeedUpdate? parseFrame(dynamic raw, String expectedTripId) {
    Map<String, dynamic> data;
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      data = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }

    final type = data['type']?.toString().toLowerCase() ?? '';
    if (type == 'ping' ||
        type == 'pong' ||
        type == 'heartbeat' ||
        type == 'tracking.connected' ||
        type == 'tracking.resynced') {
      return null;
    }

    // The per-trip consumer only ever sends this trip's frames, but the
    // all-trips consumer shares the payload shape — guard so a future switch to
    // `/ws/tracking/` can't quietly render another child's bus.
    final frameTripId = data['trip_id']?.toString();
    if (frameTripId != null &&
        frameTripId.isNotEmpty &&
        frameTripId != expectedTripId) {
      return null;
    }

    if (type == 'trip.stop_update') {
      return TripFeedUpdate(
        tripId: expectedTripId,
        receivedAt: DateTime.now(),
        stopEvent: data['stop'] is Map
            ? Map<String, dynamic>.from(data['stop'] as Map)
            : null,
        nextStop: data['next_stop'] is Map
            ? Map<String, dynamic>.from(data['next_stop'] as Map)
            : null,
      );
    }

    final location = data['location'] is Map
        ? Map<String, dynamic>.from(data['location'] as Map)
        : null;

    return TripFeedUpdate(
      tripId: expectedTripId,
      receivedAt: DateTime.now(),
      latitude: _toDouble(data['latitude'] ?? location?['latitude']),
      longitude: _toDouble(data['longitude'] ?? location?['longitude']),
      speed: _toDouble(data['speed']),
      heading: _toDouble(data['heading']),
      accuracy: _toDouble(data['accuracy']),
      timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? ''),
      nextStop: data['next_stop'] is Map
          ? Map<String, dynamic>.from(data['next_stop'] as Map)
          : null,
      navigation: data['navigation'] is Map
          ? Map<String, dynamic>.from(data['navigation'] as Map)
          : null,
      etaChain: _toChain(data['eta_chain']),
    );
  }

  static List<Map<String, dynamic>>? _toChain(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Numbers cross the wire as strings on some fields (`speed`, `heading` are
  /// stringified Decimals server-side) and as numbers on others.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  void _armSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(silenceTimeout, () {
      // Treat prolonged silence as a dead link, not a parked bus.
      _handleDisconnect();
    });
  }

  void _handleDisconnect() {
    if (_closed) return;
    _teardownChannel();
    _setStatus(TripFeedStatus.degraded);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _cancelReconnect();

    // Exponential backoff with jitter, mirroring the backoffice client so a
    // backend restart doesn't get a synchronised stampede from every device.
    final expMs = math.min(
      maxReconnectDelay.inMilliseconds,
      baseReconnectDelay.inMilliseconds * math.pow(2, _attempt).toInt(),
    );
    final jitter = (expMs * 0.1 * math.Random().nextDouble()).round();
    final delay = Duration(milliseconds: (expMs * 0.9).round() + jitter);
    _attempt++;

    _reconnectTimer = Timer(delay, connect);
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _teardownChannel() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close(ws_status.goingAway);
    } catch (_) {
      /* already gone */
    }
    _channel = null;
  }

  /// Pause without forgetting the trip — used when the map goes to background.
  void suspend() {
    _cancelReconnect();
    _teardownChannel();
    _setStatus(TripFeedStatus.idle);
    _attempt = 0;
  }

  Future<void> dispose() async {
    _closed = true;
    _cancelReconnect();
    _teardownChannel();
    _setStatus(TripFeedStatus.idle);
  }
}
