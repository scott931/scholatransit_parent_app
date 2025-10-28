enum TripStatus { scheduled, inProgress, completed, cancelled }

class Trip {
  final String id;
  final String routeId;
  final String driverId;
  final String vehicleId;
  final String name;
  final String description;
  final TripStatus status;
  final DateTime scheduledStartTime;
  final DateTime? actualStartTime;
  final DateTime? scheduledEndTime;
  final DateTime? actualEndTime;
  final String startLocation;
  final String endLocation;
  final List<String> studentIds;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.vehicleId,
    required this.name,
    required this.description,
    required this.status,
    required this.scheduledStartTime,
    this.actualStartTime,
    this.scheduledEndTime,
    this.actualEndTime,
    required this.startLocation,
    required this.endLocation,
    required this.studentIds,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == TripStatus.inProgress;
  bool get isCompleted => status == TripStatus.completed;
  bool get isScheduled => status == TripStatus.scheduled;
  bool get isCancelled => status == TripStatus.cancelled;

  Duration? get duration {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!);
    }
    return null;
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      routeId: json['route_id'] ?? '',
      driverId: json['driver_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.scheduled,
      ),
      scheduledStartTime: DateTime.parse(
        json['scheduled_start_time'] ?? DateTime.now().toIso8601String(),
      ),
      actualStartTime: json['actual_start_time'] != null
          ? DateTime.parse(json['actual_start_time'])
          : null,
      scheduledEndTime: json['scheduled_end_time'] != null
          ? DateTime.parse(json['scheduled_end_time'])
          : null,
      actualEndTime: json['actual_end_time'] != null
          ? DateTime.parse(json['actual_end_time'])
          : null,
      startLocation: json['start_location'] ?? '',
      endLocation: json['end_location'] ?? '',
      studentIds: List<String>.from(json['student_ids'] ?? []),
      metadata: json['metadata'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_id': routeId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'name': name,
      'description': description,
      'status': status.name,
      'scheduled_start_time': scheduledStartTime.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'scheduled_end_time': scheduledEndTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'start_location': startLocation,
      'end_location': endLocation,
      'student_ids': studentIds,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Trip copyWith({
    String? id,
    String? routeId,
    String? driverId,
    String? vehicleId,
    String? name,
    String? description,
    TripStatus? status,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? scheduledEndTime,
    DateTime? actualEndTime,
    String? startLocation,
    String? endLocation,
    List<String>? studentIds,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      studentIds: studentIds ?? this.studentIds,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
