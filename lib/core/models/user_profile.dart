import 'user_role.dart';

/// User Profile Response Model
/// Represents the complete user profile data returned from /api/v1/users/profile/
class UserProfileResponse {
  final bool success;
  final UserProfile user;
  final UserPermissions permissions;

  const UserProfileResponse({
    required this.success,
    required this.user,
    required this.permissions,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] as bool,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      permissions: UserPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user.toJson(),
      'permissions': permissions.toJson(),
    };
  }
}

/// User Profile Model
/// Contains detailed user information
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final String userTypeDisplay;
  final String status;
  final String statusDisplay;
  final String? phoneNumber;
  final String? profilePicture;
  final String address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final bool isVerified;
  final String? verificationDate;
  final String? lastLoginIp;
  final String displayName;
  final Map<String, dynamic>? profile;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.userTypeDisplay,
    required this.status,
    required this.statusDisplay,
    this.phoneNumber,
    this.profilePicture,
    required this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    required this.isVerified,
    this.verificationDate,
    this.lastLoginIp,
    required this.displayName,
    this.profile,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      userType: json['user_type'] as String,
      userTypeDisplay: json['user_type_display'] as String,
      status: json['status'] as String,
      statusDisplay: json['status_display'] as String,
      phoneNumber: json['phone_number'] as String?,
      profilePicture: json['profile_picture'] as String?,
      address: json['address'] as String,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelationship:
          json['emergency_contact_relationship'] as String?,
      isVerified: json['is_verified'] as bool,
      verificationDate: json['verification_date'] as String?,
      lastLoginIp: json['last_login_ip'] as String?,
      displayName: json['display_name'] as String,
      profile: json['profile'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'user_type_display': userTypeDisplay,
      'status': status,
      'status_display': statusDisplay,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'address': address,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'is_verified': isVerified,
      'verification_date': verificationDate,
      'last_login_ip': lastLoginIp,
      'display_name': displayName,
      'profile': profile,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get user role enum
  UserRole get role => UserRole.fromString(userType);

  /// Check if user is active
  bool get isActive => status.toLowerCase() == 'active';

  /// Check if user has profile picture
  bool get hasProfilePicture =>
      profilePicture != null && profilePicture!.isNotEmpty;

  /// Check if user has emergency contact
  bool get hasEmergencyContact =>
      emergencyContactName != null && emergencyContactPhone != null;

  /// Get full name
  String get fullName => '$firstName $lastName';
}

/// User Permissions Model
/// Contains user permission flags
class UserPermissions {
  final bool canAccessAdminPanel;
  final bool canManageFleet;
  final bool canManageRoutes;
  final bool canTrackVehicles;
  final bool canManageStudents;
  final bool canManagePayments;
  final bool canViewReports;
  final bool canManageUsers;
  final bool canManageSystemSettings;

  const UserPermissions({
    required this.canAccessAdminPanel,
    required this.canManageFleet,
    required this.canManageRoutes,
    required this.canTrackVehicles,
    required this.canManageStudents,
    required this.canManagePayments,
    required this.canViewReports,
    required this.canManageUsers,
    required this.canManageSystemSettings,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      canAccessAdminPanel: json['can_access_admin_panel'] as bool,
      canManageFleet: json['can_manage_fleet'] as bool,
      canManageRoutes: json['can_manage_routes'] as bool,
      canTrackVehicles: json['can_track_vehicles'] as bool,
      canManageStudents: json['can_manage_students'] as bool,
      canManagePayments: json['can_manage_payments'] as bool,
      canViewReports: json['can_view_reports'] as bool,
      canManageUsers: json['can_manage_users'] as bool,
      canManageSystemSettings: json['can_manage_system_settings'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_access_admin_panel': canAccessAdminPanel,
      'can_manage_fleet': canManageFleet,
      'can_manage_routes': canManageRoutes,
      'can_track_vehicles': canTrackVehicles,
      'can_manage_students': canManageStudents,
      'can_manage_payments': canManagePayments,
      'can_view_reports': canViewReports,
      'can_manage_users': canManageUsers,
      'can_manage_system_settings': canManageSystemSettings,
    };
  }

  /// Check if user has any admin permissions
  bool get hasAdminPermissions =>
      canAccessAdminPanel ||
      canManageFleet ||
      canManageRoutes ||
      canManageStudents ||
      canManagePayments ||
      canManageUsers ||
      canManageSystemSettings;

  /// Check if user has driver permissions
  bool get hasDriverPermissions => canTrackVehicles || canManageFleet;

  /// Check if user has reporting permissions
  bool get hasReportingPermissions => canViewReports || canAccessAdminPanel;
}
