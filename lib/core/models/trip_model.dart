enum TripStatus { pending, inProgress, completed, cancelled, delayed }

enum TripType { pickup, dropoff, scheduled, emergency }

class Trip {
  final int id;
  final String tripId;
  final int driverId;
  final String? driverName;
  final int? vehicleId;
  final String? vehicleName;
  final int? routeId;
  final String? routeName;
  final TripStatus status;
  final TripType type;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String? startLocation;
  final String? endLocation;
  final String? currentLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String? notes;
  final String? delayReason;
  final int? odometerReading;
  final double? distance;
  final double? averageSpeed;
  final double? maxSpeed;
  final int? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ETA-related fields
  final DateTime? estimatedArrival;
  final double? currentSpeed;
  final bool? etaIsDelayed;
  final String? etaStatus;
  final double? trafficMultiplier;
  final DateTime? etaLastUpdated;

  const Trip({
    required this.id,
    required this.tripId,
    required this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleName,
    this.routeId,
    this.routeName,
    required this.status,
    required this.type,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.startLocation,
    this.endLocation,
    this.currentLocation,
    this.currentLatitude,
    this.currentLongitude,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.notes,
    this.delayReason,
    this.odometerReading,
    this.distance,
    this.averageSpeed,
    this.maxSpeed,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedArrival,
    this.currentSpeed,
    this.etaIsDelayed,
    this.etaStatus,
    this.trafficMultiplier,
    this.etaLastUpdated,
  });

  bool get isActive => status == TripStatus.inProgress;
  bool get isCompleted => status == TripStatus.completed;
  bool get isCancelled => status == TripStatus.cancelled;
  bool get isDelayed => status == TripStatus.delayed;

  Duration? get actualDuration {
    if (actualStart != null && actualEnd != null) {
      return actualEnd!.difference(actualStart!);
    }
    return null;
  }

  Duration get scheduledDuration {
    return scheduledEnd.difference(scheduledStart);
  }

  bool get isOverdue {
    if (isActive && actualStart != null) {
      return DateTime.now().isAfter(scheduledEnd);
    }
    return false;
  }

  // ETA-related getters
  Duration? get timeToArrival {
    if (estimatedArrival == null) return null;
    return estimatedArrival!.difference(DateTime.now());
  }

