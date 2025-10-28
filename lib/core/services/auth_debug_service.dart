import 'storage_service.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';

/// Authentication Debug Service
/// Helps diagnose and fix authentication issues
class AuthDebugService {
  /// Comprehensive authentication status check
  static Map<String, dynamic> getAuthStatus() {
    final authToken = StorageService.getAuthToken();
    final refreshToken = StorageService.getRefreshToken();
    final parentId = StorageService.getInt('parent_id');
    final userProfile = StorageService.getUserProfile();

    return {
      'hasAuthToken': authToken != null && authToken.isNotEmpty,
      'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
      'hasParentId': parentId != null,
      'hasUserProfile': userProfile != null,
      'authTokenLength': authToken?.length ?? 0,
      'refreshTokenLength': refreshToken?.length ?? 0,
      'parentId': parentId,
      'authTokenPreview': authToken?.substring(0, 20) ?? 'null',
      'refreshTokenPreview': refreshToken?.substring(0, 20) ?? 'null',
    };
  }

  /// Print detailed authentication status
  static void printAuthStatus() {
    print('🔐 AUTHENTICATION STATUS CHECK:');
    print('================================');

    final status = getAuthStatus();

    print('📱 Token Status:');
    print(
      '   - Auth Token: ${status['hasAuthToken'] ? '✅ Present' : '❌ Missing'}',
    );
    print(
      '   - Refresh Token: ${status['hasRefreshToken'] ? '✅ Present' : '❌ Missing'}',
    );
    print('   - Auth Token Length: ${status['authTokenLength']}');
    print('   - Refresh Token Length: ${status['refreshTokenLength']}');

    print('👤 User Status:');
    print(
      '   - Parent ID: ${status['hasParentId'] ? '✅ ${status['parentId']}' : '❌ Missing'}',
    );
    print(
      '   - User Profile: ${status['hasUserProfile'] ? '✅ Present' : '❌ Missing'}',
    );

    print('🔍 Token Previews:');
    print('   - Auth Token: ${status['authTokenPreview']}...');
    print('   - Refresh Token: ${status['refreshTokenPreview']}...');

    // Determine the issue
    if (!status['hasAuthToken']) {
      print('🚨 ISSUE: No authentication token found!');
      print('💡 SOLUTION: User needs to complete login flow');
    } else if (!status['hasRefreshToken']) {
      print('⚠️ WARNING: No refresh token found');
      print('💡 SOLUTION: User may need to login again');
    } else {
      print('✅ Authentication tokens are present');
    }
  }

  /// Test API authentication with detailed logging
  static Future<bool> testApiAuthentication() async {
    print('🧪 TESTING API AUTHENTICATION:');
    print('==============================');

    try {
      // Test 1: Check if we have tokens
      final authToken = StorageService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        print('❌ No auth token available for testing');
        return false;
      }

      print('✅ Auth token found, testing API call...');

      // Test 2: Make a simple API call
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
      );

      print('📡 API Response:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Error: ${response.error}');

      if (response.success) {
        print('✅ API authentication is working!');
        return true;
      } else {
        print('❌ API authentication failed');

        // Check if it's a token issue
        if (response.error?.contains('401') == true ||
            response.error?.contains('Authentication') == true) {
          print('🔍 DIAGNOSIS: Token is invalid or expired');
          print('💡 SOLUTION: User needs to login again');
        }

        return false;
      }
    } catch (e) {
      print('💥 ERROR: API test failed with exception: $e');
      return false;
    }
  }

  /// Clear all authentication data
  static Future<void> clearAllAuthData() async {
    print('🧹 CLEARING ALL AUTHENTICATION DATA:');
    print('====================================');

    try {
      await StorageService.clearAuthTokens();
      await StorageService.clearUserProfile();
      await StorageService.clearDriverId();

      print('✅ All authentication data cleared');
      print('💡 User will need to login again');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  /// Force user to login by clearing data and redirecting
  static Future<void> forceReLogin() async {
    print('🔄 FORCING USER TO RE-LOGIN:');
    print('============================');

    await clearAllAuthData();
    print('✅ Authentication data cleared');
    print('💡 User should be redirected to login screen');
  }

  /// Comprehensive authentication health check
  static Future<Map<String, dynamic>> healthCheck() async {
    print('🏥 AUTHENTICATION HEALTH CHECK:');
    print('===============================');

    final status = getAuthStatus();
    final apiTest = await testApiAuthentication();

    final health = {
      'hasTokens':
          (status['hasAuthToken'] as bool) &&
          (status['hasRefreshToken'] as bool),
      'hasUserData':
          (status['hasParentId'] as bool) && (status['hasUserProfile'] as bool),
      'apiWorking': apiTest,
      'overallHealthy':
          (status['hasAuthToken'] as bool) &&
          (status['hasRefreshToken'] as bool) &&
          apiTest,
    };

    print('📊 Health Summary:');
    print('   - Has Tokens: ${(health['hasTokens'] as bool) ? '✅' : '❌'}');
    print('   - Has User Data: ${(health['hasUserData'] as bool) ? '✅' : '❌'}');
    print('   - API Working: ${(health['apiWorking'] as bool) ? '✅' : '❌'}');
    print(
      '   - Overall Healthy: ${(health['overallHealthy'] as bool) ? '✅' : '❌'}',
    );

    if (!(health['overallHealthy'] as bool)) {
      print('🚨 AUTHENTICATION ISSUES DETECTED!');
      if (!(health['hasTokens'] as bool)) {
        print('💡 Fix: User needs to complete login flow');
      } else if (!(health['apiWorking'] as bool)) {
        print('💡 Fix: Tokens may be expired, try refresh or re-login');
      }
    }

    return health;
  }
}
