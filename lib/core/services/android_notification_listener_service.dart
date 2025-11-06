import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Service to access Android system notifications
/// This requires the user to grant Notification Listener permission
class AndroidNotificationListenerService {
  static const MethodChannel _channel = MethodChannel(
    'com.scholatransit.driver/notification_listener',
  );

  /// Stream controller for notification events
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of notification events
  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  /// Initialize the notification listener
  /// Sets up the method channel handler to receive notifications from native Android
  /// Automatically requests permission if not enabled
  static Future<void> initialize({bool autoRequestPermission = true}) async {
    if (!Platform.isAndroid) {
      print('⚠️ Notification listener is only available on Android');
      return;
    }

    try {
      // Set up method channel handler
      _channel.setMethodCallHandler(_handleMethodCall);
      print('✅ Android notification listener initialized');

      // Automatically request permission if not enabled
      if (autoRequestPermission) {
        await _autoRequestPermissionIfNeeded();
      }
    } catch (e) {
      print('❌ Failed to initialize notification listener: $e');
    }
  }

  /// Automatically request permission if not already enabled
  static Future<void> _autoRequestPermissionIfNeeded() async {
    try {
      // Wait a bit for the app to fully initialize
      await Future.delayed(const Duration(seconds: 2));

      final isEnabled = await isNotificationListenerEnabled();
      if (!isEnabled) {
        print('📱 Notification listener not enabled, automatically requesting permission...');
        await requestNotificationListenerPermission();
      } else {
        print('✅ Notification listener already enabled');
      }
    } catch (e) {
      print('❌ Error checking/requesting notification listener permission: $e');
    }
  }

  /// Handle method calls from native Android
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationPosted':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _notificationController.add({
          'type': 'posted',
          'data': data,
        });
        print('📱 Notification posted: ${data['packageName']} - ${data['title']}');
        break;

      case 'onNotificationRemoved':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        _notificationController.add({
          'type': 'removed',
          'data': data,
        });
        print('📱 Notification removed: ${data['packageName']}');
        break;

      default:
        print('⚠️ Unknown method call: ${call.method}');
    }
  }

  /// Check if notification listener permission is enabled
  static Future<bool> isNotificationListenerEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'isNotificationListenerEnabled',
      );
      return result ?? false;
    } catch (e) {
      print('❌ Failed to check notification listener status: $e');
      return false;
    }
  }

  /// Request notification listener permission
  /// Opens Android settings where user can enable the permission
  static Future<void> requestNotificationListenerPermission() async {
    if (!Platform.isAndroid) {
      print('⚠️ Notification listener is only available on Android');
      return;
    }

    try {
      await _channel.invokeMethod('requestNotificationListenerPermission');
      print('✅ Opened notification listener settings');
    } catch (e) {
      print('❌ Failed to open notification listener settings: $e');
    }
  }

  /// Get currently active notifications
  static Future<List<Map<String, dynamic>>> getActiveNotifications() async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getActiveNotifications',
      );

      if (result == null) {
        return [];
      }

      return result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      print('❌ Failed to get active notifications: $e');
      return [];
    }
  }

  /// Dispose the service
  static void dispose() {
    _notificationController.close();
  }
}

