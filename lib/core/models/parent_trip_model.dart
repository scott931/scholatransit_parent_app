import 'parent_model.dart';

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
    return TripStop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      scheduledTime: DateTime.parse(json['scheduled_time']),
      actualTime: json['actual_time'] != null
          ? DateTime.parse(json['actual_time'])
          : null,
      type: _parseStopType(json['type']),
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

  static StopType _parseStopType(dynamic type) {
    if (type == null) return StopType.pickup;

    switch (type.toString().toLowerCase()) {
      case 'pickup':
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
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParentTrip({
    required this.id,
    this.backendTripId = '',
    required this.tripName,
    required this.routeName,
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
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == TripStatus.inProgress;
  bool get isCompleted => status == TripStatus.completed;
  bool get isScheduled => status == TripStatus.scheduled;

  factory ParentTrip.fromJson(Map<String, dynamic> json) {
    final startRaw = json['scheduled_start_time'] ?? json['scheduled_start'];
    final endRaw = json['scheduled_end_time'] ?? json['scheduled_end'];
    return ParentTrip(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      backendTripId: json['trip_id']?.toString() ?? '',
      tripName: (json['trip_name'] ?? json['trip_id'] ?? '').toString(),
      routeName: json['route_name']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      driverPhone: json['driver_phone']?.toString() ?? '',
      driverPhoto: json['driver_photo']?.toString(),
      scheduledStartTime: _parseTripDateTime(startRaw),
      scheduledEndTime: _parseTripDateTime(endRaw),
      actualStartTime: json['actual_start_time'] != null
          ? DateTime.parse(json['actual_start_time'])
          : null,
      actualEndTime: json['actual_end_time'] != null
          ? DateTime.parse(json['actual_end_time'])
          : null,
      status: _parseTripStatus(json['status']),
      children:
          (json['children'] as List<dynamic>?)
              ?.map((child) => Child.fromJson(child as Map<String, dynamic>))
              .toList() ??
          [],
      busNumber: json['bus_number'],
      busColor: json['bus_color'],
      currentLatitude: _parseLat(json['current_latitude']) ??
          _parseLatFromGeoJson(json['current_location']),
      currentLongitude: _parseLng(json['current_longitude']) ??
          _parseLngFromGeoJson(json['current_location']),
      currentAddress: json['current_address'],
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'])
          : null,
      estimatedArrivalMinutes: json['estimated_arrival_minutes'],
      stops:
          (json['stops'] as List<dynamic>?)
              ?.map((stop) => TripStop.fromJson(stop as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseTripDateTime(json['created_at']),
      updatedAt: _parseTripDateTime(json['updated_at']),
    );
  }

  static DateTime _parseTripDateTime(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static double? _parseLat(dynamic v) =>
      v == null ? null : (v as num).toDouble();

  static double? _parseLng(dynamic v) =>
      v == null ? null : (v as num).toDouble();

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': backendTripId,
      'trip_name': tripName,
      'route_name': routeName,
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
        return TripStatus.scheduled;
      case 'in_progress':
      case 'inprogress':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      case 'delayed':
        return TripStatus.delayed;
      default:
        // Human-readable labels from older serializers
        if (s.contains('progress')) return TripStatus.inProgress;
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
