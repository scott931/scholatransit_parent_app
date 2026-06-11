import 'parent_model.dart';
import 'student_model.dart';
import '../utils/coordinate_utils.dart';

enum TripStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  delayed;

  String get displayName {
    switch (this) {
      case TripStatus.scheduled:
        return 'Scheduled';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.delayed:
        return 'Delayed';
    }
  }

  String get apiValue {
    switch (this) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.inProgress:
        return 'in_progress';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
      case TripStatus.delayed:
        return 'delayed';
    }
  }

  @override
  String toString() => apiValue;
}

enum StopType {
  pickup,
  dropoff,
  school;

  String get displayName {
    switch (this) {
      case StopType.pickup:
        return 'Pickup';
      case StopType.dropoff:
        return 'Drop-off';
      case StopType.school:
        return 'School';
    }
  }

  String get apiValue {
    switch (this) {
      case StopType.pickup:
        return 'pickup';
      case StopType.dropoff:
        return 'dropoff';
      case StopType.school:
        return 'school';
    }
  }

  @override
  String toString() => apiValue;
}

class TripStop {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final StopType type;
  final List<Child> children;
  final bool isCompleted;

  const TripStop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledTime,
    this.actualTime,
    required this.type,
    required this.children,
    required this.isCompleted,
  });

  factory TripStop.fromJson(Map<String, dynamic> json) {
    final coords = CoordinateUtils.fromStopJson(json);
    return TripStop(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['stop_name'] ?? '',
      address: json['address'] ?? '',
      latitude: coords?['latitude'] ?? 0.0,
      longitude: coords?['longitude'] ?? 0.0,
      scheduledTime: _parseScheduledTime(json),
      actualTime: json['actual_time'] != null
          ? DateTime.tryParse(json['actual_time'].toString())
          : null,
      type: _parseStopType(json['type'] ?? json['stop_type']),
      children:
          (json['children'] as List<dynamic>?)
              ?.map((child) => Child.fromJson(child as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'scheduled_time': scheduledTime.toIso8601String(),
      'actual_time': actualTime?.toIso8601String(),
      'type': type.toString(),
      'children': children.map((child) => child.toJson()).toList(),
      'is_completed': isCompleted,
    };
  }

  static DateTime _parseScheduledTime(Map<String, dynamic> json) {
    for (final key in [
      'scheduled_time',
      'estimated_time',
      'estimated_arrival_time',
    ]) {
      final parsed = DateTime.tryParse(json[key]?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static StopType _parseStopType(dynamic type) {
    if (type == null) return StopType.pickup;

    switch (type.toString().toLowerCase()) {
      case 'pickup':
      case 'both':
        return StopType.pickup;
      case 'dropoff':
      case 'drop_off':
        return StopType.dropoff;
      case 'school':
        return StopType.school;
      default:
        return StopType.pickup;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripStop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TripStop(id: $id, name: $name, type: $type)';
  }
}

class ParentTrip {
  final int id;
  /// Backend `trip_id` string (used in `/tracking/trips/{trip_id}/`), not always numeric `id`.
  final String backendTripId;
  final String tripName;
  final String routeName;
  final int? routeId;
  final int? driverId;
  final int? vehicleId;
  final String driverName;
  final String driverPhone;
  final String? driverPhoto;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final TripStatus status;
  final List<Child> children;
  final String? busNumber;
  final String? busColor;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? currentAddress;
  final DateTime? lastLocationUpdate;
  final int? estimatedArrivalMinutes;
  final List<TripStop> stops;
  /// Backend `is_active` flag when the trip is live-trackable regardless of status label.
  final bool? isActiveFromApi;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParentTrip({
    required this.id,
    this.backendTripId = '',
    required this.tripName,
    required this.routeName,
    this.routeId,
    this.driverId,
    this.vehicleId,
    required this.driverName,
    required this.driverPhone,
    this.driverPhoto,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.status,
    required this.children,
    this.busNumber,
    this.busColor,
    this.currentLatitude,
    this.currentLongitude,
    this.currentAddress,
    this.lastLocationUpdate,
    this.estimatedArrivalMinutes,
    required this.stops,
    this.isActiveFromApi,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True when the bus trip is live on the road (matches admin "active route").
  bool get isActive {
    if (isActiveFromApi == true) return true;
    if (status == TripStatus.inProgress || status == TripStatus.delayed) {
      return true;
    }
    // Started but not ended — common when status label lags behind actual_start.
    if (actualStartTime != null && actualEndTime == null && !isCompleted) {
      return true;
    }
    return false;
  }

  /// Trips that should appear on the parent map / tracking tab.
  bool get isTrackable =>
      isActive ||
      (status == TripStatus.scheduled &&
          actualStartTime != null &&
          actualEndTime == null);
  bool get isCompleted => status == TripStatus.completed;
  bool get isScheduled => status == TripStatus.scheduled;

  /// From `my-students` → `upcoming_trips[]` (scheduled trips on child's route).
  factory ParentTrip.fromStudentUpcomingTrip(
    Student student,
    Map<String, dynamic> json,
  ) {
    final now = DateTime.now();
    final status = _parseTripStatus(json['status']);
    return ParentTrip(
      id: 0,
      backendTripId: json['trip_id']?.toString() ?? '',
      tripName: json['trip_id']?.toString().isNotEmpty == true
          ? json['trip_id'].toString()
          : (student.routeName ?? 'Scheduled trip'),
      routeName: student.routeName ?? '',
      routeId: student.assignedRoute,
      driverName: json['driver_name']?.toString() ?? student.assignedDriverName ?? '',
      driverPhone: '',
      scheduledStartTime: _parseTripDateTime(json['scheduled_start']),
      scheduledEndTime: _parseTripDateTime(json['scheduled_end']),
      status: status,
      children: const [],
      busNumber: json['vehicle_license']?.toString() ??
          student.assignedVehicleLicense,
      stops: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Fallback when list APIs return empty but `my-students` has `current_trip`.
  factory ParentTrip.fromStudentCurrentTrip(Student student) {
    final current = student.currentTrip!;
    final now = DateTime.now();
    final status = _parseTripStatus(current.status);
    return ParentTrip(
      id: 0,
      backendTripId: current.tripId,
      tripName: current.tripId.isNotEmpty
          ? current.tripId
          : (student.routeName ?? 'Bus trip'),
      routeName: student.routeName ?? '',
      routeId: student.assignedRoute,
      driverName: current.driverName,
      driverPhone: '',
      scheduledStartTime:
          DateTime.tryParse(current.scheduledStart) ?? now,
      scheduledEndTime: DateTime.tryParse(current.scheduledEnd) ?? now,
      actualStartTime: current.actualStart.isNotEmpty
          ? DateTime.tryParse(current.actualStart)
          : null,
      actualEndTime: current.actualEnd.isNotEmpty
          ? DateTime.tryParse(current.actualEnd)
          : null,
      status: status,
      children: const [],
      busNumber: current.vehicleLicense.isNotEmpty
          ? current.vehicleLicense
          : student.assignedVehicleLicense,
      stops: const [],
      isActiveFromApi: status == TripStatus.inProgress,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ParentTrip.fromJson(Map<String, dynamic> json) {
    final startRaw = json['scheduled_start_time'] ?? json['scheduled_start'];
    final endRaw = json['scheduled_end_time'] ?? json['scheduled_end'];

    final routeRaw = json['route'];
    final routeMap = routeRaw is Map
        ? Map<String, dynamic>.from(routeRaw)
        : null;
    final routeDetail = json['route_detail'] is Map
        ? Map<String, dynamic>.from(json['route_detail'] as Map)
        : null;

    var stops = <TripStop>[];
    void addStopsFromList(List<dynamic> list) {
      for (final raw in list) {
        if (raw is! Map) continue;
        try {
          stops.add(TripStop.fromJson(Map<String, dynamic>.from(raw)));
        } catch (_) {
          // Ignore malformed stops — trip should still load.
        }
      }
    }

    if (json['stops'] is List) addStopsFromList(json['stops'] as List);
    if (stops.isEmpty && routeMap?['stops'] is List) {
      addStopsFromList(routeMap!['stops'] as List);
    }
    if (stops.isEmpty && routeDetail?['waypoints'] is List) {
      addStopsFromList(routeDetail!['waypoints'] as List);
    }
    if (stops.isEmpty) {
      _appendEndpointStops(stops, json['start_location'], json['end_location']);
    }

    return ParentTrip(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      backendTripId: json['trip_id']?.toString() ?? '',
      tripName: (json['trip_name'] ?? json['trip_id'] ?? '').toString(),
      routeName: (json['route_name'] ??
              routeMap?['name'] ??
              routeDetail?['name'] ??
              '')
          .toString(),
      routeId: CoordinateUtils.parseRouteId(
        routeRaw ?? json['route_id'] ?? routeDetail?['id'],
      ),
      driverId: _parseOptionalInt(json['driver'] ?? json['driver_id']),
      vehicleId: _parseOptionalInt(json['vehicle'] ?? json['vehicle_id']),
      driverName: json['driver_name']?.toString() ?? '',
      driverPhone: json['driver_phone']?.toString() ?? '',
      driverPhoto: json['driver_photo']?.toString(),
      scheduledStartTime: _parseTripDateTime(startRaw),
      scheduledEndTime: _parseTripDateTime(endRaw),
      actualStartTime: _parseOptionalDate(
        json['actual_start_time'] ?? json['actual_start'],
      ),
      actualEndTime: _parseOptionalDate(
        json['actual_end_time'] ?? json['actual_end'],
      ),
      status: _parseTripStatus(json['status']),
      // Do not map `students_on_route` — it lists all route students and can
      // cause the client-side child filter to drop valid parent-scoped trips.
      children: _parseChildren(json['children']),
      busNumber: json['bus_number']?.toString() ??
          json['vehicle_name']?.toString() ??
          json['vehicle_license_plate']?.toString(),
      busColor: json['bus_color'],
      currentLatitude: _parseLat(json['current_latitude']) ??
          _parseLatFromGeoJson(json['current_location']) ??
          _parseLatFromWkt(json['current_location']),
      currentLongitude: _parseLng(json['current_longitude']) ??
          _parseLngFromGeoJson(json['current_location']) ??
          _parseLngFromWkt(json['current_location']),
      currentAddress: json['current_address'],
      lastLocationUpdate: _parseOptionalDate(
        json['last_location_update'] ?? json['last_update'] ?? json['updated_at'],
      ),
      estimatedArrivalMinutes: json['estimated_arrival_minutes'],
      stops: stops,
      isActiveFromApi: json['is_active'] is bool
          ? json['is_active'] as bool
          : json['is_active']?.toString().toLowerCase() == 'true',
      createdAt: _parseTripDateTime(json['created_at']),
      updatedAt: _parseTripDateTime(json['updated_at']),
    );
  }

  static List<Child> _parseChildren(dynamic raw) {
    if (raw is! List) return [];
    final children = <Child>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        children.add(Child.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Ignore malformed child rows.
      }
    }
    return children;
  }

  static DateTime _parseTripDateTime(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseOptionalDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static double? _parseLat(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static double? _parseLng(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _parseOptionalInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is Map) {
      return _parseOptionalInt(v['id'] ?? v['pk']);
    }
    return int.tryParse(v.toString());
  }

  static double? _parseLatFromGeoJson(dynamic v) {
    if (v is Map && v['coordinates'] is List) {
      final c = v['coordinates'] as List;
      if (c.length >= 2) return (c[1] as num).toDouble();
    }
    return null;
  }

  static double? _parseLngFromGeoJson(dynamic v) {
    if (v is Map && v['coordinates'] is List) {
      final c = v['coordinates'] as List;
      if (c.length >= 2) return (c[0] as num).toDouble();
    }
    return null;
  }

  /// WKT POINT (lng lat) from tracking serializers (same as driver app).
  static double? _parseLatFromWkt(dynamic v) {
    if (v is! String) return null;
    final m = RegExp(r'POINT\s*\(([^)]+)\)', caseSensitive: false).firstMatch(v);
    if (m == null) return null;
    final parts = m.group(1)?.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.length < 2) return null;
    return double.tryParse(parts[1]);
  }

  static double? _parseLngFromWkt(dynamic v) {
    if (v is! String) return null;
    final m = RegExp(r'POINT\s*\(([^)]+)\)', caseSensitive: false).firstMatch(v);
    if (m == null) return null;
    final parts = m.group(1)?.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.length < 2) return null;
    return double.tryParse(parts[0]);
  }

  static void _appendEndpointStops(
    List<TripStop> stops,
    dynamic startLocation,
    dynamic endLocation,
  ) {
    final startLat = _parseLatFromWkt(startLocation);
    final startLng = _parseLngFromWkt(startLocation);
    final endLat = _parseLatFromWkt(endLocation);
    final endLng = _parseLngFromWkt(endLocation);

    if (startLat != null && startLng != null) {
      stops.add(
        TripStop(
          id: -1,
          name: 'Start',
          address: '',
          latitude: startLat,
          longitude: startLng,
          scheduledTime: DateTime.now(),
          type: StopType.pickup,
          children: const [],
          isCompleted: false,
        ),
      );
    }
    if (endLat != null && endLng != null) {
      stops.add(
        TripStop(
          id: -2,
          name: 'End',
          address: '',
          latitude: endLat,
          longitude: endLng,
          scheduledTime: DateTime.now(),
          type: StopType.dropoff,
          children: const [],
          isCompleted: false,
        ),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': backendTripId,
      'trip_name': tripName,
      'route_name': routeName,
      'route': routeId,
      'route_id': routeId,
      'driver': driverId,
      'driver_id': driverId,
      'vehicle': vehicleId,
      'vehicle_id': vehicleId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_photo': driverPhoto,
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'scheduled_end_time': scheduledEndTime.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'status': status.toString(),
      'children': children.map((child) => child.toJson()).toList(),
      'bus_number': busNumber,
      'bus_color': busColor,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'current_address': currentAddress,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'estimated_arrival_minutes': estimatedArrivalMinutes,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static TripStatus _parseTripStatus(dynamic status) {
    if (status == null) return TripStatus.scheduled;

    final s = status.toString().toLowerCase().replaceAll(' ', '_');
    switch (s) {
      case 'scheduled':
      case 'pending':
        return TripStatus.scheduled;
      case 'in_progress':
      case 'inprogress':
      case 'in-progress':
      case 'active':
      case 'started':
      case 'running':
      case 'live':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'delayed':
        return TripStatus.delayed;
      default:
        // Human-readable labels from older serializers
        if (s.contains('progress') || s == 'active' || s.contains('activ')) {
          return TripStatus.inProgress;
        }
        if (s.contains('schedul')) return TripStatus.scheduled;
        if (s.contains('complet')) return TripStatus.completed;
        if (s.contains('cancel')) return TripStatus.cancelled;
        if (s.contains('delay')) return TripStatus.delayed;
        return TripStatus.scheduled;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParentTrip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ParentTrip(id: $id, name: $tripName, status: $status)';
  }
}

/// UI filters for parent trip lists (dashboard vs schedule vs live map).
extension ParentTripListFilters on List<ParentTrip> {
  /// Trips currently in progress on the road (Live Tracking tab / drawer).
  List<ParentTrip> get liveTrips => where((t) => t.isActive).toList();

  /// Scheduled-only trips for the Schedule tab.
  List<ParentTrip> get scheduledTrips =>
      where((t) => t.isScheduled).toList();
}
