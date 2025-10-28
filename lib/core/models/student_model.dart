enum StudentStatus {
  waiting,
  onBus,
  pickedUp,
  droppedOff,
  absent;

  String get displayName {
    switch (this) {
      case StudentStatus.waiting:
        return 'Waiting';
      case StudentStatus.onBus:
        return 'On Bus';
      case StudentStatus.pickedUp:
        return 'Picked Up';
      case StudentStatus.droppedOff:
        return 'Dropped Off';
      case StudentStatus.absent:
        return 'Absent';
    }
  }

  String get apiValue {
    switch (this) {
      case StudentStatus.waiting:
        return 'waiting';
      case StudentStatus.onBus:
        return 'on_bus';
      case StudentStatus.pickedUp:
        return 'picked_up';
      case StudentStatus.droppedOff:
        return 'dropped_off';
      case StudentStatus.absent:
        return 'absent';
    }
  }

  @override
  String toString() => apiValue;
}

class Student {
  final int id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String grade;
  final String status;
  final String approvalStatus;
  final int age;
  final String phoneNumber;
  final String email;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String schoolName;
  final String schoolAddress;
  final int? assignedRoute;
  final int? pickupStop;
  final int? dropoffStop;
  final bool hasRouteAssignment;
  final String? routeName;
  final String? routeDescription;
  final String? routeType;
  final String? routeStatus;
  final String? assignedDriverName;
  final String? assignedVehicleLicense;
  final String? pickupStopName;
  final String? pickupStopAddress;
  final CurrentTrip? currentTrip;
  final List<dynamic> upcomingTrips;
  final List<ParentInfo> parents;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional properties that were missing
  final String? profileImage;
  final String? school;
  final DateTime? lastSeen;
  final String? parentName;
  final double? latitude;
  final double? longitude;

