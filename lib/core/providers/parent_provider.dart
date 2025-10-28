import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parent_model.dart';
import '../models/parent_trip_model.dart';
import '../models/student_model.dart';
import '../services/parent_tracking_service.dart';
import '../services/parent_notification_service.dart';
import '../services/parent_student_service.dart';
import '../services/storage_service.dart';
import '../services/authentication_service.dart';
import '../services/api_response_handler.dart';
import '../services/state_management_helper.dart';
import '../services/debug_logger.dart';

class ParentState {
  final bool isLoading;
  final Parent? parent;
  final List<Child> children;
  final List<Student> students;
  final List<ParentTrip> activeTrips;
  final List<ParentTrip> tripHistory;
  final List<Map<String, dynamic>> notifications;
  final String? error;
  final Map<String, dynamic>? currentLocation;
  final int? unreadCount;

  const ParentState({
    this.isLoading = false,
    this.parent,
    this.children = const [],
    this.students = const [],
    this.activeTrips = const [],
    this.tripHistory = const [],
    this.notifications = const [],
    this.error,
    this.currentLocation,
    this.unreadCount = 0,
  });

  ParentState copyWith({
    bool? isLoading,
    Parent? parent,
    List<Child>? children,
    List<Student>? students,
    List<ParentTrip>? activeTrips,
    List<ParentTrip>? tripHistory,
    List<Map<String, dynamic>>? notifications,
    String? error,
    Map<String, dynamic>? currentLocation,
    int? unreadCount,
  }) {
    return ParentState(
      isLoading: isLoading ?? this.isLoading,
      parent: parent ?? this.parent,
      children: children ?? this.children,
      students: students ?? this.students,
      activeTrips: activeTrips ?? this.activeTrips,
      tripHistory: tripHistory ?? this.tripHistory,
      notifications: notifications ?? this.notifications,
      error: error,
      currentLocation: currentLocation ?? this.currentLocation,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ParentNotifier extends StateNotifier<ParentState> {
  ParentNotifier() : super(const ParentState()) {
    _initializeServices();
  }

  void _initializeServices() {
    // Listen to trip updates
    ParentTrackingService.tripStream.listen((trip) {
      _updateActiveTrip(trip);
    });

    // Listen to ETA updates
    ParentTrackingService.etaStream.listen((etaData) {
      _updateETA(etaData);
    });

    // Listen to notifications
    ParentNotificationService.notificationStream.listen((notification) {
      _addNotification(notification);
    });
  }

  /// Helper method to handle both direct list and paginated response formats
  List<Map<String, dynamic>> _extractDataFromResponse(dynamic responseData) {
    List<Map<String, dynamic>> extractedData = [];

    try {
      // Check if data is a list directly
      if (responseData is List) {
        for (final item in responseData) {
          if (item is Map) {
            extractedData.add(Map<String, dynamic>.from(item));
          }
        }
      }
      // Check if data is a map with results array
      else if (responseData is Map) {
        final dynamic dataMap = responseData;
        final dynamic results = dataMap['results'];
        if (results is List) {
          for (final dynamic item in results) {
            if (item is Map) {
              extractedData.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error extracting data from response: $e');
    }

    return extractedData;
  }

  /// Validate authentication using centralized service
  Future<bool> _validateAuthentication() async {
    // For StateNotifier, we need to get the ref from the provider context
    // Since we can't access ref directly in StateNotifier, we'll use a simpler approach
    return await AuthenticationService.validateAndRefreshAuth(null);
  }

  Future<void> loadParentData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Enhanced authentication check
      if (!await _validateAuthentication()) {
        DebugLogger.logAuthDebug(
          'Authentication validation failed, skipping data load',
        );
        state = StateManagementHelper.setErrorState(
          state,
          'Authentication required. Please log in.',
          state.copyWith,
        );
        return;
      }

      // Load students
      await loadStudents();

      // Load active trips
      await loadActiveTrips();

      // Load trip history
      await loadTripHistory();

      // Load notifications
      await loadNotifications();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load parent data: $e',
      );
    }
  }

  Future<void> loadStudents() async {
    try {
      print('👨‍👩‍👧‍👦 Loading students...');
      final response = await ParentStudentService.getParentStudents(limit: 50);
      if (response.success && response.data != null) {
        // ParentStudentService already returns List<Student>, no need to extract or convert
        final students = response.data!;
        print('✅ Students loaded successfully: ${students.length} students');
        state = state.copyWith(students: students);
      } else {
        // Check for authentication errors
        if (response.error?.contains('401') == true ||
            response.error?.contains('Authentication') == true) {
          print('🔐 Authentication error detected in students API');
          state = state.copyWith(
            students: [],
            error: 'Authentication expired. Please log in again.',
          );
        } else {
          print('⚠️ No students found or API unavailable, using empty list');
          state = state.copyWith(students: []);
        }
      }
    } catch (e) {
      print('❌ Failed to load students: $e');
      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Authentication')) {
        state = state.copyWith(
          students: [],
          error: 'Authentication expired. Please log in again.',
        );
      } else {
        // Provide fallback empty list to prevent crashes
        state = state.copyWith(students: []);
      }
    }
  }

  Future<void> loadActiveTrips() async {
    try {
      final response = await ParentTrackingService.getActiveTrips();
      if (response.success && response.data != null) {
        final tripsData = _extractDataFromResponse(response.data!);
        final trips = tripsData
            .map((json) => ParentTrip.fromJson(json))
            .toList();
        state = state.copyWith(activeTrips: trips);
      } else {
        print('⚠️ No active trips found or API unavailable, using empty list');
        state = state.copyWith(activeTrips: []);
      }
    } catch (e) {
      print('❌ Failed to load active trips: $e');
      // Provide fallback empty list to prevent crashes
      state = state.copyWith(activeTrips: []);
    }
  }

  Future<void> loadTripHistory({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await ParentTrackingService.getTripHistory(
        startDate: startDate,
        endDate: endDate,
        limit: 50,
      );
      if (response.success && response.data != null) {
        final tripHistoryData = _extractDataFromResponse(response.data!);
        final tripHistory = tripHistoryData
            .map((json) => ParentTrip.fromJson(json))
            .toList();
        state = state.copyWith(tripHistory: tripHistory);
      } else {
        print('⚠️ No trip history found or API unavailable, using empty list');
        state = state.copyWith(tripHistory: []);
      }
    } catch (e) {
      print('❌ Failed to load trip history: $e');
      // Provide fallback empty list to prevent crashes
      state = state.copyWith(tripHistory: []);
    }
  }

  Future<void> loadNotifications() async {
    try {
      print('📱 Loading notifications...');

      // Enhanced authentication check
      if (!await _validateAuthentication()) {
        DebugLogger.logAuthDebug(
          'Authentication validation failed - skipping emergency alerts',
        );
        DebugLogger.logAuthDebug(
          'This means the user is not properly authenticated',
        );
        // Still try to load regular notifications
      } else {
        DebugLogger.logAuthDebug(
          'Authentication token validated - will attempt to load emergency alerts',
        );
      }

      // Load regular notifications
      final notificationsResponse =
          await ParentNotificationService.getParentNotifications(limit: 50);
      print('📱 Notifications API response:');
      print('  - success: ${notificationsResponse.success}');
      print('  - data: ${notificationsResponse.data}');
      print('  - error: ${notificationsResponse.error}');

      // Load emergency alerts
      final emergencyResponse =
          await ParentNotificationService.getEmergencyAlerts(limit: 50);
      print('🚨 Emergency alerts API response:');
      print('  - success: ${emergencyResponse.success}');
      print('  - data: ${emergencyResponse.data}');
      print('  - error: ${emergencyResponse.error}');

      // Check for authentication errors
      if (!emergencyResponse.success && emergencyResponse.error != null) {
        print('🚨 Emergency alerts API failed:');
        print('  - Error: ${emergencyResponse.error}');
        print('  - Status Code: ${emergencyResponse.statusCode}');

        if (emergencyResponse.error!.contains('Authentication') ||
            emergencyResponse.error!.contains('401') ||
            emergencyResponse.error!.contains('token') ||
            emergencyResponse.error!.contains('credentials')) {
          print(
            '🔐 Emergency alerts require authentication - user may need to log in',
          );
          print(
            '🔐 Current auth token status: ${AuthenticationService.getAuthToken() != null ? "Present" : "Missing"}',
          );
        }
      }

      List<Map<String, dynamic>> allNotifications = [];

      // Process regular notifications
      if (notificationsResponse.success && notificationsResponse.data != null) {
        final regularNotifications = _extractDataFromResponse(
          notificationsResponse.data!,
        );
        print(
          '📱 Regular notifications raw data: ${notificationsResponse.data}',
        );

        final validNotifications = regularNotifications.where((notification) {
          return notification['id'] != null;
        }).toList();
        allNotifications.addAll(validNotifications);
        print('📱 Loaded ${validNotifications.length} regular notifications');
      }

      // Process emergency alerts
      if (emergencyResponse.success && emergencyResponse.data != null) {
        final emergencyAlerts = _extractDataFromResponse(
          emergencyResponse.data!,
        );
        print('🚨 Emergency alerts raw data: ${emergencyResponse.data}');

        print(
          '🚨 Processed ${emergencyAlerts.length} emergency alerts from API',
        );

        final transformedAlerts = emergencyAlerts
            .map((alert) => _transformEmergencyAlertToNotification(alert))
            .toList();
        allNotifications.addAll(transformedAlerts);
        print('🚨 Loaded ${transformedAlerts.length} emergency alerts');
      } else if (!emergencyResponse.success) {
        print('⚠️ Emergency alerts API failed: ${emergencyResponse.error}');
        print('📱 Continuing with regular notifications only');
      }

      if (allNotifications.isNotEmpty) {
        // Sort by creation time (newest first)
        allNotifications.sort((a, b) {
          final aTime = _getSafeDateTime(a['created_at']);
          final bTime = _getSafeDateTime(b['created_at']);
          return bTime.compareTo(aTime);
        });

        final unreadCount = allNotifications
            .where((n) => !(n['is_read'] ?? false))
            .length;
        print(
          '📱 Total loaded ${allNotifications.length} notifications, $unreadCount unread',
        );
        state = state.copyWith(
          notifications: allNotifications,
          unreadCount: unreadCount,
        );
      } else {
        print('⚠️ No notifications found or API unavailable, using empty list');
        state = state.copyWith(notifications: [], unreadCount: 0);
      }
    } catch (e) {
      print('❌ Failed to load notifications: $e');
      // Provide fallback empty list to prevent crashes
      state = state.copyWith(notifications: [], unreadCount: 0);
    }
  }

  Future<void> startTripTracking(int tripId) async {
    try {
      final success = await ParentTrackingService.startTripTracking(tripId);
      if (success) {
        print('✅ Started tracking trip $tripId');
      }
    } catch (e) {
      print('❌ Failed to start trip tracking: $e');
    }
  }

  Future<void> stopTripTracking() async {
    try {
      await ParentTrackingService.stopTripTracking();
      print('✅ Stopped trip tracking');
    } catch (e) {
      print('❌ Failed to stop trip tracking: $e');
    }
  }

  Future<void> startNotificationMonitoring() async {
    if (state.parent != null) {
      ParentNotificationService.startNotificationMonitoring(state.parent!.id);
    }
  }

  Future<void> stopNotificationMonitoring() async {
    ParentNotificationService.stopNotificationMonitoring();
  }

  void _updateActiveTrip(ParentTrip trip) {
    final updatedTrips = List<ParentTrip>.from(state.activeTrips);
    final index = updatedTrips.indexWhere((t) => t.id == trip.id);

    if (index >= 0) {
      updatedTrips[index] = trip;
    } else {
      updatedTrips.add(trip);
    }

    state = state.copyWith(activeTrips: updatedTrips);
  }

  void _updateETA(Map<String, dynamic> etaData) {
    // Update current location and ETA
    state = state.copyWith(currentLocation: etaData);
  }

  void _addNotification(Map<String, dynamic> notification) {
    // Validate notification data
    if (notification['id'] == null) {
      print('⚠️ Received invalid notification without ID: $notification');
      return;
    }

    final updatedNotifications = List<Map<String, dynamic>>.from(
      state.notifications,
    );
    updatedNotifications.insert(0, notification);

    // Calculate unread count from all notifications
    final unreadCount = updatedNotifications
        .where((n) => !(n['is_read'] ?? false))
        .length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await ParentNotificationService.markNotificationAsRead(
        notificationId: notificationId,
      );

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification['id'] == notificationId) {
          return {...notification, 'is_read': true};
        }
        return notification;
      }).toList();

      // Calculate unread count from all notifications
      final unreadCount = updatedNotifications
          .where((n) => !(n['is_read'] ?? false))
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('❌ Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (state.parent != null) {
      try {
        await ParentNotificationService.markAllNotificationsAsRead(
          parentId: state.parent!.id,
        );

        final updatedNotifications = state.notifications.map((notification) {
          return {...notification, 'is_read': true};
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );
      } catch (e) {
        print('❌ Failed to mark all notifications as read: $e');
      }
    }
  }

  Future<void> refreshData() async {
    await loadParentData();
  }

  Future<void> refreshStudents() async {
    await loadStudents();
  }

  /// Transform emergency alert data to match notification format
  Map<String, dynamic> _transformEmergencyAlertToNotification(
    Map<String, dynamic> alert,
  ) {
    print(
      '🚨 Transforming emergency alert: ${alert['id']} - ${alert['title']}',
    );

    return {
      'id': 'emergency_${alert['id']}', // Prefix to avoid conflicts
      'type': 'emergency',
      'title': alert['title'] ?? 'Emergency Alert',
      'message': alert['description'] ?? 'Emergency situation reported',
      'created_at': alert['reported_at'] ?? alert['created_at'],
      'is_read': false, // Emergency alerts are always unread initially
      'emergency_type': alert['emergency_type'],
      'emergency_type_display': alert['emergency_type_display'],
      'severity': alert['severity'],
      'severity_display': alert['severity_display'],
      'status': alert['status'],
      'status_display': alert['status_display'],
      'vehicle': alert['vehicle'],
      'route': alert['route'],
      'students': alert['students'],
      'affected_students_count': alert['affected_students_count'],
      'estimated_delay_minutes': alert['estimated_delay_minutes'],
      'is_emergency': true, // Flag to identify emergency alerts
    };
  }

  /// Safely extract a DateTime value from notification data
  DateTime _getSafeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse date: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Force refresh all data (cache busting)
  Future<void> forceRefreshAllData() async {
    print('🔄 Force refreshing all data...');

    // Clear all storage
    await StorageService.forceRefreshAllData();

    // Reset state to initial
    state = const ParentState();

    // Reload all data
    await loadParentData();

    print('✅ All data force refreshed');
  }

  // Clear cache and reload notifications
  Future<void> clearCacheAndReload() async {
    print('🧹 Clearing cache and reloading...');

    // Clear notification cache
    await StorageService.clearNotificationSettings();

    // Reset notifications in state
    state = state.copyWith(notifications: [], unreadCount: 0);

    // Reload notifications
    await loadNotifications();

    print('✅ Cache cleared and data reloaded');
  }

  // Development-specific hot reload cache clearing
  Future<void> clearHotReloadCache() async {
    if (kDebugMode) {
      print('🔥 Clearing hot reload cache...');

      // Clear all storage
      await StorageService.clearAllData();

      // Reset state completely
      state = const ParentState();

      // Reinitialize services
      _initializeServices();

      print('✅ Hot reload cache cleared');
    }
  }

  @override
  void dispose() {
    stopTripTracking();
    stopNotificationMonitoring();
    super.dispose();
  }
}

final parentProvider = StateNotifierProvider<ParentNotifier, ParentState>((
  ref,
) {
  return ParentNotifier();
});
