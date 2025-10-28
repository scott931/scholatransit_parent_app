import 'package:flutter/material.dart';

enum AttendanceStatus { present, absent, late, earlyPickup, noShow, cancelled }

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.earlyPickup:
        return 'Early Pickup';
      case AttendanceStatus.noShow:
        return 'No Show';
      case AttendanceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.earlyPickup:
        return Colors.blue;
      case AttendanceStatus.noShow:
        return Colors.red;
      case AttendanceStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.earlyPickup:
        return Icons.schedule;
      case AttendanceStatus.noShow:
        return Icons.person_off;
      case AttendanceStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class AttendanceRecord {
  final int id;
  final int tripId;
  final String tripIdString;
  final int studentId;
  final String studentName;
  final String studentIdString;
  final DateTime tripDate;
  final DateTime scheduledPickupTime;
  final DateTime? actualPickupTime;
  final DateTime scheduledDropoffTime;
  final DateTime? actualDropoffTime;
  final AttendanceStatus status;
  final String? notes;
  final String? delayReason;
  final String routeName;
  final String driverName;
  final String vehicleInfo;
  final String pickupLocation;
  final String dropoffLocation;
  final double? distance;
  final int? duration; // in minutes
  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.tripId,
    required this.tripIdString,
    required this.studentId,
    required this.studentName,
    required this.studentIdString,
    required this.tripDate,
    required this.scheduledPickupTime,
    this.actualPickupTime,
    required this.scheduledDropoffTime,
    this.actualDropoffTime,
    required this.status,
    this.notes,
    this.delayReason,
    required this.routeName,
    required this.driverName,
    required this.vehicleInfo,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.distance,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      tripIdString: json['trip_id_string'] ?? '',
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'] ?? '',
      studentIdString: json['student_id_string'] ?? '',
      tripDate: DateTime.parse(json['trip_date']),
      scheduledPickupTime: DateTime.parse(json['scheduled_pickup_time']),
      actualPickupTime: json['actual_pickup_time'] != null
          ? DateTime.parse(json['actual_pickup_time'])
          : null,
      scheduledDropoffTime: DateTime.parse(json['scheduled_dropoff_time']),
      actualDropoffTime: json['actual_dropoff_time'] != null
          ? DateTime.parse(json['actual_dropoff_time'])
          : null,
      status: _parseAttendanceStatus(json['status']),
      notes: json['notes'],
      delayReason: json['delay_reason'],
      routeName: json['route_name'] ?? '',
      driverName: json['driver_name'] ?? '',
      vehicleInfo: json['vehicle_info'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      dropoffLocation: json['dropoff_location'] ?? '',
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'trip_id_string': tripIdString,
      'student_id': studentId,
      'student_name': studentName,
      'student_id_string': studentIdString,
      'trip_date': tripDate.toIso8601String(),
      'scheduled_pickup_time': scheduledPickupTime.toIso8601String(),
      'actual_pickup_time': actualPickupTime?.toIso8601String(),
      'scheduled_dropoff_time': scheduledDropoffTime.toIso8601String(),
      'actual_dropoff_time': actualDropoffTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'delay_reason': delayReason,
      'route_name': routeName,
      'driver_name': driverName,
      'vehicle_info': vehicleInfo,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'distance': distance,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static AttendanceStatus _parseAttendanceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'early_pickup':
        return AttendanceStatus.earlyPickup;
      case 'no_show':
        return AttendanceStatus.noShow;
      case 'cancelled':
        return AttendanceStatus.cancelled;
      default:
        return AttendanceStatus.absent;
    }
  }

  // Helper methods
  bool get isOnTime {
    if (actualPickupTime == null) return false;
    final difference = actualPickupTime!.difference(scheduledPickupTime);
    return difference.inMinutes.abs() <=
        5; // Within 5 minutes is considered on time
  }

  bool get isLate {
    if (actualPickupTime == null) return false;
    final difference = actualPickupTime!.difference(scheduledPickupTime);
    return difference.inMinutes > 5;
  }

  Duration? get delayDuration {
    if (actualPickupTime == null) return null;
    return actualPickupTime!.difference(scheduledPickupTime);
  }

  String get delayDisplayText {
    if (delayDuration == null) return '';
    final minutes = delayDuration!.inMinutes;
    if (minutes == 0) return 'On time';
    if (minutes > 0) return '${minutes}m late';
    return '${minutes.abs()}m early';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, student: $studentName, date: $tripDate, status: ${status.displayName})';
  }
}

class AttendanceSummary {
  final int totalTrips;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int earlyPickupCount;
  final int noShowCount;
  final int cancelledCount;
  final double attendanceRate;
  final double punctualityRate;
  final DateTime? firstTripDate;
  final DateTime? lastTripDate;

  const AttendanceSummary({
    required this.totalTrips,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.earlyPickupCount,
    required this.noShowCount,
    required this.cancelledCount,
    required this.attendanceRate,
    required this.punctualityRate,
    this.firstTripDate,
    this.lastTripDate,
  });

  factory AttendanceSummary.fromRecords(List<AttendanceRecord> records) {
    if (records.isEmpty) {
      return const AttendanceSummary(
        totalTrips: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
        earlyPickupCount: 0,
        noShowCount: 0,
        cancelledCount: 0,
        attendanceRate: 0.0,
        punctualityRate: 0.0,
      );
    }

    final totalTrips = records.length;
    final presentCount = records
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final absentCount = records
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    final lateCount = records
        .where((r) => r.status == AttendanceStatus.late)
        .length;
    final earlyPickupCount = records
        .where((r) => r.status == AttendanceStatus.earlyPickup)
        .length;
    final noShowCount = records
        .where((r) => r.status == AttendanceStatus.noShow)
        .length;
    final cancelledCount = records
        .where((r) => r.status == AttendanceStatus.cancelled)
        .length;

    final attendanceRate = totalTrips > 0
        ? (presentCount / totalTrips) * 100
        : 0.0;
    final onTimeCount = records.where((r) => r.isOnTime).length;
    final punctualityRate = totalTrips > 0
        ? (onTimeCount / totalTrips) * 100
        : 0.0;

    final dates = records.map((r) => r.tripDate).toList()..sort();
    final firstTripDate = dates.isNotEmpty ? dates.first : null;
    final lastTripDate = dates.isNotEmpty ? dates.last : null;

    return AttendanceSummary(
      totalTrips: totalTrips,
      presentCount: presentCount,
      absentCount: absentCount,
      lateCount: lateCount,
      earlyPickupCount: earlyPickupCount,
      noShowCount: noShowCount,
      cancelledCount: cancelledCount,
      attendanceRate: attendanceRate,
      punctualityRate: punctualityRate,
      firstTripDate: firstTripDate,
      lastTripDate: lastTripDate,
    );
  }
}
