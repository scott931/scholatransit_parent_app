/// Trip Log Model
///
/// This model represents a trip log entry from the API response.
/// It matches the structure returned by the /api/v1/tracking/trips/ endpoint.
library;

enum TripLogStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  delayed;

  String get displayName {
    switch (this) {
      case TripLogStatus.scheduled:
        return 'Scheduled';
      case TripLogStatus.inProgress:
        return 'In Progress';
      case TripLogStatus.completed:
        return 'Completed';
      case TripLogStatus.cancelled:
        return 'Cancelled';
      case TripLogStatus.delayed:
        return 'Delayed';
    }
  }

  String get apiValue {
    switch (this) {
      case TripLogStatus.scheduled:
        return 'Scheduled';
      case TripLogStatus.inProgress:
        return 'In Progress';
      case TripLogStatus.completed:
        return 'Completed';
      case TripLogStatus.cancelled:
        return 'Cancelled';
      case TripLogStatus.delayed:
        return 'Delayed';
    }
  }

  /// Snake-case status codes from the tracking Trip API.
  String get backendValue {
    switch (this) {
      case TripLogStatus.scheduled:
        return 'scheduled';
      case TripLogStatus.inProgress:
        return 'in_progress';
      case TripLogStatus.completed:
        return 'completed';
      case TripLogStatus.cancelled:
        return 'cancelled';
      case TripLogStatus.delayed:
        return 'delayed';
    }
  }

  static TripLogStatus fromString(String status) {
    final s = status.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (s) {
      case 'scheduled':
      case 'pending':
        return TripLogStatus.scheduled;
      case 'in_progress':
      case 'inprogress':
        return TripLogStatus.inProgress;
      case 'completed':
        return TripLogStatus.completed;
      case 'cancelled':
        return TripLogStatus.cancelled;
      case 'delayed':
        return TripLogStatus.delayed;
      default:
        // Human-readable labels from serializers / toJson()
        if (s.contains('progress')) return TripLogStatus.inProgress;
        if (s.contains('complet')) return TripLogStatus.completed;
        if (s.contains('cancel')) return TripLogStatus.cancelled;
        if (s.contains('delay')) return TripLogStatus.delayed;
        return TripLogStatus.scheduled;
    }
  }
}

enum TripLogType {
  studentPickup,
  studentDropoff,
  scheduled,
  emergency;

  String get displayName {
    switch (this) {
      case TripLogType.studentPickup:
        return 'Student Pickup';
      case TripLogType.studentDropoff:
        return 'Student Dropoff';
      case TripLogType.scheduled:
        return 'Scheduled';
      case TripLogType.emergency:
        return 'Emergency';
    }
  }

  String get apiValue {
    switch (this) {
      case TripLogType.studentPickup:
        return 'Student Pickup';
      case TripLogType.studentDropoff:
        return 'Student Dropoff';
      case TripLogType.scheduled:
        return 'Scheduled';
      case TripLogType.emergency:
        return 'Emergency';
    }
  }

  static TripLogType fromString(String type) {
    final t = type.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (t) {
      case 'student_pickup':
      case 'studentpickup':
      case 'pickup':
        return TripLogType.studentPickup;
      case 'student_dropoff':
      case 'studentdropoff':
      case 'dropoff':
        return TripLogType.studentDropoff;
      case 'scheduled':
        return TripLogType.scheduled;
      case 'emergency':
        return TripLogType.emergency;
      default:
        if (t.contains('drop')) return TripLogType.studentDropoff;
        if (t.contains('pickup') || t.contains('pick')) {
          return TripLogType.studentPickup;
        }
        return TripLogType.scheduled;
    }
  }
}

