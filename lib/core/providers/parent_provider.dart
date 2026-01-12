import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parent_model.dart';
import '../models/parent_trip_model.dart';
import '../models/student_model.dart';
import '../services/parent_tracking_service.dart';
import '../services/parent_notification_service.dart';
import '../services/parent_student_service.dart';
import '../services/storage_service.dart';
import '../services/authentication_service.dart';
import '../services/state_management_helper.dart';
import '../services/debug_logger.dart';
import '../services/location_service_resolver.dart';
import 'dart:async';

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
  StreamSubscription<Position>? _locationSubscription;
  bool _isLocationTracking = false;

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

  /// Start location tracking and update current location on the map
  Future<void> startLocationTracking() async {
    if (_isLocationTracking) {
      print('📍 Location tracking already active');
      return;
    }

    try {
      print('📍 Starting location tracking for parent...');

      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission permanently denied');
        return;
      }

      // Initialize location service resolver
      await LocationServiceResolver.initialize();

      // Start tracking with callbacks
      final trackingStarted = await LocationServiceResolver.startTracking(
        onLocationUpdate: (Position position) {
          print(
            '📍 Parent location update: ${position.latitude}, ${position.longitude}',
          );
          
          // Update parent state with current location
          state = state.copyWith(
            currentLocation: {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'timestamp': position.timestamp?.toIso8601String(),
            },
          );
        },
        onLocationError: (String error) {
          print('❌ Location error: $error');
        },
        onUserGuidance: (String guidance) {
          print('💡 Location guidance: $guidance');
        },
      );

      if (trackingStarted) {
        _isLocationTracking = true;
        print('✅ Location tracking started successfully');

        // Get initial position
        final initialPosition = await LocationServiceResolver.getCurrentPosition();
        if (initialPosition != null) {
          print(
            '📍 Initial location: ${initialPosition.latitude}, ${initialPosition.longitude}',
          );
          state = state.copyWith(
            currentLocation: {
              'latitude': initialPosition.latitude,
              'longitude': initialPosition.longitude,
              'accuracy': initialPosition.accuracy,
              'timestamp': initialPosition.timestamp?.toIso8601String(),
            },
          );
        }
      } else {
        print('❌ Failed to start location tracking');
      }
    } catch (e) {
      print('❌ Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    if (!_isLocationTracking) {
      return;
    }

    try {
      print('📍 Stopping location tracking...');
      await LocationServiceResolver.stopTracking();
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isLocationTracking = false;
      print('✅ Location tracking stopped');
    } catch (e) {
      print('❌ Error stopping location tracking: $e');
    }
  }

  @override
  void dispose() {
    stopLocationTracking();
    stopTripTracking();
    stopNotificationMonitoring();
    super.dispose();
  }

  /// Helper method to calculate unread count from notifications
  /// Uses consistent logic to determine if a notification is read
  /// Get the authenticated parent's ID
  /// Returns null if parent is not authenticated
  int? _getAuthenticatedParentId() {
    // First try to get from state
    if (state.parent != null && state.parent!.id > 0) {
      return state.parent!.id;
    }
    
    // Fallback to storage
    final parentId = StorageService.getInt('parent_id');
    if (parentId != null && parentId > 0) {
      return parentId;
    }
    
    return null;
  }

  /// Check if a notification belongs to the authenticated parent
  /// Returns true if parent is not authenticated (to allow notifications during login flow)
  /// Returns false if notification's parent_id doesn't match authenticated parent
  bool _isNotificationForAuthenticatedParent(Map<String, dynamic> notification) {
    final authenticatedParentId = _getAuthenticatedParentId();
    
    // If parent is not authenticated, allow notification (might be during login flow)
    if (authenticatedParentId == null) {
      print('⚠️ SECURITY: No authenticated parent ID found, allowing notification (may be during login)');
      return true;
    }

    // Extract parent_id from notification (try multiple field names)
    dynamic notificationParentId = notification['parent_id'] ?? 
                                    notification['parentId'] ?? 
                                    notification['parent']?['id'] ??
                                    notification['parent'];

    // Handle different types (int, string, etc.)
    int? notificationParentIdInt;
    if (notificationParentId is int) {
      notificationParentIdInt = notificationParentId;
    } else if (notificationParentId is String) {
      notificationParentIdInt = int.tryParse(notificationParentId);
    } else if (notificationParentId != null) {
      notificationParentIdInt = int.tryParse(notificationParentId.toString());
    }

    // If notification doesn't have a parent_id, log warning but allow it
    // (some notifications might not have parent_id field)
    if (notificationParentIdInt == null) {
      print(
        '⚠️ SECURITY: Notification ${notification['id']} has no parent_id field - allowing but logging warning',
      );
      return true;
    }

    // Check if parent IDs match
    final matches = notificationParentIdInt == authenticatedParentId;
    
    if (!matches) {
      print(
        '🚨 SECURITY ALERT: Notification ${notification['id']} has parent_id=$notificationParentIdInt but authenticated parent_id=$authenticatedParentId',
      );
      print(
        '🚨 SECURITY: This notification was filtered out - backend may have a security issue!',
      );
    }

    return matches;
  }

  /// Filter notifications to only include those belonging to the authenticated parent
  List<Map<String, dynamic>> _filterNotificationsByParentId(
    List<Map<String, dynamic>> notifications,
  ) {
    final authenticatedParentId = _getAuthenticatedParentId();
    
    // If parent is not authenticated, return all notifications (might be during login flow)
    if (authenticatedParentId == null) {
      print('⚠️ SECURITY: No authenticated parent ID found, returning all notifications (may be during login)');
      return notifications;
    }

    final filtered = <Map<String, dynamic>>[];
    int filteredOutCount = 0;

    for (final notification in notifications) {
      if (_isNotificationForAuthenticatedParent(notification)) {
        filtered.add(notification);
      } else {
        filteredOutCount++;
      }
    }

    if (filteredOutCount > 0) {
      print(
        '🔒 SECURITY: Filtered out $filteredOutCount notification(s) that did not belong to parent $authenticatedParentId',
      );
    }

    return filtered;
  }

  int _calculateUnreadCount(List<Map<String, dynamic>> notifications) {
    return notifications.where((n) {
      // Normalize and check is_read field
      dynamic isReadValue = n['is_read'] ?? n['isRead'];
      bool isRead = false;

      if (isReadValue == true ||
          isReadValue == 1 ||
          isReadValue == '1' ||
          isReadValue == 'true' ||
          isReadValue.toString().toLowerCase() == 'true') {
        isRead = true;
      }

      // Check read_at field
      final readAt = n['read_at'] ?? n['readAt'];
      final hasReadAt = readAt != null &&
                        readAt != '' &&
                        readAt.toString().isNotEmpty &&
                        readAt.toString().toLowerCase() != 'null';

      // Notification is unread ONLY if is_read is false/null AND read_at is null/empty
      final isUnread = !isRead && !hasReadAt;

      return isUnread;
    }).length;
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

      // Start real-time notification monitoring if parent is loaded
      if (state.parent != null) {
        await startNotificationMonitoring();
      }

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

  /// Get all child IDs that belong to the authenticated parent
  /// Returns a set of child IDs from both parent.children and students
  Set<int> _getParentChildIds() {
    final parentId = _getAuthenticatedParentId();
    if (parentId == null) {
      print('⚠️ No authenticated parent ID found for child filtering');
      return <int>{};
    }

    final childIds = <int>{};

    // Get child IDs from parent.children (Child model)
    if (state.parent != null) {
      for (final child in state.parent!.children) {
        childIds.add(child.id);
      }
    }

    // Get child IDs from students where parent has a relationship
    for (final student in state.students) {
      // Check if this student has a parent relationship with the authenticated parent
      final hasParentRelationship = student.parents.any(
        (parentInfo) => parentInfo.parent == parentId,
      );
      if (hasParentRelationship) {
        childIds.add(student.id);
      }
    }

    print('🔒 SECURITY: Found ${childIds.length} child IDs for parent $parentId');
    return childIds;
  }

  /// Filter trips to only include those where the parent has a relationship with at least one child
  List<ParentTrip> _filterTripsByParentChildRelationship(
    List<ParentTrip> trips,
  ) {
    final parentChildIds = _getParentChildIds();
    
    // If no child IDs found, return empty list (parent has no children)
    if (parentChildIds.isEmpty) {
      print('⚠️ No children found for parent, filtering out all trips');
      return [];
    }

    final filteredTrips = trips.where((trip) {
      // Check if any child in the trip belongs to this parent
      final hasRelatedChild = trip.children.any(
        (child) => parentChildIds.contains(child.id),
      );
      
      if (!hasRelatedChild) {
        print(
          '🔒 SECURITY: Filtered out trip ${trip.id} - parent has no relationship with any child in this trip',
        );
      }
      
      return hasRelatedChild;
    }).toList();

    final filteredCount = trips.length - filteredTrips.length;
    if (filteredCount > 0) {
      print(
        '🔒 SECURITY: Filtered out $filteredCount trip(s) that did not belong to parent\'s children',
      );
    }

    return filteredTrips;
  }

  Future<void> loadActiveTrips() async {
    try {
      final response = await ParentTrackingService.getActiveTrips();
      if (response.success && response.data != null) {
        final tripsData = _extractDataFromResponse(response.data!);
        final allTrips = tripsData
            .map((json) => ParentTrip.fromJson(json))
            .toList();
        
        // Filter trips to only show those for parent's children
        final filteredTrips = _filterTripsByParentChildRelationship(allTrips);
        
        print(
          '✅ Loaded ${filteredTrips.length} active trips (filtered from ${allTrips.length} total)',
        );
        state = state.copyWith(activeTrips: filteredTrips);
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
        final allTripHistory = tripHistoryData
            .map((json) => ParentTrip.fromJson(json))
            .toList();
        
        // Filter trip history to only show those for parent's children
        final filteredTripHistory = _filterTripsByParentChildRelationship(allTripHistory);
        
        print(
          '✅ Loaded ${filteredTripHistory.length} trip history items (filtered from ${allTripHistory.length} total)',
        );
        state = state.copyWith(tripHistory: filteredTripHistory);
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

      // Load regular notifications (both read and unread for display)
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

        // Normalize notification fields and merge with existing notifications
        // to preserve read status of notifications that were marked as read locally
        // Create a map with both int and string keys for robust ID matching
        final existingNotifications = <dynamic, Map<String, dynamic>>{};
        for (final n in state.notifications) {
          final id = n['id'];
          existingNotifications[id] = n;
          // Also store with string key for matching
          existingNotifications[id.toString()] = n;
        }

        final normalizedNotifications = allNotifications.map((n) {
          final normalized = Map<String, dynamic>.from(n);
          final notificationId = normalized['id'];

          // Check if this notification already exists in local state
          // Try both the original ID and string version
          final existingNotification = existingNotifications[notificationId] ??
                                      existingNotifications[notificationId.toString()];

          if (existingNotification != null) {
            // Preserve read status from local state if it was marked as read
            dynamic existingIsReadValue = existingNotification['is_read'] ?? existingNotification['isRead'];
            bool existingIsRead = false;
            if (existingIsReadValue == true || existingIsReadValue == 1 || existingIsReadValue == '1' || existingIsReadValue == 'true') {
              existingIsRead = true;
            }
            final existingReadAt = existingNotification['read_at'] ?? existingNotification['readAt'];
            final existingHasReadAt = existingReadAt != null && existingReadAt != '' && existingReadAt.toString().isNotEmpty;

            // If notification was marked as read locally, preserve that status
            if (existingIsRead || existingHasReadAt) {
              print('📖 Preserving read status for notification: $notificationId');
              normalized['is_read'] = true;
              normalized['read_at'] = existingReadAt ?? DateTime.now().toIso8601String();
              // Also normalize other fields
              if (normalized['read_at'] == null && normalized['readAt'] != null) {
                normalized['read_at'] = normalized['readAt'];
              }
              return normalized;
            }
          }

          // Normalize fields for new notifications
          // Ensure is_read is a boolean
          if (normalized['is_read'] == null && normalized['isRead'] != null) {
            normalized['is_read'] = normalized['isRead'];
          }
          if (normalized['is_read'] == 1 || normalized['is_read'] == '1') {
            normalized['is_read'] = true;
          }
          if (normalized['is_read'] == 0 || normalized['is_read'] == '0' || normalized['is_read'] == null) {
            normalized['is_read'] = false;
          }
          // Ensure read_at is consistent
          if (normalized['read_at'] == null && normalized['readAt'] != null) {
            normalized['read_at'] = normalized['readAt'];
          }
          return normalized;
        }).toList();

        // SECURITY: Filter notifications to ensure parent only sees their own children's notifications
        final filteredNotifications = _filterNotificationsByParentId(normalizedNotifications);
        
        if (filteredNotifications.length != normalizedNotifications.length) {
          final filteredCount = normalizedNotifications.length - filteredNotifications.length;
          print(
            '⚠️ SECURITY: Filtered out $filteredCount notification(s) that did not belong to authenticated parent',
          );
        }

        // Calculate unread count using the helper method
        final unreadCount = _calculateUnreadCount(filteredNotifications);

        print(
          '📱 Total loaded ${filteredNotifications.length} notifications (after parent filtering), $unreadCount unread, ${filteredNotifications.length - unreadCount} read',
        );

        // Debug: Print first few notifications to see their read status
        if (normalizedNotifications.isNotEmpty) {
          print('📱 Sample notifications:');
          for (int i = 0; i < normalizedNotifications.length && i < 3; i++) {
            final n = normalizedNotifications[i];
            print('  ${i + 1}. ID: ${n['id']}, is_read: ${n['is_read']} (${n['is_read'].runtimeType}), read_at: ${n['read_at']}');
          }
        }

        // CRITICAL FIX: Merge with existing notifications to preserve manually added ones
        // Get existing notifications that aren't from the API (manually added)
        final manuallyAddedNotifications = state.notifications.where((existing) {
          // Check if this notification exists in the API response
          final existingId = existing['id'];
          final existsInApi = normalizedNotifications.any((api) {
            final apiId = api['id'];
            return apiId == existingId || apiId.toString() == existingId.toString();
          });
          // Keep notifications that don't exist in API (manually added)
          return !existsInApi;
        }).map((n) => Map<String, dynamic>.from(n)).toList();
        
        print('📱 Preserving ${manuallyAddedNotifications.length} manually added notifications');
        
        // Merge: API notifications first (newest), then manually added ones
        // Also filter manually added notifications for security
        final filteredManuallyAdded = _filterNotificationsByParentId(manuallyAddedNotifications);
        final mergedNotifications = <Map<String, dynamic>>[
          ...filteredNotifications,
          ...filteredManuallyAdded,
        ];
        final mergedUnreadCount = _calculateUnreadCount(mergedNotifications);
        
        print('📱 Total notifications after merge: ${mergedNotifications.length} (${mergedUnreadCount} unread)');
        
        state = state.copyWith(
          notifications: mergedNotifications,
          unreadCount: mergedUnreadCount,
        );
      } else {
        print('⚠️ No notifications found from API, preserving existing notifications');
        // CRITICAL FIX: Don't overwrite existing notifications when API returns empty
        // Preserve manually added notifications, but filter for security
        final filteredExisting = _filterNotificationsByParentId(state.notifications);
        final existingCount = filteredExisting.length;
        final existingUnreadCount = _calculateUnreadCount(filteredExisting);
        print('📱 Preserving $existingCount existing notifications (after parent filtering) ($existingUnreadCount unread)');
        // Update with filtered notifications to ensure security
        state = state.copyWith(
          notifications: filteredExisting,
          unreadCount: existingUnreadCount,
        );
      }
    } catch (e) {
      print('❌ Failed to load notifications: $e');
      // CRITICAL FIX: Don't clear existing notifications on error
      // Preserve manually added notifications even if API fails, but filter for security
      final filteredExisting = _filterNotificationsByParentId(state.notifications);
      final existingCount = filteredExisting.length;
      final existingUnreadCount = _calculateUnreadCount(filteredExisting);
      print('📱 Error loading notifications, preserving $existingCount existing notifications (after parent filtering)');
      // Update with filtered notifications to ensure security
      state = state.copyWith(
        notifications: filteredExisting,
        unreadCount: existingUnreadCount,
      );
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
    // Filter trip to ensure parent has relationship with at least one child
    final parentChildIds = _getParentChildIds();
    
    // Check if parent has relationship with any child in this trip
    final hasRelatedChild = parentChildIds.isNotEmpty && trip.children.any(
      (child) => parentChildIds.contains(child.id),
    );
    
    if (!hasRelatedChild) {
      print(
        '🔒 SECURITY: Ignoring trip update ${trip.id} - parent has no relationship with any child in this trip',
      );
      return;
    }
    
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

  /// Add a notification from external source (e.g., background notification)
  /// This is a public method that can be called from anywhere
  void addNotificationFromExternalSource(Map<String, dynamic> notification) {
    _addNotification(notification);
  }

  void _addNotification(Map<String, dynamic> notification) {
    // Debug: Log notification being added
    print('═══════════════════════════════════════════════════════════');
    print('📱 _addNotification called');
    print('📱 Notification keys: ${notification.keys.toList()}');
    print('📱 Notification title: ${notification['title']}');
    print('📱 Notification body: ${notification['body']}');
    print('📱 Notification message: ${notification['message']}');
    print('📱 Body length: ${notification['body']?.toString().length ?? 0}');
    print('📱 Message length: ${notification['message']?.toString().length ?? 0}');
    print('═══════════════════════════════════════════════════════════');
    
    // Validate notification data
    if (notification['id'] == null) {
      print('⚠️ Received invalid notification without ID: $notification');
      return;
    }

    final notificationId = notification['id'];

    // SECURITY: Filter notification to ensure it belongs to authenticated parent
    // Check this early before any processing
    if (!_isNotificationForAuthenticatedParent(notification)) {
      print(
        '⚠️ SECURITY: Rejecting notification $notificationId - does not belong to authenticated parent',
      );
      return;
    }

    // Check if notification already exists in the list
    final existingIndex = state.notifications.indexWhere(
      (n) => n['id'] == notificationId ||
             (n['id'] is int && notificationId is int && n['id'] == notificationId) ||
             (n['id'] is String && notificationId is String && n['id'] == notificationId) ||
             (n['id'].toString() == notificationId.toString()),
    );

    if (existingIndex >= 0) {
      // Notification already exists - check if it's read
      final existingNotification = state.notifications[existingIndex];

      // Normalize existing notification read status
      dynamic existingIsReadValue = existingNotification['is_read'] ?? existingNotification['isRead'];
      bool existingIsRead = false;
      if (existingIsReadValue == true || existingIsReadValue == 1 || existingIsReadValue == '1' || existingIsReadValue == 'true') {
        existingIsRead = true;
      }
      final existingReadAt = existingNotification['read_at'] ?? existingNotification['readAt'];
      final existingHasReadAt = existingReadAt != null && existingReadAt != '' && existingReadAt.toString().isNotEmpty;
      final existingIsReadFinal = existingIsRead || existingHasReadAt;

      // If existing notification is already read, NEVER update it - preserve read status
      if (existingIsReadFinal) {
        print('✅ Existing notification is already read, preserving read status: $notificationId');
        return;
      }

      // Check if the incoming notification is read - if so, mark existing as read
      dynamic newIsReadValue = notification['is_read'] ?? notification['isRead'];
      bool newIsRead = false;
      if (newIsReadValue == true || newIsReadValue == 1 || newIsReadValue == '1' || newIsReadValue == 'true') {
        newIsRead = true;
      }
      final newReadAt = notification['read_at'] ?? notification['readAt'];
      final newHasReadAt = newReadAt != null && newReadAt != '' && newReadAt.toString().isNotEmpty;

      // If incoming notification is read, mark existing as read too
      if (newIsRead || newHasReadAt) {
        print('📖 Marking existing notification as read from server update: $notificationId');
        final updatedNotifications = List<Map<String, dynamic>>.from(state.notifications);
        updatedNotifications[existingIndex] = {
          ...existingNotification,
          'is_read': true,
          'read_at': newReadAt ?? DateTime.now().toIso8601String(),
        };
        final unreadCount = _calculateUnreadCount(updatedNotifications);
        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        );
        return;
      }

      // Both are unread - just update the existing notification with new data
      print('🔄 Updating existing unread notification: $notificationId');
      final updatedNotifications = List<Map<String, dynamic>>.from(
        state.notifications,
      );

      // Update with new notification data, but preserve read status if already read
      updatedNotifications[existingIndex] = {
        ...notification,
        // Preserve existing read status - don't overwrite if already read
        'is_read': existingNotification['is_read'],
        'read_at': existingNotification['read_at'],
      };

      // Calculate unread count using the helper method
      final unreadCount = _calculateUnreadCount(updatedNotifications);

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
      return;
    }

    // Add new notification (only if it's unread)
    // Check if notification is read before adding
    dynamic isReadValue = notification['is_read'] ?? notification['isRead'];
    bool isRead = false;
    if (isReadValue == true || isReadValue == 1 || isReadValue == '1' || isReadValue == 'true') {
      isRead = true;
    }
    final readAt = notification['read_at'] ?? notification['readAt'];
    final hasReadAt = readAt != null && readAt != '' && readAt.toString().isNotEmpty;
    
    // CRITICAL: Verify body is present before adding
    final bodyValue = notification['body']?.toString() ?? notification['message']?.toString() ?? '';
    print('📱 Adding notification to state:');
    print('   - ID: $notificationId');
    print('   - Title: ${notification['title']}');
    print('   - Body: "$bodyValue" (length: ${bodyValue.length})');
    print('   - Message: ${notification['message']}');
    print('   - Is read: $isRead');

    // Only add if notification is unread
    if (!isRead && !hasReadAt) {
      final updatedNotifications = List<Map<String, dynamic>>.from(
        state.notifications,
      );
      updatedNotifications.insert(0, notification);

      // Calculate unread count using the helper method
      final unreadCount = _calculateUnreadCount(updatedNotifications);

      print('🔔 New unread notification added: ${notification['title'] ?? notification['message']}');
      print('📱 Notification body in state: "${notification['body']}"');
      print('📱 Notification message in state: "${notification['message']}"');
      print('📱 First notification in updated list body: "${updatedNotifications.first['body']}"');
      print('📱 First notification in updated list message: "${updatedNotifications.first['message']}"');
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
      
      // Verify after state update
      final verifyState = state;
      if (verifyState.notifications.isNotEmpty) {
        final firstNotif = verifyState.notifications.first;
        print('📱 VERIFICATION - First notification in state after update:');
        print('   - Title: "${firstNotif['title']}"');
        print('   - Body: "${firstNotif['body']}" (length: ${firstNotif['body']?.toString().length ?? 0})');
        print('   - Message: "${firstNotif['message']}" (length: ${firstNotif['message']?.toString().length ?? 0})');
        print('   - Keys: ${firstNotif.keys.toList()}');
      }
    } else {
      print('✅ Skipping read notification when adding new: $notificationId, is_read: $isReadValue, read_at: $readAt');
    }
  }

  Future<void> markNotificationAsRead(dynamic notificationId) async {
    try {
      print('📖 Marking notification as read: $notificationId (type: ${notificationId.runtimeType})');

      // For emergency alerts with string IDs like "emergency_2", we can't mark them via API
      // But we can mark them locally
      if (notificationId is String && notificationId.startsWith('emergency_')) {
        print('⚠️ Emergency alert with string ID - marking locally only');
      } else {
        // Try to mark via API if it's a numeric ID
        try {
          final numericId = notificationId is int
              ? notificationId
              : (notificationId is String ? int.tryParse(notificationId) : null);

          if (numericId != null) {
            await ParentNotificationService.markNotificationAsRead(
              notificationId: numericId,
            );
          }
        } catch (e) {
          print('⚠️ Could not mark via API (may be emergency alert): $e');
        }
      }

      // Update local state - mark as read by setting both is_read and read_at
      final updatedNotifications = state.notifications.map((notification) {
        final notifId = notification['id'];
        // Handle different ID types (int, string, etc.)
        final matches = (notifId == notificationId) ||
                       (notifId is int && notificationId is int && notifId == notificationId) ||
                       (notifId is String && notificationId is String && notifId == notificationId) ||
                       (notifId is String && notificationId is int && notifId == notificationId.toString()) ||
                       (notifId is int && notificationId is String && notifId.toString() == notificationId) ||
                       (notifId.toString() == notificationId.toString());

        if (matches) {
          print('✅ Marked notification $notifId as read');
          return {
            ...notification,
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          };
        }
        return notification;
      }).toList();

      // Calculate unread count using the helper method
      final unreadCount = _calculateUnreadCount(updatedNotifications);

      print('📖 After marking as read - Unread count: $unreadCount (Total: ${updatedNotifications.length})');
      print('📖 Notification IDs after marking: ${updatedNotifications.map((n) => '${n['id']}: is_read=${n['is_read']}, read_at=${n['read_at']}').join(', ')}');

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );

      // For string IDs (like emergency alerts), we don't need to reload from server
      // since they're only stored locally. For numeric IDs, reload to get server status.
      if (notificationId is int) {
        await Future.delayed(const Duration(milliseconds: 300));
        await loadNotifications();
      }
    } catch (e) {
      print('❌ Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (state.parent != null) {
      try {
        print('📖 Marking ALL notifications as read...');
        await ParentNotificationService.markAllNotificationsAsRead(
          parentId: state.parent!.id,
        );

        // Mark all as read locally
        final updatedNotifications = state.notifications.map((notification) {
          return {
            ...notification,
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );

        print('✅ All notifications marked as read. Unread count: 0');

        // Reload notifications from server to get the latest status
        await Future.delayed(const Duration(milliseconds: 500));
        await loadNotifications();
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

}

final parentProvider = StateNotifierProvider<ParentNotifier, ParentState>((
  ref,
) {
  return ParentNotifier();
});
