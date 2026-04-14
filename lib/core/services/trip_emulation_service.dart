import 'package:flutter/foundation.dart';
import '../models/parent_model.dart';
import '../models/parent_trip_model.dart';
import '../config/app_config.dart';

/// Trip Emulation Service
///
/// Provides 3 emulated trips for development/demo without affecting the
/// real API flow. Follows the full trip step logic: Pickup → School → Dropoff.
///
/// Enable via [AppConfig.enableTripEmulation].
class TripEmulationService {
  static const double _baseLat = AppConfig.defaultLatitude;
  static const double _baseLng = AppConfig.defaultLongitude;

  /// Returns emulated live trips (in progress only).
  /// Used when [AppConfig.enableTripEmulation] is true.
  static List<ParentTrip> getEmulatedActiveTrips({
    List<Child>? parentChildren,
  }) {
    if (!kDebugMode) return [];
    final now = DateTime.now();
    final children = _resolveChildren(parentChildren);
    return [_buildInProgressTrip(now, children)];
  }

  /// Returns emulated upcoming trips (scheduled, not yet started).
  static List<ParentTrip> getEmulatedScheduledTrips({
    List<Child>? parentChildren,
  }) {
    if (!kDebugMode) return [];
    final now = DateTime.now();
    final children = _resolveChildren(parentChildren);
    return [_buildScheduledTrip(now, children)];
  }

  /// Returns emulated trip history (completed trips).
  static List<ParentTrip> getEmulatedTripHistory({
    List<Child>? parentChildren,
  }) {
    if (!kDebugMode) return [];
    final now = DateTime.now();
    final children = _resolveChildren(parentChildren);
    return [
      _buildCompletedTrip1(now, children),
      _buildCompletedTrip2(now, children),
      _buildCompletedTrip3(now, children),
    ];
  }

  static List<Child> _resolveChildren(List<Child>? parentChildren) {
    if (parentChildren != null && parentChildren.isNotEmpty) {
      return parentChildren;
    }
    return _createEmulatedChildren();
  }

  static List<Child> _createEmulatedChildren() {
    final base = DateTime.now().subtract(const Duration(days: 365));
    return [
      Child(
        id: 1,
        studentId: 'EMU-001',
        firstName: 'Alex',
        lastName: 'Johnson',
        profileImage: null,
        grade: 'Grade 5',
        school: 'Demo School',
        address: '123 Demo St',
        assignedRoute: 1,
        status: ChildStatus.onBus,
        lastSeen: DateTime.now(),
        createdAt: base,
        updatedAt: base,
      ),
      Child(
        id: 2,
        studentId: 'EMU-002',
        firstName: 'Sam',
        lastName: 'Williams',
        profileImage: null,
        grade: 'Grade 3',
        school: 'Demo School',
        address: '456 Demo Ave',
        assignedRoute: 1,
        status: ChildStatus.waiting,
        lastSeen: null,
        createdAt: base,
        updatedAt: base,
      ),
    ];
  }

