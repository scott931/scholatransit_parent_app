import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Service to handle navigation when notifications are tapped
/// This service can be used from anywhere in the app, including background handlers
class NotificationNavigationService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static GoRouter? _router;
  // Store pending notification data temporarily for screens to read
  // This is needed because GoRouter's go() doesn't support extra parameters
  static Map<String, dynamic>? _pendingNotificationData;

  /// Initialize the navigation service with navigator key and router
  static void initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    GoRouter? router,
  }) {
    _navigatorKey = navigatorKey;
    _router = router;
  }

  /// Handle navigation when a notification is tapped
  /// Supports different notification types: emergency, trip, general
  static Future<void> handleNotificationTap({
    required Map<String, dynamic> data,
    String? notificationType,
    String? title,
    String? body,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('🧭 NOTIFICATION NAVIGATION HANDLER');
    print('═══════════════════════════════════════════════════════════');
    print('🧭 Data: $data');
    print('🧭 Type: $notificationType');
    print('🧭 Title parameter: $title');
    print('🧭 Body parameter: $body');
    print('🧭 Router available: ${_router != null}');
    print('🧭 Navigator key available: ${_navigatorKey != null}');
    
    // Extract title and body with fallbacks
    final extractedTitle = title ?? 
                           data['title']?.toString() ?? 
                           data['notification_title']?.toString() ??
                           'Notification';
    final extractedBody = body ?? 
                          data['body']?.toString() ?? 
                          data['message']?.toString() ??
                          data['notification_body']?.toString() ??
                          '';
    
    print('🧭 Extracted title: "$extractedTitle"');
    print('🧭 Extracted body: "$extractedBody"');
    
    // CRITICAL FIX: If title/body are still null/empty after extraction, 
    // and we have them as parameters, use them directly
    final finalExtractedTitle = (extractedTitle.isNotEmpty && extractedTitle != 'Notification')
        ? extractedTitle
        : (title?.isNotEmpty == true ? title! : 'Notification');
    final finalExtractedBody = extractedBody.isNotEmpty
        ? extractedBody
        : (body?.isNotEmpty == true ? body! : '');
    
    print('🧭 Final extracted title: "$finalExtractedTitle"');
    print('🧭 Final extracted body: "$finalExtractedBody"');

    // Extract notification type from data if not provided
    final type = notificationType ?? 
        data['type']?.toString().toLowerCase() ?? 
        data['notification_type']?.toString().toLowerCase() ?? 
        'general';

    // Handle emergency alerts
    if (type == 'emergency' || data.containsKey('alert_id') || data.containsKey('emergency_alert_id')) {
      final alertId = data['alert_id'] ?? 
          data['emergency_alert_id'] ?? 
          data['alertId'] ?? 
          data['emergencyAlertId'];
      
      if (alertId != null) {
        final id = alertId is int ? alertId : int.tryParse(alertId.toString());
        if (id != null) {
          print('🚨 Navigating to emergency alert: $id');
          _navigateTo('/parent/notifications/emergency/$id');
          return;
        }
      }
    }

    // Handle trip notifications
    if (type == 'trip' || data.containsKey('trip_id') || data.containsKey('tripId')) {
      final tripId = data['trip_id'] ?? data['tripId'];
      if (tripId != null) {
        final id = tripId is int ? tripId : int.tryParse(tripId.toString());
        if (id != null) {
          print('🚌 Navigating to trip: $id');
          _navigateTo('/trips/details/$id');
          return;
        }
      }
    }

    // Handle pickup and drop point alerts
    if (type == 'student_pickup' || type == 'pickup_alert' || data.containsKey('pickup_alert')) {
      final studentId = data['student_id'] ?? data['studentId'];
      final tripId = data['trip_id'] ?? data['tripId'];
      final stopId = data['stop_id'] ?? data['stopId'];
      final stopName = data['stop_name'] ?? data['stopName'];
      
      print('🚌 Pickup alert received');
      print('   - Student ID: $studentId');
      print('   - Trip ID: $tripId');
      print('   - Stop ID: $stopId');
      print('   - Stop Name: $stopName');
      
      // Navigate to trip details if trip ID is available
      if (tripId != null) {
        final id = tripId is int ? tripId : int.tryParse(tripId.toString());
        if (id != null) {
          print('🚌 Navigating to trip details for pickup alert: $id');
          _navigateTo('/trips/details/$id');
          return;
        }
      }
      
      // Navigate to student details if student ID is available
      if (studentId != null) {
        final id = studentId is int ? studentId : int.tryParse(studentId.toString());
        if (id != null) {
          print('👨‍🎓 Navigating to student details for pickup alert: $id');
          _navigateTo('/students/$id');
          return;
        }
      }
    }
    
    // Handle drop point alerts
    if (type == 'student_dropoff' || type == 'dropoff_alert' || type == 'drop_point_alert' || data.containsKey('dropoff_alert') || data.containsKey('drop_point_alert')) {
      final studentId = data['student_id'] ?? data['studentId'];
      final tripId = data['trip_id'] ?? data['tripId'];
      final stopId = data['stop_id'] ?? data['stopId'];
      final stopName = data['stop_name'] ?? data['stopName'];
      
      print('📍 Drop point alert received');
      print('   - Student ID: $studentId');
      print('   - Trip ID: $tripId');
      print('   - Stop ID: $stopId');
      print('   - Stop Name: $stopName');
      
      // Navigate to trip details if trip ID is available
      if (tripId != null) {
        final id = tripId is int ? tripId : int.tryParse(tripId.toString());
        if (id != null) {
          print('🚌 Navigating to trip details for dropoff alert: $id');
          _navigateTo('/trips/details/$id');
          return;
        }
      }
      
      // Navigate to student details if student ID is available
      if (studentId != null) {
        final id = studentId is int ? studentId : int.tryParse(studentId.toString());
        if (id != null) {
          print('👨‍🎓 Navigating to student details for dropoff alert: $id');
          _navigateTo('/students/$id');
          return;
        }
      }
    }

    // Handle student notifications
    if (type == 'student' || data.containsKey('student_id') || data.containsKey('studentId')) {
      final studentId = data['student_id'] ?? data['studentId'];
      if (studentId != null) {
        final id = studentId is int ? studentId : int.tryParse(studentId.toString());
        if (id != null) {
          print('👨‍🎓 Navigating to student: $id');
          _navigateTo('/students/$id');
          return;
        }
      }
    }

    // Handle notification with ID - navigate to notification details
    if (data.containsKey('notification_id') || data.containsKey('notificationId') || data.containsKey('id')) {
      final notificationId = data['notification_id'] ?? 
          data['notificationId'] ?? 
          data['id'];
      
      if (notificationId != null) {
        print('📱 Navigating to notification details: $notificationId');
        // Navigate to notifications screen - the screen will handle showing details
        _navigateTo('/parent/notifications', extra: {
          'highlight_notification_id': notificationId,
        });
        return;
      }
    }

    // Default: Navigate to notifications list with notification data
    print('📋 Navigating to notifications list with notification data');
    
    // Use the final extracted title and body (already extracted above with fallbacks)
    print('📋 Using final extracted values:');
    print('   - Title: "$finalExtractedTitle"');
    print('   - Body: "$finalExtractedBody"');
    
    // CRITICAL: Ensure data map also contains title and body for redundancy
    final enrichedData = Map<String, dynamic>.from(data);
    
    // Always ensure title and body are in the data map, even if they're already there
    // This ensures they're preserved when the data is passed to the screen
    enrichedData['title'] = finalExtractedTitle;
    enrichedData['body'] = finalExtractedBody;
    enrichedData['message'] = finalExtractedBody; // Also store as 'message' for compatibility
    
    print('📋 Enriched data keys: ${enrichedData.keys.toList()}');
    print('📋 Enriched data title: "${enrichedData['title']}"');
    print('📋 Enriched data body: "${enrichedData['body']}"');
    print('📋 Enriched data message: "${enrichedData['message']}"');
    
    // Store notification data temporarily (GoRouter's go() doesn't support extra)
    _pendingNotificationData = {
      'title': finalExtractedTitle,
      'body': finalExtractedBody,
      'message': finalExtractedBody, // Also store as message for compatibility
      'data': enrichedData,
      'type': type,
    };
    
    print('═══════════════════════════════════════════════════════════');
    print('📋 STORING PENDING NOTIFICATION DATA');
    print('═══════════════════════════════════════════════════════════');
    print('📋 Title: "$finalExtractedTitle" (length: ${finalExtractedTitle.length})');
    print('📋 Body: "$finalExtractedBody" (length: ${finalExtractedBody.length})');
    print('📋 Message: "$finalExtractedBody" (length: ${finalExtractedBody.length})');
    print('📋 Type: $type');
    print('📋 Enriched data keys: ${enrichedData.keys.toList()}');
    print('📋 Enriched data body: "${enrichedData['body']}"');
    print('📋 Enriched data message: "${enrichedData['message']}"');
    print('📋 Full stored data: $_pendingNotificationData');
    print('═══════════════════════════════════════════════════════════');
    // Navigate to notifications screen
    _navigateTo('/parent/notifications');
  }

  /// Get and clear pending notification data (called by notifications screen)
  static Map<String, dynamic>? getAndClearPendingNotificationData() {
    final data = _pendingNotificationData;
    _pendingNotificationData = null; // Clear after reading
    if (data != null) {
      print('📋 Retrieved pending notification data: $data');
    }
    return data;
  }

  /// Navigate to a specific route
  static void _navigateTo(String path, {Map<String, dynamic>? extra}) {
    if (_router != null) {
      try {
        if (extra != null) {
          // GoRouter doesn't support extra in go(), so we'll use push with extra
          // But first try go() and the screen will handle the data via state
          _router!.go(path);
          // Note: For highlighting specific notifications, we'll rely on the screen
          // refreshing and showing all notifications, including the new one
          print('✅ Navigated to: $path (extra data: $extra)');
        } else {
          _router!.go(path);
          print('✅ Navigated to: $path');
        }
      } catch (e) {
        print('❌ Navigation error: $e');
        // Fallback: try with navigator key
        _navigateWithNavigatorKey(path);
      }
    } else {
      _navigateWithNavigatorKey(path);
    }
  }

  /// Fallback navigation using navigator key
  static void _navigateWithNavigatorKey(String path) {
    if (_navigatorKey?.currentContext != null) {
      try {
        _navigatorKey!.currentContext!.go(path);
        print('✅ Navigated using navigator key: $path');
      } catch (e) {
        print('❌ Navigator key navigation error: $e');
      }
    } else {
      print('⚠️ No navigator available for navigation to: $path');
    }
  }

  /// Navigate to notifications list
  static void navigateToNotifications() {
    _navigateTo('/parent/notifications');
  }

  /// Navigate to emergency alert details
  static void navigateToEmergencyAlert(int alertId) {
    _navigateTo('/parent/notifications/emergency/$alertId');
  }

  /// Navigate to trip details
  static void navigateToTrip(int tripId) {
    _navigateTo('/trips/details/$tripId');
  }

  /// Navigate to student details
  static void navigateToStudent(int studentId) {
    _navigateTo('/students/$studentId');
  }

  /// Navigate to trip details for pickup alert
  static void navigateToPickupAlert({
    int? tripId,
    int? studentId,
    String? stopName,
  }) {
    if (tripId != null) {
      navigateToTrip(tripId);
    } else if (studentId != null) {
      navigateToStudent(studentId);
    } else {
      navigateToNotifications();
    }
  }

  /// Navigate to trip details for drop point alert
  static void navigateToDropPointAlert({
    int? tripId,
    int? studentId,
    String? stopName,
  }) {
    if (tripId != null) {
      navigateToTrip(tripId);
    } else if (studentId != null) {
      navigateToStudent(studentId);
    } else {
      navigateToNotifications();
    }
  }
}
