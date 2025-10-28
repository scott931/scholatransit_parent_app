import 'dart:async';
import '../models/parent_model.dart';
import '../config/api_endpoints.dart';
import 'api_service.dart';

class ParentNotificationService {
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Timer? _notificationTimer;

  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  /// Send child status update notification
  static Future<ApiResponse<Map<String, dynamic>>> sendChildStatusUpdate({
    required int parentId,
    required int childId,
    required ChildStatus status,
    String? message,
    Map<String, dynamic>? additionalData,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.childStatusNotification,
      data: {
        'parent_id': parentId,
        'child_id': childId,
        'status': status.apiValue,
        'message': message ?? _getStatusMessage(status),
        'additional_data': additionalData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send trip update notification
  static Future<ApiResponse<Map<String, dynamic>>> sendTripUpdate({
    required int parentId,
    required int tripId,
    required String updateType,
    required String message,
    Map<String, dynamic>? tripData,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.tripUpdateNotification,
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'update_type': updateType,
        'message': message,
        'trip_data': tripData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send emergency alert to parent
  static Future<ApiResponse<Map<String, dynamic>>> sendEmergencyAlert({
    required int parentId,
    required String alertType,
    required String message,
    required String severity,
    Map<String, dynamic>? alertData,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.createGeneralAlert,
      data: {
        'parent_id': parentId,
        'alert_type': alertType,
        'message': message,
        'severity': severity,
        'alert_data': alertData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send ETA notification
  static Future<ApiResponse<Map<String, dynamic>>> sendETANotification({
    required int parentId,
    required int tripId,
    required int etaMinutes,
    required String stopName,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.etaNotification,
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'eta_minutes': etaMinutes,
        'stop_name': stopName,
        'message': _getETAMessage(etaMinutes, stopName),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get parent notifications
  static Future<ApiResponse<Map<String, dynamic>>> getParentNotifications({
    int? limit,
    int? offset,
    String? type,
    bool? isRead,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (type != null) queryParams['type'] = type;
    if (isRead != null) queryParams['is_read'] = isRead;

    return ApiService.get<Map<String, dynamic>>(
      ApiEndpoints.parentNotifications,
      queryParameters: queryParams,
    );
  }

  /// Get emergency alerts
  static Future<ApiResponse<Map<String, dynamic>>> getEmergencyAlerts({
    int? limit,
    int? offset,
    String? status,
    String? severity,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (status != null) queryParams['status'] = status;
    if (severity != null) queryParams['severity'] = severity;

    return ApiService.get<Map<String, dynamic>>(
      ApiEndpoints.emergencyAlerts,
      queryParameters: queryParams,
    );
  }

  /// Mark notification as read
  static Future<ApiResponse<Map<String, dynamic>>> markNotificationAsRead({
    required int notificationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.markNotificationAsRead(notificationId),
    );
  }

  /// Mark all notifications as read
  static Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsAsRead({
    required int parentId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.markAllNotificationsAsRead,
      data: {'parent_id': parentId},
    );
  }

  /// Start real-time notification monitoring
  static void startNotificationMonitoring(int parentId) {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      await _checkForNewNotifications(parentId);
    });
  }

  /// Stop real-time notification monitoring
  static void stopNotificationMonitoring() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  /// Check for new notifications
  static Future<void> _checkForNewNotifications(int parentId) async {
    try {
      final response = await getParentNotifications(limit: 10, isRead: false);

      if (response.success && response.data != null) {
        final data = response.data!;
        final results = data['results'] as List<dynamic>? ?? [];
        for (final notification in results) {
          _notificationController.add(notification as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('❌ Failed to check for notifications: $e');
    }
  }

  /// Get status message for child status
  static String _getStatusMessage(ChildStatus status) {
    switch (status) {
      case ChildStatus.waiting:
        return 'Your child is waiting for the bus';
      case ChildStatus.onBus:
        return 'Your child is now on the bus';
      case ChildStatus.pickedUp:
        return 'Your child has been picked up';
      case ChildStatus.droppedOff:
        return 'Your child has been dropped off';
      case ChildStatus.absent:
        return 'Your child was absent today';
    }
  }

  /// Get ETA message
  static String _getETAMessage(int etaMinutes, String stopName) {
    if (etaMinutes <= 0) {
      return 'The bus has arrived at $stopName';
    } else if (etaMinutes == 1) {
      return 'The bus will arrive at $stopName in 1 minute';
    } else if (etaMinutes < 5) {
      return 'The bus will arrive at $stopName in $etaMinutes minutes';
    } else {
      return 'The bus is approximately $etaMinutes minutes away from $stopName';
    }
  }

  /// Send delay notification
  static Future<ApiResponse<Map<String, dynamic>>> sendDelayNotification({
    required int parentId,
    required int tripId,
    required int delayMinutes,
    required String reason,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.delayNotification,
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'delay_minutes': delayMinutes,
        'reason': reason,
        'message':
            'The bus is running $delayMinutes minutes late. Reason: $reason',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send route change notification
  static Future<ApiResponse<Map<String, dynamic>>> sendRouteChangeNotification({
    required int parentId,
    required int tripId,
    required String oldRoute,
    required String newRoute,
    String? reason,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.routeChangeNotification,
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'old_route': oldRoute,
        'new_route': newRoute,
        'reason': reason,
        'message':
            'Route changed from $oldRoute to $newRoute${reason != null ? '. Reason: $reason' : ''}',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get notification preferences
  static Future<ApiResponse<Map<String, dynamic>>> getNotificationPreferences({
    required int parentId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      ApiEndpoints.notificationPreferences(parentId),
    );
  }

  /// Update notification preferences
  static Future<ApiResponse<Map<String, dynamic>>>
  updateNotificationPreferences({
    required int parentId,
    required Map<String, dynamic> preferences,
  }) async {
    return ApiService.put<Map<String, dynamic>>(
      ApiEndpoints.updateNotificationPreferences(parentId),
      data: preferences,
    );
  }

  /// Start parent notifications
  static Future<void> startParentNotifications(int parentId) async {
    startNotificationMonitoring(parentId);
  }

  /// Stop parent notifications
  static Future<void> stopParentNotifications() async {
    stopNotificationMonitoring();
  }

  /// Send ETA update
  static Future<ApiResponse<Map<String, dynamic>>> sendETAUpdate({
    required int parentId,
    required int tripId,
    required int etaMinutes,
    required String stopName,
  }) async {
    return sendETANotification(
      parentId: parentId,
      tripId: tripId,
      etaMinutes: etaMinutes,
      stopName: stopName,
    );
  }

  /// Send distance update
  static Future<ApiResponse<Map<String, dynamic>>> sendDistanceUpdate({
    required int parentId,
    required int tripId,
    required double distanceKm,
    required String stopName,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.distanceNotification,
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'distance_km': distanceKm,
        'stop_name': stopName,
        'message':
            'The bus is ${distanceKm.toStringAsFixed(1)} km away from $stopName',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send arrival notification
  static Future<ApiResponse<Map<String, dynamic>>> sendArrivalNotification({
    required int parentId,
    required int tripId,
    required String stopName,
    required String studentName,
    required String parentPhone,
    required String parentEmail,
    String? delayReason,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      ApiEndpoints.arrivalNotification,
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'stop_name': stopName,
        'student_name': studentName,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
        'delay_reason': delayReason,
        'message': 'The bus has arrived at $stopName for $studentName',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send delay notification with additional parameters
  static Future<ApiResponse<Map<String, dynamic>>>
  sendDelayNotificationWithDetails({
    required int parentId,
    required int tripId,
    required int delayMinutes,
    required String reason,
    required String studentName,
    required String parentPhone,
    required String parentEmail,
  }) async {
    return sendDelayNotification(
      parentId: parentId,
      tripId: tripId,
      delayMinutes: delayMinutes,
      reason: reason,
    );
  }

  /// Dispose resources
  static Future<void> dispose() async {
    _notificationTimer?.cancel();
    await _notificationController.close();
  }
}