class TripLog {
  final int id;
  final String tripId;
  final int driver;
  final String driverName;
  final int vehicle;
  final String vehicleName;
  final int route;
  final String routeName;
  final TripLogType tripType;
  final TripLogStatus status;
  final String? startLocation;
  final String? endLocation;
  final String? currentLocation;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final double? totalDistance;
  final double? averageSpeed;
  final double? maxSpeed;
  final String? notes;
  final String? delayReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripLog({
    required this.id,
    required this.tripId,
    required this.driver,
    required this.driverName,
    required this.vehicle,
    required this.vehicleName,
    required this.route,
    required this.routeName,
    required this.tripType,
    required this.status,
    this.startLocation,
    this.endLocation,
    this.currentLocation,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.totalDistance,
    this.averageSpeed,
    this.maxSpeed,
    this.notes,
    this.delayReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse coordinates from WKT (Well-Known Text) format
  /// Example: "SRID=4326;POINT (40.90091757555056 -2.267229174184562)"
  static Map<String, double>? parseWktCoordinates(String? wktString) {
    if (wktString == null || wktString.isEmpty) return null;

    try {
      // Extract coordinates from WKT format
      final pointMatch = RegExp(r'POINT\s*\(([^)]+)\)').firstMatch(wktString);
      if (pointMatch != null) {
        final coords = pointMatch.group(1)?.split(' ') ?? [];
        if (coords.length >= 2) {
          return {
            'longitude': double.parse(coords[0]),
            'latitude': double.parse(coords[1]),
          };
        }
      }
    } catch (e) {
      print('Error parsing WKT coordinates: $e');
    }
    return null;
  }

  /// Get formatted duration between actual start and end times
  Duration? get actualDuration {
    if (actualStart != null && actualEnd != null) {
      return actualEnd!.difference(actualStart!);
    }
    return null;
  }

  /// Get formatted duration between scheduled start and end times
  Duration get scheduledDuration {
    return scheduledEnd.difference(scheduledStart);
  }

  /// Check if trip is currently active
  bool get isActive => status == TripLogStatus.inProgress;

  /// Check if trip is completed
  bool get isCompleted => status == TripLogStatus.completed;

  /// Check if trip is cancelled
  bool get isCancelled => status == TripLogStatus.cancelled;

  /// Check if trip is delayed
  bool get isDelayed => status == TripLogStatus.delayed;

  /// Check if trip is overdue (past scheduled end time and still active)
  bool get isOverdue {
    if (isActive && actualStart != null) {
      return DateTime.now().isAfter(scheduledEnd);
    }
    return false;
  }

  /// Get formatted actual duration string
  String get formattedActualDuration {
    final duration = actualDuration;
    if (duration == null) return '--';

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Get formatted scheduled duration string
  String get formattedScheduledDuration {
    final duration = scheduledDuration;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case TripLogStatus.scheduled:
        return '#FFA500'; // Orange
      case TripLogStatus.inProgress:
        return '#4CAF50'; // Green
      case TripLogStatus.completed:
        return '#2196F3'; // Blue
      case TripLogStatus.cancelled:
        return '#F44336'; // Red
      case TripLogStatus.delayed:
        return '#FF9800'; // Deep Orange
    }
  }

  /// Get type color for UI
  String get typeColor {
    switch (tripType) {
      case TripLogType.studentPickup:
        return '#4CAF50'; // Green
      case TripLogType.studentDropoff:
        return '#2196F3'; // Blue
      case TripLogType.scheduled:
        return '#9C27B0'; // Purple
      case TripLogType.emergency:
        return '#F44336'; // Red
    }
  }

  static DateTime _parseRequiredDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int _parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Map) {
      final nested = value['id'] ?? value['pk'];
      return _parseInt(nested, fallback);
    }
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Create TripLog from JSON response
  factory TripLog.fromJson(Map<String, dynamic> json) {
    return TripLog(
      id: _parseInt(json['id']),
      tripId: json['trip_id']?.toString() ?? '',
      driver: _parseInt(json['driver']),
      driverName: json['driver_name']?.toString() ?? '',
      vehicle: _parseInt(json['vehicle']),
      vehicleName: json['vehicle_name']?.toString() ?? '',
      route: _parseInt(json['route']),
      routeName: json['route_name']?.toString() ?? '',
      tripType: TripLogType.fromString(json['trip_type']?.toString() ?? ''),
      status: TripLogStatus.fromString(json['status']?.toString() ?? ''),
      startLocation: json['start_location']?.toString(),
      endLocation: json['end_location']?.toString(),
      currentLocation: json['current_location']?.toString(),
      scheduledStart: _parseRequiredDate(json['scheduled_start']),
      scheduledEnd: _parseRequiredDate(json['scheduled_end']),
      actualStart: _parseOptionalDate(json['actual_start']),
      actualEnd: _parseOptionalDate(json['actual_end']),
      totalDistance: _parseDouble(json['total_distance']),
      averageSpeed: _parseDouble(json['average_speed']),
      maxSpeed: _parseDouble(json['max_speed']),
      notes: json['notes']?.toString(),
      delayReason: json['delay_reason']?.toString(),
      createdAt: _parseRequiredDate(json['created_at']),
      updatedAt: _parseRequiredDate(json['updated_at']),
    );
  }

  /// Map tracking API trip payloads into [ParentTrip.fromJson] field names.
  Map<String, dynamic> toParentTripJson() {
    final wktCurrent = parseWktCoordinates(currentLocation);
    return {
      'id': id,
      'trip_id': tripId,
      'driver': driver,
      'driver_name': driverName,
      'vehicle': vehicle,
      'vehicle_name': vehicleName,
      'route': route,
      'route_name': routeName,
      'trip_type': tripType.apiValue,
      'status': status.backendValue,
      'start_location': startLocation,
      'end_location': endLocation,
      'current_location': currentLocation,
      if (wktCurrent != null) 'current_latitude': wktCurrent['latitude'],
      if (wktCurrent != null) 'current_longitude': wktCurrent['longitude'],
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert TripLog to JSON
  Map<String, dynamic> toJson() {
    final wktCurrent = parseWktCoordinates(currentLocation);
    return {
      'id': id,
      'trip_id': tripId,
      'driver': driver,
      'driver_name': driverName,
      'vehicle': vehicle,
      'vehicle_name': vehicleName,
      'route': route,
      'route_name': routeName,
      'trip_type': tripType.apiValue,
      'status': status.backendValue,
      'start_location': startLocation,
      'end_location': endLocation,
      'current_location': currentLocation,
      if (wktCurrent != null) 'current_latitude': wktCurrent['latitude'],
      if (wktCurrent != null) 'current_longitude': wktCurrent['longitude'],
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'total_distance': totalDistance,
      'average_speed': averageSpeed,
      'max_speed': maxSpeed,
      'notes': notes,
      'delay_reason': delayReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TripLog(id: $id, tripId: $tripId, driver: $driverName, vehicle: $vehicleName, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Trip Logs Response Model
///
/// Represents the paginated response from the trip logs API
class TripLogsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<TripLog> results;

  const TripLogsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  static List<TripLog> _parseResults(dynamic raw) {
    if (raw is! List) return [];
    final logs = <TripLog>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        logs.add(TripLog.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Skip malformed trip rows — keep the rest of the page.
      }
    }
    return logs;
  }

  /// Create TripLogsResponse from JSON
  factory TripLogsResponse.fromJson(Map<String, dynamic> json) {
    return TripLogsResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: _parseResults(json['results']),
    );
  }

  /// Convert TripLogsResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((tripLog) => tripLog.toJson()).toList(),
    };
  }

  /// Check if there are more pages
  bool get hasNext => next != null && next!.isNotEmpty;

  /// Check if there are previous pages
  bool get hasPrevious => previous != null && previous!.isNotEmpty;

  @override
  String toString() {
    return 'TripLogsResponse(count: $count, hasNext: $hasNext, hasPrevious: $hasPrevious, results: ${results.length})';
  }
}
