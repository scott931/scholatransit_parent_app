import '../config/api_endpoints.dart';
import '../models/user_profile.dart';
import 'api_service.dart';

/// User Profile Service
/// Handles user profile related API operations
class UserProfileService {
  /// Get user profile information
  /// Returns complete user profile with permissions
  static Future<ApiResponse<UserProfileResponse>> getUserProfile() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
      );

      if (response.success && response.data != null) {
        final userProfileResponse = UserProfileResponse.fromJson(
          response.data!,
        );
        return ApiResponse<UserProfileResponse>.success(userProfileResponse);
      } else {
        return ApiResponse<UserProfileResponse>.error(
          response.error ?? 'Failed to fetch user profile',
        );
      }
    } catch (e) {
      return ApiResponse<UserProfileResponse>.error(
        'Error fetching user profile: $e',
      );
    }
  }

  /// Get user profile with error handling
  /// Returns null if profile fetch fails
  static Future<UserProfileResponse?> getUserProfileSafe() async {
    final response = await getUserProfile();
    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
  }

  /// Check if user has specific permission
  static Future<bool> hasPermission(String permission) async {
    final profile = await getUserProfileSafe();
    if (profile == null) return false;

    switch (permission.toLowerCase()) {
      case 'admin_panel':
        return profile.permissions.canAccessAdminPanel;
      case 'manage_fleet':
        return profile.permissions.canManageFleet;
      case 'manage_routes':
        return profile.permissions.canManageRoutes;
      case 'track_vehicles':
        return profile.permissions.canTrackVehicles;
      case 'manage_students':
        return profile.permissions.canManageStudents;
      case 'manage_payments':
        return profile.permissions.canManagePayments;
      case 'view_reports':
        return profile.permissions.canViewReports;
      case 'manage_users':
        return profile.permissions.canManageUsers;
      case 'system_settings':
        return profile.permissions.canManageSystemSettings;
      default:
        return false;
    }
  }

  /// Check if user is admin
  static Future<bool> isAdmin() async {
    final profile = await getUserProfileSafe();
    return profile?.permissions.hasAdminPermissions ?? false;
  }

  /// Check if user is driver
  static Future<bool> isDriver() async {
    final profile = await getUserProfileSafe();
    return profile?.permissions.hasDriverPermissions ?? false;
  }

  /// Get user display name
  static Future<String?> getUserDisplayName() async {
    final profile = await getUserProfileSafe();
    return profile?.user.displayName;
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    final profile = await getUserProfileSafe();
    return profile?.user.userType;
  }

  /// Check if user is verified
  static Future<bool> isUserVerified() async {
    final profile = await getUserProfileSafe();
    return profile?.user.isVerified ?? false;
  }

  /// Get user emergency contact information
  static Future<Map<String, String?>> getEmergencyContact() async {
    final profile = await getUserProfileSafe();
    if (profile == null) {
      return {'name': null, 'phone': null, 'relationship': null};
    }

    return {
      'name': profile.user.emergencyContactName,
      'phone': profile.user.emergencyContactPhone,
      'relationship': profile.user.emergencyContactRelationship,
    };
  }
}
