import '../services/user_profile_service.dart';

/// Example usage of User Profile API
/// This file demonstrates how to use the user profile service
class UserProfileUsageExample {
  /// Example: Get complete user profile
  static Future<void> getCompleteUserProfile() async {
    print('🔍 Fetching user profile...');

    final response = await UserProfileService.getUserProfile();

    if (response.success && response.data != null) {
      final profile = response.data!;

      print('✅ User Profile Retrieved:');
      print('   Name: ${profile.user.displayName}');
      print('   Email: ${profile.user.email}');
      print('   Role: ${profile.user.userTypeDisplay}');
      print('   Status: ${profile.user.statusDisplay}');
      print('   Verified: ${profile.user.isVerified}');

      // Check permissions
      print('📋 Permissions:');
      print('   Can Track Vehicles: ${profile.permissions.canTrackVehicles}');
      print('   Can Manage Fleet: ${profile.permissions.canManageFleet}');
      print(
        '   Can Access Admin Panel: ${profile.permissions.canAccessAdminPanel}',
      );
    } else {
      print('❌ Failed to fetch profile: ${response.error}');
    }
  }

  /// Example: Check specific permissions
  static Future<void> checkUserPermissions() async {
    print('🔐 Checking user permissions...');

    // Check individual permissions
    final canTrackVehicles = await UserProfileService.hasPermission(
      'track_vehicles',
    );
    final canManageFleet = await UserProfileService.hasPermission(
      'manage_fleet',
    );
    final isAdmin = await UserProfileService.isAdmin();
    final isDriver = await UserProfileService.isDriver();

    print('📊 Permission Results:');
    print('   Can Track Vehicles: $canTrackVehicles');
    print('   Can Manage Fleet: $canManageFleet');
    print('   Is Admin: $isAdmin');
    print('   Is Driver: $isDriver');
  }

  /// Example: Get user information safely
  static Future<void> getSafeUserInfo() async {
    print('👤 Getting user information safely...');

    final displayName = await UserProfileService.getUserDisplayName();
    final userRole = await UserProfileService.getUserRole();
    final isVerified = await UserProfileService.isUserVerified();
    final emergencyContact = await UserProfileService.getEmergencyContact();

    print('📝 User Information:');
    print('   Display Name: ${displayName ?? 'Unknown'}');
    print('   Role: ${userRole ?? 'Unknown'}');
    print('   Verified: $isVerified');

    if (emergencyContact['name'] != null) {
      print('🚨 Emergency Contact:');
      print('   Name: ${emergencyContact['name']}');
      print('   Phone: ${emergencyContact['phone']}');
      print('   Relationship: ${emergencyContact['relationship']}');
    } else {
      print('🚨 No emergency contact information available');
    }
  }

  /// Example: Handle profile fetch with error handling
  static Future<void> handleProfileFetchWithErrors() async {
    print('🛡️ Handling profile fetch with error handling...');

    try {
      final profile = await UserProfileService.getUserProfileSafe();

      if (profile != null) {
        print('✅ Profile loaded successfully');
        print('   User: ${profile.user.displayName}');
        print(
          '   Has Admin Permissions: ${profile.permissions.hasAdminPermissions}',
        );
        print(
          '   Has Driver Permissions: ${profile.permissions.hasDriverPermissions}',
        );
        print(
          '   Has Reporting Permissions: ${profile.permissions.hasReportingPermissions}',
        );
      } else {
        print('❌ Profile could not be loaded');
      }
    } catch (e) {
      print('💥 Error occurred: $e');
    }
  }

  /// Example: Complete workflow
  static Future<void> runCompleteExample() async {
    print('🚀 Running complete user profile example...\n');

    await getCompleteUserProfile();
    print('');

    await checkUserPermissions();
    print('');

    await getSafeUserInfo();
    print('');

    await handleProfileFetchWithErrors();
    print('');

    print('✅ Complete example finished!');
  }
}
