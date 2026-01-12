import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

// Background notification handler (must be top-level function)
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  print('Background notification tapped: ${response.payload}');
}

// Background message handler (must be top-level function)
// This runs in a separate isolate, so we need to initialize everything here
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message received: ${message.messageId}');
  print('📱 Title: ${message.notification?.title}');
  print('📱 Body: ${message.notification?.body}');
  print('📱 Data: ${message.data}');
  
  // Initialize local notifications plugin in background isolate
  final FlutterLocalNotificationsPlugin localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Initialize Android notification channel and settings
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('📱 Background notification tapped: ${response.payload}');
    },
  );
  
  // Create notification channel for Android
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }
  
  // Show notification for background messages
  if (message.notification != null) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      enableLights: true,
      color: Color(0xFF0052CC),
      styleInformation: BigTextStyleInformation(''),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await localNotifications.show(
      message.hashCode,
      message.notification!.title ?? 'Notification',
      message.notification!.body ?? '',
      details,
      payload: message.data.toString(),
    );
    print('✅ Background notification displayed');
  } else if (message.data.isNotEmpty) {
    // Handle data-only messages (no notification payload)
    // Extract title and body from data if available
    final title = message.data['title'] ?? 'New Notification';
    final body = message.data['body'] ?? message.data['message'] ?? 'You have a new message';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      channelShowBadge: true,
      enableLights: true,
      color: Color(0xFF0052CC),
      styleInformation: BigTextStyleInformation(''),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await localNotifications.show(
      message.hashCode,
      title.toString(),
      body.toString(),
      details,
      payload: message.data.toString(),
    );
    print('✅ Background data-only notification displayed');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static FirebaseMessaging? _firebaseMessaging;
  static String? _fcmToken;

  static Future<void> init() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _requestNotificationPermission();
  }

  static Future<void> _initializeFirebaseMessaging() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Request permission for iOS
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        print('📱 FCM Permission status: ${settings.authorizationStatus}');
      }

      // Note: Background message handler should be registered in main.dart
      // before Firebase.initializeApp() is called
      // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get FCM token
      await _refreshFCMToken();

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        print('📱 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        registerDeviceToken(newToken);
      });

      print('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Firebase Messaging: $e');
    }
  }

  static Future<void> _refreshFCMToken() async {
    try {
      final token = await _firebaseMessaging?.getToken();
      if (token != null) {
        _fcmToken = token;
        print('📱 FCM Token: $token');
        await registerDeviceToken(token);
      }
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message received: ${message.messageId}');
    print('📱 Title: ${message.notification?.title}');
    print('📱 Body: ${message.notification?.body}');
    print('📱 Data: ${message.data}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
        id: message.hashCode,
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped: ${message.messageId}');
    print('📱 Data: ${message.data}');
    // Handle navigation based on notification data
    // This can be extended to navigate to specific screens
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    // Create notification channel for Android (required for background notifications)
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// Create notification channel for Android (required for showing notifications in background)
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDescription,
      importance: Importance.high, // High importance for popup notifications
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print('⚠️ Notification permission not granted');
    } else {
      print('✅ Notification permission granted');
    }
  }

  static Future<void> registerDeviceToken(String token) async {
    try {
      await ApiService.post(
        AppConfig.deviceTokenEndpoint,
        data: {
          'device_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        },
      );
    } catch (_) {}
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    // Handle notification tap
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // Ensure notifications show even when app is in background
      channelShowBadge: true,
      fullScreenIntent: false,
      // Make notification sticky/persistent
      ongoing: false,
      autoCancel: true,
      // Enable heads-up notification (popup style) - shows as popup even when app is in background
      enableLights: true,
      color: Color(0xFF0052CC),
      // These settings ensure notification appears as popup in background
      styleInformation: BigTextStyleInformation(''),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> showTripNotification({
    required String title,
    required String body,
    String? tripId,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: tripId,
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    );
  }

  static Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? emergencyId,
  }) async {
    try {
      print('🔔 DEBUG: Showing emergency notification: $title');
      await showLocalNotification(
        title: title,
        body: body,
        payload: emergencyId,
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      );
      print('🔔 DEBUG: Emergency notification shown successfully');
    } catch (e) {
      print('🔔 DEBUG: Failed to show emergency notification: $e');
      rethrow;
    }
  }

  static Future<void> showStudentStatusNotification({
    required String studentName,
    required String status,
    String? tripId,
  }) async {
    await showLocalNotification(
      title: 'Student Status Update',
      body: '$studentName: $status',
      payload: tripId,
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppConfig.notificationChannelId,
          AppConfig.notificationChannelName,
          channelDescription: AppConfig.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<String?> getFCMToken() async {
    try {
      if (_fcmToken != null) {
        return _fcmToken;
      }
      final token = await _firebaseMessaging?.getToken();
      if (token != null) {
        _fcmToken = token;
        return token;
      }
      return null;
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging?.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging?.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Delete FCM token (for logout)
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging?.deleteToken();
      _fcmToken = null;
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ Failed to delete FCM token: $e');
    }
  }
}