  String get formattedTimeToArrival {
    final duration = timeToArrival;
    if (duration == null) return '--';

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  bool get isRunningLate {
    if (estimatedArrival == null) return false;
    return estimatedArrival!.isAfter(scheduledEnd);
  }

  String get etaStatusDisplay {
    if (etaStatus != null) return etaStatus!;

    if (estimatedArrival == null) return 'Calculating...';

    if (isRunningLate) {
      return 'Delayed';
    } else if ((timeToArrival?.inMinutes ?? 0) <= 5) {
      return 'Arriving Soon';
    } else if ((timeToArrival?.inMinutes ?? 0) <= 15) {
      return 'On Time';
    } else {
      return 'Scheduled';
    }
  }

  int get etaColor {
    if (estimatedArrival == null) return 0xFF9E9E9E; // Grey

    if (isRunningLate) {
      return 0xFFD32F2F; // Red
    } else if ((timeToArrival?.inMinutes ?? 0) <= 5) {
      return 0xFF4CAF50; // Green
    } else {
      return 0xFF2196F3; // Blue
    }
  }

  String get trafficConditions {
    if (trafficMultiplier == null) return 'Unknown';

    if (trafficMultiplier! <= 0.8) return 'Light Traffic';
    if (trafficMultiplier! <= 1.2) return 'Normal Traffic';
    if (trafficMultiplier! <= 1.5) return 'Heavy Traffic';
    return 'Severe Traffic';
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    final startCoords = _resolveCoordinatePair(
      latitudeValue: json['start_latitude'],
      longitudeValue: json['start_longitude'],
      locationValue: json['start_location'],
    );
    final endCoords = _resolveCoordinatePair(
      latitudeValue: json['end_latitude'],
      longitudeValue: json['end_longitude'],
      locationValue: json['end_location'],
    );
    final currentCoords = _resolveCoordinatePair(
      latitudeValue: json['current_latitude'],
      longitudeValue: json['current_longitude'],
      locationValue: json['current_location'],
    );

    return Trip(
      id: json['id'] ?? 0,
      tripId: json['trip_id'] ?? '',
      driverId: json['driver'] ?? json['driver_id'] ?? 0,
      driverName: json['driver_name'],
      vehicleId: json['vehicle'] ?? json['vehicle_id'],
      vehicleName: json['vehicle_name'],
      routeId: json['route'] ?? json['route_id'],
      routeName: json['route_name'],
      status: _parseTripStatus(json['status']),
      type: _parseTripType(json['trip_type']),
      scheduledStart: DateTime.parse(json['scheduled_start']),
      scheduledEnd: DateTime.parse(json['scheduled_end']),
      actualStart: json['actual_start'] != null
          ? DateTime.parse(json['actual_start'])
          : null,
      actualEnd: json['actual_end'] != null
          ? DateTime.parse(json['actual_end'])
          : null,
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      currentLocation: json['current_location']?.toString(),
      currentLatitude: currentCoords?['latitude'],
      currentLongitude: currentCoords?['longitude'],
      startLatitude: startCoords?['latitude'],
      startLongitude: startCoords?['longitude'],
      endLatitude: endCoords?['latitude'],
      endLongitude: endCoords?['longitude'],
      notes: json['notes'],
      delayReason: json['delay_reason'],
      odometerReading: json['odometer_reading'],
      distance:
          json['total_distance']?.toDouble() ?? json['distance']?.toDouble(),
      averageSpeed: json['average_speed']?.toDouble(),
      maxSpeed: json['max_speed']?.toDouble(),
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      estimatedArrival: json['estimated_arrival'] != null
          ? DateTime.parse(json['estimated_arrival'])
          : null,
      currentSpeed: json['current_speed']?.toDouble(),
      etaIsDelayed: json['is_delayed'],
      etaStatus: json['eta_status'],
      trafficMultiplier: json['traffic_multiplier']?.toDouble(),
      etaLastUpdated: json['eta_last_updated'] != null
          ? DateTime.parse(json['eta_last_updated'])
          : null,
    );
  }

  // Backend variant mapper to handle response keys from tracking endpoint
  factory Trip.fromBackend(Map<String, dynamic> json) {
    final startCoords = _resolveCoordinatePair(
      latitudeValue: json['start_latitude'],
      longitudeValue: json['start_longitude'],
      locationValue: json['start_location'],
    );
    final endCoords = _resolveCoordinatePair(
      latitudeValue: json['end_latitude'],
      longitudeValue: json['end_longitude'],
      locationValue: json['end_location'],
    );
    final currentCoords = _resolveCoordinatePair(
      latitudeValue: json['current_latitude'],
      longitudeValue: json['current_longitude'],
      locationValue: json['current_location'],
    );

    return Trip(
      id: json['id'] ?? 0,
      tripId: json['trip_id'] ?? '',
      driverId: json['driver'] ?? json['driver_id'] ?? 0,
      driverName: json['driver_name'],
      vehicleId: json['vehicle'] ?? json['vehicle_id'],
      vehicleName: json['vehicle_name'],
      routeId: json['route'] ?? json['route_id'],
      routeName: json['route_name'],
      status: _parseTripStatus(json['status']),
      type: _parseTripType(json['trip_type']),
      scheduledStart: DateTime.parse(json['scheduled_start']),
      scheduledEnd: DateTime.parse(json['scheduled_end']),
      actualStart: json['actual_start'] != null
          ? DateTime.parse(json['actual_start'])
          : null,
      actualEnd: json['actual_end'] != null
          ? DateTime.parse(json['actual_end'])
          : null,
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      currentLocation: json['current_location']?.toString(),
      currentLatitude: currentCoords?['latitude'],
      currentLongitude: currentCoords?['longitude'],
      startLatitude: startCoords?['latitude'],
      startLongitude: startCoords?['longitude'],
      endLatitude: endCoords?['latitude'],
      endLongitude: endCoords?['longitude'],
      notes: json['notes'],
      delayReason: json['delay_reason'],
      odometerReading: json['odometer_reading'],
      distance:
          json['total_distance']?.toDouble() ?? json['distance']?.toDouble(),
      averageSpeed: json['average_speed']?.toDouble(),
      maxSpeed: json['max_speed']?.toDouble(),
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      estimatedArrival: json['estimated_arrival'] != null
          ? DateTime.parse(json['estimated_arrival'])
          : null,
      currentSpeed: json['current_speed']?.toDouble(),
      etaIsDelayed: json['is_delayed'],
      etaStatus: json['eta_status'],
      trafficMultiplier: json['traffic_multiplier']?.toDouble(),
      etaLastUpdated: json['eta_last_updated'] != null
          ? DateTime.parse(json['eta_last_updated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'driver': driverId,
      'driver_name': driverName,
      'vehicle': vehicleId,
      'vehicle_name': vehicleName,
      'route': routeId,
      'route_name': routeName,
      'status': status.name,
      'trip_type': type.name,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'start_location': startLocation,
      'end_location': endLocation,
      'current_location': currentLocation,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'notes': notes,
      'delay_reason': delayReason,
      'odometer_reading': odometerReading,
      'total_distance': distance,
      'average_speed': averageSpeed,
      'max_speed': maxSpeed,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'estimated_arrival': estimatedArrival?.toIso8601String(),
      'current_speed': currentSpeed,
      'is_delayed': etaIsDelayed,
      'eta_status': etaStatus,
      'traffic_multiplier': trafficMultiplier,
      'eta_last_updated': etaLastUpdated?.toIso8601String(),
    };
  }

  static TripStatus _parseTripStatus(String? status) {
    print('🔍 DEBUG: Parsing trip status: "$status"');
    final parsedStatus = switch (status?.toLowerCase()) {
      'pending' => TripStatus.pending,
      'in_progress' || 'in-progress' || 'in progress' => TripStatus.inProgress,
      'completed' => TripStatus.completed,
      'cancelled' => TripStatus.cancelled,
      'delayed' => TripStatus.delayed,
      _ => TripStatus.pending,
    };
    print('🔍 DEBUG: Parsed status: $parsedStatus');
    return parsedStatus;
  }

  static TripType _parseTripType(String? type) {
    switch (type?.toLowerCase()) {
      case 'pickup':
        return TripType.pickup;
      case 'dropoff':
        return TripType.dropoff;
      case 'scheduled':
        return TripType.scheduled;
      case 'emergency':
        return TripType.emergency;
      default:
        return TripType.scheduled;
    }
  }

  // Helper method to parse WKT coordinates
  // Example: "SRID=4326;POINT (36.82858656398285 -1.2917814999850434)"
  static Map<String, double>? _parseWktCoordinates(String? wktString) {
    if (wktString == null || wktString.isEmpty) return null;

    try {
      // Extract coordinates from WKT format
      // Pattern: SRID=4326;POINT (longitude latitude)
      final regex = RegExp(r'POINT\s*\(([^)]+)\)');
      final match = regex.firstMatch(wktString);

      if (match != null) {
        final coordsString = match.group(1);
        final coords = coordsString?.split(' ') ?? [];

        if (coords.length >= 2) {
          final longitude = double.tryParse(coords[0]);
          final latitude = double.tryParse(coords[1]);

          if (longitude != null && latitude != null) {
            print(
              '🔍 DEBUG: Parsed WKT coordinates - Lat: $latitude, Lng: $longitude',
            );
            return {'latitude': latitude, 'longitude': longitude};
          }
        }
      }

      print('❌ DEBUG: Failed to parse WKT: $wktString');
      return null;
    } catch (e) {
      print('❌ DEBUG: Error parsing WKT coordinates: $e');
      return null;
    }
  }

  static Map<String, double>? _parseGeoJsonCoordinates(dynamic value) {
    if (value is Map && value['coordinates'] is List) {
      final coords = value['coordinates'] as List;
      if (coords.length >= 2) {
        final longitude = _toDouble(coords[0]);
        final latitude = _toDouble(coords[1]);
        if (longitude != null && latitude != null) {
          return {'latitude': latitude, 'longitude': longitude};
        }
      }
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Map<String, double>? _resolveCoordinatePair({
    dynamic latitudeValue,
    dynamic longitudeValue,
    dynamic locationValue,
  }) {
    final latitude = _toDouble(latitudeValue);
    final longitude = _toDouble(longitudeValue);
    if (latitude != null && longitude != null) {
      return {'latitude': latitude, 'longitude': longitude};
    }

    final geoJson = _parseGeoJsonCoordinates(locationValue);
    if (geoJson != null) return geoJson;

    if (locationValue is String) {
      final wkt = _parseWktCoordinates(locationValue);
      if (wkt != null) return wkt;
    }

    return null;
  }

  Trip copyWith({
    int? id,
    String? tripId,
    int? driverId,
    String? driverName,
    int? vehicleId,
    String? vehicleName,
    int? routeId,
    String? routeName,
    TripStatus? status,
    TripType? type,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? actualStart,
    DateTime? actualEnd,
    String? startLocation,
    String? endLocation,
    String? currentLocation,
    double? currentLatitude,
    double? currentLongitude,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    String? notes,
    String? delayReason,
    int? odometerReading,
    double? distance,
    double? averageSpeed,
    double? maxSpeed,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedArrival,
    double? currentSpeed,
    bool? etaIsDelayed,
    String? etaStatus,
    double? trafficMultiplier,
    DateTime? etaLastUpdated,
  }) {
    return Trip(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      status: status ?? this.status,
      type: type ?? this.type,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      actualStart: actualStart ?? this.actualStart,
      actualEnd: actualEnd ?? this.actualEnd,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      currentLocation: currentLocation ?? this.currentLocation,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      notes: notes ?? this.notes,
      delayReason: delayReason ?? this.delayReason,
      odometerReading: odometerReading ?? this.odometerReading,
      distance: distance ?? this.distance,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      etaIsDelayed: etaIsDelayed ?? this.etaIsDelayed,
      etaStatus: etaStatus ?? this.etaStatus,
      trafficMultiplier: trafficMultiplier ?? this.trafficMultiplier,
      etaLastUpdated: etaLastUpdated ?? this.etaLastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Trip(id: $id, tripId: $tripId, status: $status, type: $type)';
  }
}