  const Student({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.grade,
    required this.status,
    required this.approvalStatus,
    required this.age,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.schoolName,
    required this.schoolAddress,
    this.assignedRoute,
    this.pickupStop,
    this.dropoffStop,
    required this.hasRouteAssignment,
    this.routeName,
    this.routeDescription,
    this.routeType,
    this.routeStatus,
    this.assignedDriverName,
    this.assignedVehicleLicense,
    this.pickupStopName,
    this.pickupStopAddress,
    this.currentTrip,
    required this.upcomingTrips,
    required this.parents,
    required this.createdAt,
    required this.updatedAt,
    this.profileImage,
    this.school,
    this.lastSeen,
    this.parentName,
    this.latitude,
    this.longitude,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      fullName: json['full_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      grade: json['grade'] ?? '',
      status: json['status'] ?? '',
      approvalStatus: json['approval_status'] ?? '',
      age: json['age'] ?? 0,
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      country: json['country'] ?? '',
      schoolName: json['school_name'] ?? '',
      schoolAddress: json['school_address'] ?? '',
      assignedRoute: json['assigned_route'],
      pickupStop: json['pickup_stop'],
      dropoffStop: json['dropoff_stop'],
      hasRouteAssignment: json['has_route_assignment'] ?? false,
      routeName: json['route_name'],
      routeDescription: json['route_description'],
      routeType: json['route_type'],
      routeStatus: json['route_status'],
      assignedDriverName: json['assigned_driver_name'],
      assignedVehicleLicense: json['assigned_vehicle_license'],
      pickupStopName: json['pickup_stop_name'],
      pickupStopAddress: json['pickup_stop_address'],
      currentTrip: json['current_trip'] != null
          ? CurrentTrip.fromJson(json['current_trip'])
          : null,
      upcomingTrips: json['upcoming_trips'] ?? [],
      parents:
          (json['parents'] as List<dynamic>?)
              ?.map(
                (parent) => ParentInfo.fromJson(parent as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      profileImage: json['profile_image'],
      school: json['school'],
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      parentName: json['parent_name'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'grade': grade,
      'status': status,
      'approval_status': approvalStatus,
      'age': age,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'school_name': schoolName,
      'school_address': schoolAddress,
      'assigned_route': assignedRoute,
      'pickup_stop': pickupStop,
      'dropoff_stop': dropoffStop,
      'has_route_assignment': hasRouteAssignment,
      'route_name': routeName,
      'route_description': routeDescription,
      'route_type': routeType,
      'route_status': routeStatus,
      'assigned_driver_name': assignedDriverName,
      'assigned_vehicle_license': assignedVehicleLicense,
      'pickup_stop_name': pickupStopName,
      'pickup_stop_address': pickupStopAddress,
      'current_trip': currentTrip?.toJson(),
      'upcoming_trips': upcomingTrips,
      'parents': parents.map((parent) => parent.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_image': profileImage,
      'school': school,
      'last_seen': lastSeen?.toIso8601String(),
      'parent_name': parentName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Student(id: $id, name: $fullName, grade: $grade)';
  }

  Student copyWith({
    int? id,
    String? studentId,
    String? firstName,
    String? lastName,
    String? middleName,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? grade,
    String? status,
    String? approvalStatus,
    int? age,
    String? phoneNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? schoolName,
    String? schoolAddress,
    int? assignedRoute,
    int? pickupStop,
    int? dropoffStop,
    bool? hasRouteAssignment,
    String? routeName,
    String? routeDescription,
    String? routeType,
    String? routeStatus,
    String? assignedDriverName,
    String? assignedVehicleLicense,
    String? pickupStopName,
    String? pickupStopAddress,
    CurrentTrip? currentTrip,
    List<dynamic>? upcomingTrips,
    List<ParentInfo>? parents,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImage,
    String? school,
    DateTime? lastSeen,
    String? parentName,
    double? latitude,
    double? longitude,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      schoolName: schoolName ?? this.schoolName,
      schoolAddress: schoolAddress ?? this.schoolAddress,
      assignedRoute: assignedRoute ?? this.assignedRoute,
      pickupStop: pickupStop ?? this.pickupStop,
      dropoffStop: dropoffStop ?? this.dropoffStop,
      hasRouteAssignment: hasRouteAssignment ?? this.hasRouteAssignment,
      routeName: routeName ?? this.routeName,
      routeDescription: routeDescription ?? this.routeDescription,
      routeType: routeType ?? this.routeType,
      routeStatus: routeStatus ?? this.routeStatus,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedVehicleLicense:
          assignedVehicleLicense ?? this.assignedVehicleLicense,
      pickupStopName: pickupStopName ?? this.pickupStopName,
      pickupStopAddress: pickupStopAddress ?? this.pickupStopAddress,
      currentTrip: currentTrip ?? this.currentTrip,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      parents: parents ?? this.parents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImage: profileImage ?? this.profileImage,
      school: school ?? this.school,
      lastSeen: lastSeen ?? this.lastSeen,
      parentName: parentName ?? this.parentName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Helper getters for parent contact information
  String? get parentPhone {
    // For now, return the student's phone number as parent contact
    // In a real implementation, you might want to get the actual parent's phone
    return phoneNumber.isNotEmpty ? phoneNumber : null;
  }

  String? get parentEmail {
    // For now, return the student's email as parent contact
    // In a real implementation, you might want to get the actual parent's email
    return email.isNotEmpty ? email : null;
  }

  int get parentId {
    // For now, return the student's ID as parent ID
    // In a real implementation, you might want to get the actual parent's ID
    return id;
  }
}

class CurrentTrip {
  final String tripId;
  final String tripType;
  final String status;
  final String scheduledStart;
  final String scheduledEnd;
  final String actualStart;
  final String actualEnd;
  final String driverName;
  final String vehicleLicense;

  const CurrentTrip({
    required this.tripId,
    required this.tripType,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.actualStart,
    required this.actualEnd,
    required this.driverName,
    required this.vehicleLicense,
  });

  factory CurrentTrip.fromJson(Map<String, dynamic> json) {
    return CurrentTrip(
      tripId: json['trip_id'] ?? '',
      tripType: json['trip_type'] ?? '',
      status: json['status'] ?? '',
      scheduledStart: json['scheduled_start'] ?? '',
      scheduledEnd: json['scheduled_end'] ?? '',
      actualStart: json['actual_start'] ?? '',
      actualEnd: json['actual_end'] ?? '',
      driverName: json['driver_name'] ?? '',
      vehicleLicense: json['vehicle_license'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'trip_type': tripType,
      'status': status,
      'scheduled_start': scheduledStart,
      'scheduled_end': scheduledEnd,
      'actual_start': actualStart,
      'actual_end': actualEnd,
      'driver_name': driverName,
      'vehicle_license': vehicleLicense,
    };
  }
}

class ParentInfo {
  final int id;
  final int student;
  final int parent;
  final String studentName;
  final String parentName;
  final bool isPrimaryContact;
  final bool canPickup;
  final bool canDropoff;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParentInfo({
    required this.id,
    required this.student,
    required this.parent,
    required this.studentName,
    required this.parentName,
    required this.isPrimaryContact,
    required this.canPickup,
    required this.canDropoff,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentInfo.fromJson(Map<String, dynamic> json) {
    return ParentInfo(
      id: json['id'] ?? 0,
      student: json['student'] ?? 0,
      parent: json['parent'] ?? 0,
      studentName: json['student_name'] ?? '',
      parentName: json['parent_name'] ?? '',
      isPrimaryContact: json['is_primary_contact'] ?? false,
      canPickup: json['can_pickup'] ?? false,
      canDropoff: json['can_dropoff'] ?? false,
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
      'student': student,
      'parent': parent,
      'student_name': studentName,
      'parent_name': parentName,
      'is_primary_contact': isPrimaryContact,
      'can_pickup': canPickup,
      'can_dropoff': canDropoff,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