  /// Trip 1: In Progress - Pickup done, heading to School
  static ParentTrip _buildInProgressTrip(DateTime now, List<Child> children) {
    final scheduledStart = now.subtract(const Duration(minutes: 25));
    final scheduledEnd = now.add(const Duration(minutes: 35));
    final pickupTime = now.subtract(const Duration(minutes: 20));

    final stops = [
      TripStop(
        id: 101,
        name: 'Home - Pickup Point 1',
        address: '123 Demo Street, Nairobi',
        latitude: _baseLat - 0.008,
        longitude: _baseLng + 0.005,
        scheduledTime: scheduledStart,
        actualTime: pickupTime,
        type: StopType.pickup,
        children: children
            .map((c) => Child(
                  id: c.id,
                  studentId: c.studentId,
                  firstName: c.firstName,
                  lastName: c.lastName,
                  profileImage: c.profileImage,
                  grade: c.grade,
                  school: c.school,
                  address: c.address,
                  assignedRoute: c.assignedRoute,
                  status: ChildStatus.pickedUp,
                  lastSeen: c.lastSeen,
                  createdAt: c.createdAt,
                  updatedAt: c.updatedAt,
                ))
            .toList(),
        isCompleted: true,
      ),
      TripStop(
        id: 102,
        name: 'Pickup Point 2',
        address: '150 River Road, Nairobi',
        latitude: _baseLat - 0.004,
        longitude: _baseLng + 0.003,
        scheduledTime: scheduledStart.add(const Duration(minutes: 5)),
        actualTime: pickupTime.add(const Duration(minutes: 3)),
        type: StopType.pickup,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 103,
        name: 'Demo Primary School',
        address: '789 School Road, Nairobi',
        latitude: _baseLat,
        longitude: _baseLng,
        scheduledTime: now.add(const Duration(minutes: 10)),
        actualTime: null,
        type: StopType.school,
        children: children,
        isCompleted: false,
      ),
      TripStop(
        id: 104,
        name: 'Drop-off Point 1',
        address: '456 Demo Avenue, Nairobi',
        latitude: _baseLat + 0.004,
        longitude: _baseLng - 0.002,
        scheduledTime: scheduledEnd.subtract(const Duration(minutes: 10)),
        actualTime: null,
        type: StopType.dropoff,
        children: children,
        isCompleted: false,
      ),
      TripStop(
        id: 105,
        name: 'After-School Drop-off',
        address: '500 Park View, Nairobi',
        latitude: _baseLat + 0.006,
        longitude: _baseLng - 0.004,
        scheduledTime: scheduledEnd,
        actualTime: null,
        type: StopType.dropoff,
        children: children,
        isCompleted: false,
      ),
    ];

    return ParentTrip(
      id: 9001,
      tripName: 'Morning Route A - In Progress',
      routeName: 'Route A - Westside',
      driverName: 'John Kamau',
      driverPhone: '+254700000001',
      driverPhoto: null,
      scheduledStartTime: scheduledStart,
      scheduledEndTime: scheduledEnd,
      actualStartTime: pickupTime,
      actualEndTime: null,
      status: TripStatus.inProgress,
      children: children,
      busNumber: 'KCA 123A',
      busColor: '#4285F4',
      currentLatitude: _baseLat - 0.003,
      currentLongitude: _baseLng + 0.002,
      currentAddress: 'En route to Demo Primary School',
      lastLocationUpdate: now,
      estimatedArrivalMinutes: 8,
      stops: stops,
      createdAt: scheduledStart.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
  }

  /// Trip 2: Scheduled - All stops pending
  static ParentTrip _buildScheduledTrip(DateTime now, List<Child> children) {
    final scheduledStart = now.add(const Duration(minutes: 45));
    final scheduledEnd = now.add(const Duration(hours: 1, minutes: 15));
    final base = now.subtract(const Duration(days: 1));

    final stops = [
      TripStop(
        id: 201,
        name: 'Home - Pickup Point 1',
        address: '123 Demo Street, Nairobi',
        latitude: _baseLat - 0.012,
        longitude: _baseLng + 0.008,
        scheduledTime: scheduledStart,
        actualTime: null,
        type: StopType.pickup,
        children: children,
        isCompleted: false,
      ),
      TripStop(
        id: 202,
        name: 'Pickup Point 2',
        address: '180 Oak Lane, Nairobi',
        latitude: _baseLat - 0.006,
        longitude: _baseLng + 0.005,
        scheduledTime: scheduledStart.add(const Duration(minutes: 8)),
        actualTime: null,
        type: StopType.pickup,
        children: children,
        isCompleted: false,
      ),
      TripStop(
        id: 203,
        name: 'Demo Primary School',
        address: '789 School Road, Nairobi',
        latitude: _baseLat + 0.002,
        longitude: _baseLng - 0.001,
        scheduledTime: now.add(const Duration(hours: 1)),
        actualTime: null,
        type: StopType.school,
        children: children,
        isCompleted: false,
      ),
      TripStop(
        id: 204,
        name: 'Drop-off Point 1',
        address: '456 Demo Avenue, Nairobi',
        latitude: _baseLat + 0.006,
        longitude: _baseLng - 0.004,
        scheduledTime: scheduledEnd.subtract(const Duration(minutes: 12)),
        actualTime: null,
        type: StopType.dropoff,
        children: children,
        isCompleted: false,
      ),
      TripStop(
        id: 205,
        name: 'After-School Drop-off',
        address: '500 Park View, Nairobi',
        latitude: _baseLat + 0.010,
        longitude: _baseLng - 0.006,
        scheduledTime: scheduledEnd,
        actualTime: null,
        type: StopType.dropoff,
        children: children,
        isCompleted: false,
      ),
    ];

    return ParentTrip(
      id: 9002,
      tripName: 'Afternoon Route B - Scheduled',
      routeName: 'Route B - Eastside',
      driverName: 'Mary Wanjiku',
      driverPhone: '+254700000002',
      driverPhoto: null,
      scheduledStartTime: scheduledStart,
      scheduledEndTime: scheduledEnd,
      actualStartTime: null,
      actualEndTime: null,
      status: TripStatus.scheduled,
      children: children,
      busNumber: 'KCB 456B',
      busColor: '#34A853',
      currentLatitude: null,
      currentLongitude: null,
      currentAddress: null,
      lastLocationUpdate: null,
      estimatedArrivalMinutes: null,
      stops: stops,
      createdAt: base,
      updatedAt: base,
    );
  }

  /// Trip 3: Completed - All steps done
  static ParentTrip _buildCompletedTrip1(DateTime now, List<Child> children) {
    final completedAt = now.subtract(const Duration(hours: 2));
    final scheduledStart = completedAt.subtract(const Duration(minutes: 45));
    final pickupTime = completedAt.subtract(const Duration(minutes: 40));
    final schoolTime = completedAt.subtract(const Duration(minutes: 25));
    final dropoffTime = completedAt;
    final base = now.subtract(const Duration(days: 2));

    final stops = [
      TripStop(
        id: 301,
        name: 'Home - Pickup Point',
        address: '123 Demo Street, Nairobi',
        latitude: _baseLat - 0.015,
        longitude: _baseLng + 0.010,
        scheduledTime: scheduledStart,
        actualTime: pickupTime,
        type: StopType.pickup,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 302,
        name: 'Demo Primary School',
        address: '789 School Road, Nairobi',
        latitude: _baseLat,
        longitude: _baseLng,
        scheduledTime: pickupTime.add(const Duration(minutes: 15)),
        actualTime: schoolTime,
        type: StopType.school,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 303,
        name: 'After-School Drop-off',
        address: '456 Demo Avenue, Nairobi',
        latitude: _baseLat + 0.008,
        longitude: _baseLng - 0.005,
        scheduledTime: completedAt,
        actualTime: dropoffTime,
        type: StopType.dropoff,
        children: children,
        isCompleted: true,
      ),
    ];

    return ParentTrip(
      id: 9003,
      tripName: 'Morning Route A - Completed',
      routeName: 'Route A - Westside',
      driverName: 'John Kamau',
      driverPhone: '+254700000001',
      driverPhoto: null,
      scheduledStartTime: scheduledStart,
      scheduledEndTime: completedAt,
      actualStartTime: pickupTime,
      actualEndTime: dropoffTime,
      status: TripStatus.completed,
      children: children,
      busNumber: 'KCA 123A',
      busColor: '#4285F4',
      currentLatitude: _baseLat + 0.008,
      currentLongitude: _baseLng - 0.005,
      currentAddress: '456 Demo Avenue, Nairobi',
      lastLocationUpdate: dropoffTime,
      estimatedArrivalMinutes: 0,
      stops: stops,
      createdAt: base,
      updatedAt: completedAt,
    );
  }

  static ParentTrip _buildCompletedTrip2(DateTime now, List<Child> children) {
    final completedAt = now.subtract(const Duration(days: 1, hours: 2));
    final scheduledStart = completedAt.subtract(const Duration(minutes: 50));
    final base = now.subtract(const Duration(days: 3));

    final stops = [
      TripStop(
        id: 401,
        name: 'Home - Pickup Point',
        address: '200 Oak Lane, Nairobi',
        latitude: _baseLat - 0.020,
        longitude: _baseLng + 0.015,
        scheduledTime: scheduledStart,
        actualTime: scheduledStart.add(const Duration(minutes: 5)),
        type: StopType.pickup,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 402,
        name: 'Demo Primary School',
        address: '789 School Road, Nairobi',
        latitude: _baseLat,
        longitude: _baseLng,
        scheduledTime: scheduledStart.add(const Duration(minutes: 20)),
        actualTime: scheduledStart.add(const Duration(minutes: 28)),
        type: StopType.school,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 403,
        name: 'After-School Drop-off',
        address: '500 Park View, Nairobi',
        latitude: _baseLat + 0.012,
        longitude: _baseLng - 0.008,
        scheduledTime: completedAt,
        actualTime: completedAt,
        type: StopType.dropoff,
        children: children,
        isCompleted: true,
      ),
    ];

    return ParentTrip(
      id: 9004,
      tripName: 'Morning Route B - Completed',
      routeName: 'Route B - Eastside',
      driverName: 'Mary Wanjiku',
      driverPhone: '+254700000002',
      driverPhoto: null,
      scheduledStartTime: scheduledStart,
      scheduledEndTime: completedAt,
      actualStartTime: scheduledStart.add(const Duration(minutes: 5)),
      actualEndTime: completedAt,
      status: TripStatus.completed,
      children: children,
      busNumber: 'KCB 456B',
      busColor: '#34A853',
      currentLatitude: _baseLat + 0.012,
      currentLongitude: _baseLng - 0.008,
      currentAddress: '500 Park View, Nairobi',
      lastLocationUpdate: completedAt,
      estimatedArrivalMinutes: 0,
      stops: stops,
      createdAt: base,
      updatedAt: completedAt,
    );
  }

  static ParentTrip _buildCompletedTrip3(DateTime now, List<Child> children) {
    final completedAt = now.subtract(const Duration(days: 2, hours: 1));
    final scheduledStart = completedAt.subtract(const Duration(minutes: 55));
    final base = now.subtract(const Duration(days: 4));

    final stops = [
      TripStop(
        id: 501,
        name: 'Home - Pickup Point',
        address: '100 River Road, Nairobi',
        latitude: _baseLat - 0.018,
        longitude: _baseLng + 0.012,
        scheduledTime: scheduledStart,
        actualTime: scheduledStart,
        type: StopType.pickup,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 502,
        name: 'Demo Primary School',
        address: '789 School Road, Nairobi',
        latitude: _baseLat + 0.003,
        longitude: _baseLng,
        scheduledTime: scheduledStart.add(const Duration(minutes: 25)),
        actualTime: scheduledStart.add(const Duration(minutes: 22)),
        type: StopType.school,
        children: children,
        isCompleted: true,
      ),
      TripStop(
        id: 503,
        name: 'After-School Drop-off',
        address: '300 Valley Drive, Nairobi',
        latitude: _baseLat + 0.015,
        longitude: _baseLng - 0.010,
        scheduledTime: completedAt,
        actualTime: completedAt,
        type: StopType.dropoff,
        children: children,
        isCompleted: true,
      ),
    ];

    return ParentTrip(
      id: 9005,
      tripName: 'Morning Route C - Completed',
      routeName: 'Route C - Northside',
      driverName: 'Peter Ochieng',
      driverPhone: '+254700000003',
      driverPhoto: null,
      scheduledStartTime: scheduledStart,
      scheduledEndTime: completedAt,
      actualStartTime: scheduledStart,
      actualEndTime: completedAt,
      status: TripStatus.completed,
      children: children,
      busNumber: 'KCC 789C',
      busColor: '#FBBC05',
      currentLatitude: _baseLat + 0.015,
      currentLongitude: _baseLng - 0.010,
      currentAddress: '300 Valley Drive, Nairobi',
      lastLocationUpdate: completedAt,
      estimatedArrivalMinutes: 0,
      stops: stops,
      createdAt: base,
      updatedAt: completedAt,
    );
  }
}
