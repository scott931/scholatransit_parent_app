import 'dart:io' show Platform;
import 'dart:convert' show jsonEncode, jsonDecode;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import 'notification_navigation_service.dart';

// Background notification handler (must be top-level function)
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  print('Background notification tapped: ${response.payload}');
}

// Background message handler (must be top-level function)
// This runs in a separate isolate, so we need to initialize everything here
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase - handle case where it might already be initialized
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized in background handler');
    } catch (e) {
      // Firebase might already be initialized, which is fine
      if (e.toString().contains('already been initialized') || 
          e.toString().contains('already initialized')) {
        print('ℹ️ Firebase already initialized, continuing...');
      } else {
        print('⚠️ Firebase initialization error (non-critical): $e');
        // Continue anyway - Firebase might still work
      }
    }
    
    print('═══════════════════════════════════════════════════════════');
    print('📱 BACKGROUND NOTIFICATION RECEIVED');
    print('═══════════════════════════════════════════════════════════');
    print('📱 Message ID: ${message.messageId}');
    print('📱 Sent Time: ${message.sentTime}');
    print('📱 Message Type: ${message.messageType}');
    print('📱 From: ${message.from}');
    print('📱 Collapse Key: ${message.collapseKey}');
    print('📱 Notification Title: ${message.notification?.title}');
    print('📱 Notification Body: ${message.notification?.body}');
    print('📱 Notification Android Channel ID: ${message.notification?.android?.channelId}');
    print('📱 Notification Android Click Action: ${message.notification?.android?.clickAction}');
    print('📱 Data Payload:');
    message.data.forEach((key, value) {
      print('   - $key: $value (${value.runtimeType})');
    });
    print('═══════════════════════════════════════════════════════════');
    
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
    
    // Initialize local notifications - handle errors gracefully
    try {
      final initialized = await localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📱 Background notification tapped: ${response.payload}');
        },
      );
      print('✅ Local notifications initialized: $initialized');
    } catch (e) {
      print('❌ Failed to initialize local notifications: $e');
      // Continue anyway - might still work
    }
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      try {
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
        print('✅ Notification channel created');
      } catch (e) {
        print('⚠️ Failed to create notification channel: $e');
        // Continue anyway - channel might already exist
      }
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
    
    // CRITICAL: Extract title and body BEFORE creating payload
    // Try multiple sources: notification payload first, then data payload
    // IMPORTANT: Check ALL possible locations for body to ensure we capture it
    final notificationTitle = message.notification?.title ?? 
                           message.data['title']?.toString() ??
                           message.data['notification_title']?.toString() ??
                           'Notification';
    
    // CRITICAL: Try EVERY possible source for body - this is the key fix
    final notificationBody = message.notification?.body ?? 
                            message.data['body']?.toString() ??
                            message.data['message']?.toString() ??
                            message.data['notification_body']?.toString() ??
                            message.data['description']?.toString() ??
                            message.data['text']?.toString() ??
                            message.data['content']?.toString() ??
                            '';
    
    print('═══════════════════════════════════════════════════════════');
    print('📱 CREATING BACKGROUND NOTIFICATION PAYLOAD');
    print('═══════════════════════════════════════════════════════════');
    print('   - message.notification?.title: ${message.notification?.title}');
    print('   - message.notification?.body: ${message.notification?.body}');
    print('   - message.data[\'title\']: ${message.data['title']}');
    print('   - message.data[\'body\']: ${message.data['body']}');
    print('   - message.data[\'message\']: ${message.data['message']}');
    print('   - message.data[\'notification_body\']: ${message.data['notification_body']}');
    print('   - message.data[\'description\']: ${message.data['description']}');
    print('   - message.data[\'text\']: ${message.data['text']}');
    print('   - message.data[\'content\']: ${message.data['content']}');
    print('   - Final Title: "$notificationTitle" (length: ${notificationTitle.length})');
    print('   - Final Body: "$notificationBody" (length: ${notificationBody.length})');
    print('   - Body is null: ${message.notification?.body == null}');
    print('   - Body isEmpty: ${notificationBody.isEmpty}');
    print('═══════════════════════════════════════════════════════════');
    
    // Create a comprehensive payload with all notification data
    // CRITICAL: Always store title and body at top level AND in data for redundancy
    final payload = {
      'messageId': message.messageId,
      'title': notificationTitle, // Use extracted value, not null-coalesced
      'body': notificationBody, // Use extracted value, ensure it's not null
      'notification_title': notificationTitle, // Redundant storage
      'notification_body': notificationBody, // Redundant storage
      'message': notificationBody, // Also store as 'message' for compatibility
      'data': {
        ...message.data,
        // CRITICAL: Ensure body is in data map too, even if it's in message.data
        'title': notificationTitle,
        'body': notificationBody,
        'message': notificationBody,
        'notification_title': notificationTitle,
        'notification_body': notificationBody,
      },
      'sentTime': message.sentTime?.toIso8601String(),
      'from': message.from,
    };
    
    // CRITICAL: Verify payload before encoding
    print('📱 Payload before encoding:');
    print('   - payload[\'title\']: "${payload['title']}"');
    print('   - payload[\'body\']: "${payload['body']}"');
    print('   - payload[\'notification_body\']: "${payload['notification_body']}"');
    print('   - payload[\'message\']: "${payload['message']}"');
    print('   - payload[\'data\'][\'body\']: "${(payload['data'] as Map)['body']}"');
    print('   - payload[\'body\'] type: ${payload['body'].runtimeType}');
    print('   - payload[\'body\'] isEmpty: ${(payload['body'] as String).isEmpty}');
    
    // Encode payload as JSON for reliable parsing
    final payloadJson = jsonEncode(payload);
    
    // CRITICAL: Verify payload after encoding - decode to check it's correct
    try {
      final decodedCheck = jsonDecode(payloadJson) as Map<String, dynamic>;
      print('📱 Payload verification after encoding:');
      print('   - decoded[\'title\']: "${decodedCheck['title']}"');
      print('   - decoded[\'body\']: "${decodedCheck['body']}"');
      print('   - decoded[\'data\'][\'body\']: "${(decodedCheck['data'] as Map)['body']}"');
    } catch (e) {
      print('⚠️ Could not verify payload after encoding: $e');
    }
    
    print('📱 Payload JSON: $payloadJson');
    print('📱 Payload JSON length: ${payloadJson.length}');
    
    // Show notification - wrap in try-catch to handle errors
    try {
      await localNotifications.show(
        message.hashCode,
        notificationTitle,
        notificationBody,
        details,
        payload: payloadJson,
      );
      print('✅ Background notification displayed');
      print('📱 Notification ID: ${message.hashCode}');
      print('📱 Displayed title: "$notificationTitle"');
      print('📱 Displayed body: "$notificationBody"');
      print('📱 Payload stored: $payload');
    } catch (e, stackTrace) {
      print('❌ Failed to show background notification: $e');
      print('❌ Stack trace: $stackTrace');
      // Re-throw to let Firebase know it failed
      rethrow;
    }
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
    
    // Create a comprehensive payload with all notification data
    final payload = {
      'messageId': message.messageId,
      'title': title.toString(),
      'body': body.toString(),
      'data': message.data,
      'sentTime': message.sentTime?.toIso8601String(),
      'from': message.from,
    };
    
    // Encode payload as JSON for reliable parsing
    final payloadJson = jsonEncode(payload);
    
    // Show notification - wrap in try-catch to handle errors
    try {
      await localNotifications.show(
        message.hashCode,
        title.toString(),
        body.toString(),
        details,
        payload: payloadJson,
      );
      print('✅ Background data-only notification displayed');
      print('📱 Notification ID: ${message.hashCode}');
      print('📱 Payload: $payload');
    } catch (e, stackTrace) {
      print('❌ Failed to show background data-only notification: $e');
      print('❌ Stack trace: $stackTrace');
      // Re-throw to let Firebase know it failed
      rethrow;
    }
  } else {
    print('⚠️ Background message has no notification payload or data');
  }
  } catch (e, stackTrace) {
    // Catch any unexpected errors in the background handler
    print('❌❌❌ CRITICAL ERROR in background notification handler ❌❌❌');
    print('❌ Error: $e');
    print('❌ Stack trace: $stackTrace');
    print('❌ Message ID: ${message.messageId}');
    print('❌ This error will be logged but notification may still be shown by system');
    // Don't rethrow - we don't want to crash the background isolate
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
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ iOS notification permission granted');
        } else {
          print('⚠️ iOS notification permission: ${settings.authorizationStatus}');
        }
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

  static void _handleForegroundMessage(RemoteMessage message) async {
    print('═══════════════════════════════════════════════════════════');
    print('📱 FOREGROUND NOTIFICATION RECEIVED');
    print('═══════════════════════════════════════════════════════════');
    print('📱 Message ID: ${message.messageId}');
    print('📱 Sent Time: ${message.sentTime}');
    print('📱 Message Type: ${message.messageType}');
    print('📱 From: ${message.from}');
    print('📱 Notification Title: ${message.notification?.title}');
    print('📱 Notification Body: ${message.notification?.body}');
    print('📱 Data Payload:');
    message.data.forEach((key, value) {
      print('   - $key: $value (${value.runtimeType})');
    });
    print('═══════════════════════════════════════════════════════════');

    // CRITICAL: Extract body from BOTH notification payload AND data payload
    // This ensures we capture the body regardless of where it's stored
    final notificationTitle = message.notification?.title ?? 
                           message.data['title']?.toString() ??
                           message.data['notification_title']?.toString() ??
                           'Notification';
    
    final notificationBody = message.notification?.body ?? 
                          message.data['body']?.toString() ??
                          message.data['message']?.toString() ??
                          message.data['notification_body']?.toString() ??
                          message.data['description']?.toString() ??
                          message.data['text']?.toString() ??
                          message.data['content']?.toString() ??
                          '';
    
    print('📱 Extracted from foreground message:');
    print('   - Title: "$notificationTitle"');
    print('   - Body: "$notificationBody" (length: ${notificationBody.length})');
    
    // Create comprehensive payload with body stored in multiple places
    final payload = {
      'messageId': message.messageId,
      'title': notificationTitle,
      'body': notificationBody,
      'notification_title': notificationTitle,
      'notification_body': notificationBody,
      'message': notificationBody,
      'data': {
        ...message.data,
        'title': notificationTitle,
        'body': notificationBody,
        'message': notificationBody,
        'notification_title': notificationTitle,
        'notification_body': notificationBody,
      },
      'sentTime': message.sentTime?.toIso8601String(),
      'from': message.from,
    };
    
    final payloadJson = jsonEncode(payload);
    
    // Show local notification for foreground messages
    if (message.notification != null || message.data.isNotEmpty) {
      await showLocalNotification(
        title: notificationTitle,
        body: notificationBody,
        payload: payloadJson, // Use JSON payload, not toString()
        id: message.hashCode,
      );
      print('✅ Foreground notification displayed');
      print('   - Title: "$notificationTitle"');
      print('   - Body: "$notificationBody"');
      print('   - Payload length: ${payloadJson.length}');
    } else {
      print('⚠️ Foreground message has no notification payload or data');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('═══════════════════════════════════════════════════════════');
    print('📱 NOTIFICATION TAPPED');
    print('═══════════════════════════════════════════════════════════');
    print('📱 Message ID: ${message.messageId}');
    print('📱 Sent Time: ${message.sentTime}');
    print('📱 From: ${message.from}');
    print('📱 Notification Title: ${message.notification?.title}');
    print('📱 Notification Body: ${message.notification?.body}');
    print('📱 Full Data Payload:');
    message.data.forEach((key, value) {
      print('   - $key: $value (${value.runtimeType})');
    });
    print('═══════════════════════════════════════════════════════════');
    
    // Extract notification type from data
    final notificationType = message.data['type']?.toString() ?? 
        message.data['notification_type']?.toString();
    
    // CRITICAL: Extract title and body from ALL possible sources
    // Check notification payload first, then data payload, then all possible field names
    final title = message.notification?.title ?? 
                  message.data['title']?.toString() ??
                  message.data['notification_title']?.toString() ??
                  'Notification';
    
    final body = message.notification?.body ?? 
                 message.data['body']?.toString() ??
                 message.data['message']?.toString() ??
                 message.data['notification_body']?.toString() ??
                 message.data['description']?.toString() ??
                 message.data['text']?.toString() ??
                 message.data['content']?.toString() ??
                 '';
    
    print('═══════════════════════════════════════════════════════════');
    print('📱 EXTRACTING FROM REMOTE MESSAGE');
    print('═══════════════════════════════════════════════════════════');
    print('   - message.notification?.title: ${message.notification?.title}');
    print('   - message.notification?.body: ${message.notification?.body}');
    print('   - message.data[\'title\']: ${message.data['title']}');
    print('   - message.data[\'body\']: ${message.data['body']}');
    print('   - message.data[\'message\']: ${message.data['message']}');
    print('   - Final Title: "$title" (length: ${title.length})');
    print('   - Final Body: "$body" (length: ${body.length})');
    print('   - Type: $notificationType');
    print('   - Data keys: ${message.data.keys.toList()}');
    print('═══════════════════════════════════════════════════════════');
    
    // CRITICAL: Always ensure data map includes title and body
    // Store them in multiple places for redundancy
    final enrichedData = Map<String, dynamic>.from(message.data);
    
    // Always set title and body, even if they're already in data
    enrichedData['title'] = title;
    enrichedData['body'] = body;
    enrichedData['message'] = body; // Also store as 'message' for compatibility
    enrichedData['notification_title'] = title;
    enrichedData['notification_body'] = body;
    
    print('📱 Enriched data:');
    print('   - Keys: ${enrichedData.keys.toList()}');
    print('   - Title: "${enrichedData['title']}"');
    print('   - Body: "${enrichedData['body']}"');
    print('   - Message: "${enrichedData['message']}"');
    
    // Handle navigation using navigation service
    NotificationNavigationService.handleNotificationTap(
      data: enrichedData,
      notificationType: notificationType,
      title: title,
      body: body,
    );
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
    try {
      final status = await Permission.notification.request();
      print('📱 Notification permission status: $status');
      if (!status.isGranted) {
        print('⚠️ Notification permission not granted - notifications may not show');
        print('⚠️ Status: ${status.toString()}');
      } else {
        print('✅ Notification permission granted');
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
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
    print('═══════════════════════════════════════════════════════════');
    print('📱 LOCAL NOTIFICATION TAPPED');
    print('═══════════════════════════════════════════════════════════');
    print('📱 Notification ID: ${response.id}');
    print('📱 Action ID: ${response.actionId}');
    print('📱 Input: ${response.input}');
    print('📱 Payload: ${response.payload}');
    print('📱 Payload type: ${response.payload.runtimeType}');
    print('📱 Payload is null: ${response.payload == null}');
    print('📱 Payload isEmpty: ${response.payload?.isEmpty ?? true}');
    print('📱 Payload length: ${response.payload?.length ?? 0}');
    
    // CRITICAL: Print first 500 chars of payload to see structure
    if (response.payload != null && response.payload!.isNotEmpty) {
      final preview = response.payload!.length > 500 
          ? '${response.payload!.substring(0, 500)}...' 
          : response.payload!;
      print('📱 Payload preview: $preview');
    }
    print('═══════════════════════════════════════════════════════════');
    
    // Try to parse payload as JSON
    Map<String, dynamic> data = {};
    String? notificationTitle;
    String? notificationBody;
    
    // CRITICAL FIX: If payload is null or empty, we need to handle it gracefully
    // The payload should contain the notification data, but if it's missing,
    // we should still try to extract from any available source
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Try to parse as JSON
        if (response.payload!.startsWith('{')) {
          final decoded = jsonDecode(response.payload!) as Map<String, dynamic>;
          
          print('📱 Successfully parsed JSON payload');
          print('📱 Payload structure: ${decoded.keys.toList()}');
          print('📱 Full decoded payload: $decoded');
          
          // CRITICAL: Extract title and body from the top-level payload first
          notificationTitle = decoded['title']?.toString();
          notificationBody = decoded['body']?.toString();
          
          print('📱 Title from payload top-level: "$notificationTitle" (null: ${notificationTitle == null}, empty: ${notificationTitle?.isEmpty ?? true})');
          print('📱 Body from payload top-level: "$notificationBody" (null: ${notificationBody == null}, empty: ${notificationBody?.isEmpty ?? true})');
          
          // CRITICAL: Also check if title/body are in the payload but as different types
          if (notificationTitle == null) {
            final titleValue = decoded['title'];
            print('📱 Title value type: ${titleValue.runtimeType}, value: $titleValue');
          }
          if (notificationBody == null) {
            final bodyValue = decoded['body'];
            print('📱 Body value type: ${bodyValue.runtimeType}, value: $bodyValue');
          }
          
          // Extract the data field (which contains the original notification data)
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            final notificationData = decoded['data'] as Map<String, dynamic>;
            data.addAll(notificationData);
            print('📱 Extracted data from payload: ${data.keys.toList()}');
          }
          
          // Also include other useful fields from top-level
          if (decoded.containsKey('messageId')) {
            data['messageId'] = decoded['messageId'];
          }
          if (decoded.containsKey('from')) {
            data['from'] = decoded['from'];
          }
          
          // CRITICAL: If title/body are null at top-level, try to get from data field
          // This handles cases where the payload structure might be different
          if (notificationTitle == null || notificationTitle.isEmpty) {
            if (decoded.containsKey('data') && decoded['data'] is Map) {
              final dataMap = decoded['data'] as Map<String, dynamic>;
              notificationTitle = dataMap['title']?.toString() ?? 
                                dataMap['notification_title']?.toString() ??
                                dataMap['message']?.toString();
              print('📱 Title from data field: $notificationTitle');
            }
          }
          
          if (notificationBody == null || notificationBody.isEmpty) {
            if (decoded.containsKey('data') && decoded['data'] is Map) {
              final dataMap = decoded['data'] as Map<String, dynamic>;
              notificationBody = dataMap['body']?.toString() ?? 
                             dataMap['message']?.toString() ??
                             dataMap['notification_body']?.toString() ??
                             dataMap['description']?.toString();
              print('📱 Body from data field: $notificationBody');
            }
          }
          
          // CRITICAL: Also preserve title and body in the data map for redundancy
          if (notificationTitle != null && notificationTitle.isNotEmpty) {
            data['title'] = notificationTitle;
          }
          if (notificationBody != null && notificationBody.isNotEmpty) {
            data['body'] = notificationBody;
            data['message'] = notificationBody; // Also store as 'message' for compatibility
          }
          
          print('📱 Final extracted - Title: "$notificationTitle", Body: "$notificationBody"');
          print('📱 Final data map keys: ${data.keys.toList()}');
          print('📱 Final data map body: ${data['body']}');
          print('📱 Final data map message: ${data['message']}');
        } else {
          // Treat as simple string data
          data['message'] = response.payload;
          notificationBody = response.payload;
          print('📱 Treating payload as simple string: "$notificationBody"');
        }
      } catch (e, stackTrace) {
        print('⚠️ Could not parse notification payload as JSON: $e');
        print('⚠️ Stack trace: $stackTrace');
        print('⚠️ Attempting fallback parsing...');
        
        // Fallback: try to extract basic info from string
        data['payload'] = response.payload;
        notificationBody = response.payload;
        print('📱 Using payload as fallback body: "$notificationBody"');
      }
    } else {
      // CRITICAL: Payload is null or empty - this is the problem!
      print('⚠️⚠️⚠️ PAYLOAD IS NULL OR EMPTY! ⚠️⚠️⚠️');
      print('⚠️ This means the notification was created without a payload');
      print('⚠️ We cannot extract title/body from an empty payload');
      print('⚠️ The notification data must be stored elsewhere or passed differently');
      
      // Try to get from notification details if available
      // Note: NotificationResponse doesn't have title/body directly, so we're stuck
      // This is why we need to ensure the payload is always set when creating notifications
    }
    
    print('📱 Final parsed data for navigation: $data');
    print('📱 Final title for navigation: "$notificationTitle"');
    print('📱 Final body for navigation: "$notificationBody"');
    
    // Ensure we have at least some title/body - try multiple fallbacks
    final finalTitle = notificationTitle?.isNotEmpty == true
        ? notificationTitle!
        : (data['title']?.toString() ?? 
           data['notification_title']?.toString() ??
           'Notification');
    final finalBody = notificationBody?.isNotEmpty == true
        ? notificationBody!
        : (data['body']?.toString() ?? 
           data['message']?.toString() ?? 
           data['notification_body']?.toString() ??
           '');
    
    print('═══════════════════════════════════════════════════════════');
    print('📱 CALLING handleNotificationTap');
    print('═══════════════════════════════════════════════════════════');
    print('   - Title: "$finalTitle" (length: ${finalTitle.length})');
    print('   - Body: "$finalBody" (length: ${finalBody.length})');
    print('   - Data keys: ${data.keys.toList()}');
    print('═══════════════════════════════════════════════════════════');
    
    // Navigate to notifications screen with parsed data
    NotificationNavigationService.handleNotificationTap(
      data: data,
      notificationType: data['type']?.toString() ?? 
          data['notification_type']?.toString(),
      title: finalTitle,
      body: finalBody,
    );
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      print('🔔 Showing local notification:');
      print('   Title: $title');
      print('   Body: $body');
      print('   ID: $id');
      print('   Payload: $payload');

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(id, title, body, details, payload: payload);
      print('✅ Local notification displayed successfully');
    } catch (e, stackTrace) {
      print('❌ Failed to show local notification: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
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
