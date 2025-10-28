import 'storage_service.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';

/// Authentication Token Fix Service
/// Fixes authentication token storage and retrieval issues
class AuthTokenFix {
  /// Comprehensive authentication token diagnosis
  static Future<Map<String, dynamic>> diagnoseAuthTokens() async {
    print('🔍 AUTHENTICATION TOKEN DIAGNOSIS');
    print('=================================');

    // Check all possible token storage locations
    final authToken = StorageService.getAuthToken();
    final refreshToken = StorageService.getRefreshToken();
    final parentId = StorageService.getInt('parent_id');
    final userProfile = StorageService.getUserProfile();

    // Check alternative storage keys
    final altAuthToken = StorageService.getString('auth_token');
    final altRefreshToken = StorageService.getString('refresh_token');
    final altAccessToken = StorageService.getString('access_token');

    print('📱 Primary Token Check:');
    print('   - Auth Token: ${authToken != null ? '✅ Found' : '❌ Missing'}');
    print(
      '   - Refresh Token: ${refreshToken != null ? '✅ Found' : '❌ Missing'}',
    );
    print('   - Parent ID: ${parentId != null ? '✅ Found' : '❌ Missing'}');
    print(
      '   - User Profile: ${userProfile != null ? '✅ Found' : '❌ Missing'}',
    );

    print('📱 Alternative Token Check:');
    print(
      '   - Alt Auth Token: ${altAuthToken != null ? '✅ Found' : '❌ Missing'}',
    );
    print(
      '   - Alt Refresh Token: ${altRefreshToken != null ? '✅ Found' : '❌ Missing'}',
    );
    print(
      '   - Alt Access Token: ${altAccessToken != null ? '✅ Found' : '❌ Missing'}',
    );

    if (authToken != null) {
      print('🔍 Auth Token Details:');
      print('   - Length: ${authToken.length}');
      print('   - Preview: ${authToken.substring(0, 20)}...');
      print('   - Format: ${authToken.startsWith('eyJ') ? 'JWT' : 'Other'}');
    }

    if (refreshToken != null) {
      print('🔍 Refresh Token Details:');
      print('   - Length: ${refreshToken.length}');
      print('   - Preview: ${refreshToken.substring(0, 20)}...');
    }

    return {
      'hasAuthToken': authToken != null && authToken.isNotEmpty,
      'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
      'hasParentId': parentId != null,
      'hasUserProfile': userProfile != null,
      'hasAltTokens':
          altAuthToken != null ||
          altRefreshToken != null ||
          altAccessToken != null,
      'authTokenLength': authToken?.length ?? 0,
      'refreshTokenLength': refreshToken?.length ?? 0,
      'parentId': parentId,
    };
  }

  /// Fix authentication tokens by consolidating from all sources
  static Future<bool> fixAuthTokens() async {
    print('🔧 FIXING AUTHENTICATION TOKENS');
    print('===============================');

    try {
      // Get tokens from all possible sources
      final authToken = StorageService.getAuthToken();
      final refreshToken = StorageService.getRefreshToken();
      final altAuthToken = StorageService.getString('auth_token');
      final altRefreshToken = StorageService.getString('refresh_token');
      final altAccessToken = StorageService.getString('access_token');

      String? finalAuthToken;
      String? finalRefreshToken;

      // Consolidate auth token
      if (authToken != null && authToken.isNotEmpty) {
        finalAuthToken = authToken;
        print('✅ Using primary auth token');
      } else if (altAuthToken != null && altAuthToken.isNotEmpty) {
        finalAuthToken = altAuthToken;
        print('✅ Using alternative auth token');
      } else if (altAccessToken != null && altAccessToken.isNotEmpty) {
        finalAuthToken = altAccessToken;
        print('✅ Using access token as auth token');
      } else {
        print('❌ No auth token found in any location');
        return false;
      }

      // Consolidate refresh token
      if (refreshToken != null && refreshToken.isNotEmpty) {
        finalRefreshToken = refreshToken;
        print('✅ Using primary refresh token');
      } else if (altRefreshToken != null && altRefreshToken.isNotEmpty) {
        finalRefreshToken = altRefreshToken;
        print('✅ Using alternative refresh token');
      } else {
        print('⚠️ No refresh token found');
      }

      // Save consolidated tokens
      await StorageService.saveAuthToken(finalAuthToken);
      print('✅ Auth token saved to primary location');

      if (finalRefreshToken != null) {
        await StorageService.saveRefreshToken(finalRefreshToken);
        print('✅ Refresh token saved to primary location');
      }

      // Test the fixed tokens
      final testResult = await testFixedTokens();
      if (testResult) {
        print('✅ Authentication tokens fixed and working!');
        return true;
      } else {
        print('❌ Tokens found but API calls still failing');
        return false;
      }
    } catch (e) {
      print('💥 Error fixing auth tokens: $e');
      return false;
    }
  }

  /// Test the fixed authentication tokens
  static Future<bool> testFixedTokens() async {
    print('🧪 TESTING FIXED AUTHENTICATION TOKENS');
    print('======================================');

    try {
      final authToken = StorageService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        print('❌ No auth token available for testing');
        return false;
      }

      print('✅ Auth token found, testing API call...');

      // Test with profile endpoint
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
      );

      print('📡 API Test Results:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Error: ${response.error}');

      if (response.success) {
        print('✅ Authentication tokens are working!');
        return true;
      } else {
        print('❌ Authentication tokens are not working');
        if (response.error?.contains('401') == true) {
          print('🔍 Token is invalid or expired');
        }
        return false;
      }
    } catch (e) {
      print('💥 Error testing tokens: $e');
      return false;
    }
  }

  /// Force re-authentication by clearing all tokens
  static Future<void> forceReAuthentication() async {
    print('🔄 FORCING RE-AUTHENTICATION');
    print('============================');

    try {
      // Clear all possible token locations
      await StorageService.clearAuthTokens();
      await StorageService.clearUserProfile();
      await StorageService.clearDriverId();

      // Clear alternative token locations
      await StorageService.remove('auth_token');
      await StorageService.remove('refresh_token');
      await StorageService.remove('access_token');

      print('✅ All authentication data cleared');
      print('💡 User needs to login again');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  /// Complete authentication fix workflow
  static Future<bool> completeAuthFix() async {
    print('🚀 COMPLETE AUTHENTICATION FIX');
    print('==============================');

    // Step 1: Diagnose the issue
    final diagnosis = await diagnoseAuthTokens();

    // Step 2: Try to fix tokens
    if (diagnosis['hasAltTokens'] == true) {
      print('🔧 Found tokens in alternative locations, consolidating...');
      final fixResult = await fixAuthTokens();
      if (fixResult) {
        print('✅ Authentication fixed successfully!');
        return true;
      }
    }

    // Step 3: If fix failed, force re-authentication
    print('❌ Could not fix authentication automatically');
    print('💡 User needs to login again');
    await forceReAuthentication();
    return false;
  }

  /// Enhanced authentication fix with storage validation
  static Future<Map<String, dynamic>> enhancedAuthFix() async {
    print('🔧 ENHANCED AUTHENTICATION FIX');
    print('==============================');

    final result = <String, dynamic>{
      'success': false,
      'steps': <String>[],
      'errors': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Step 1: Validate storage service
      (result['steps'] as List<String>).add('Validating storage service...');
      final storageTest = await StorageService.testStorage();
      if (!storageTest) {
        (result['errors'] as List<String>).add(
          'Storage service is not working properly',
        );
        (result['recommendations'] as List<String>).add(
          'Restart the application',
        );
        return result;
      }
      (result['steps'] as List<String>).add('✅ Storage service validated');

      // Step 2: Check current token status
      (result['steps'] as List<String>).add('Checking current token status...');
      final diagnosis = await diagnoseAuthTokens();

      if (diagnosis['hasAuthToken'] == true) {
        (result['steps'] as List<String>).add('✅ Auth token found');

        // Step 3: Test current token
        (result['steps'] as List<String>).add('Testing current token...');
        final testResult = await testFixedTokens();
        if (testResult) {
          (result['steps'] as List<String>).add('✅ Current token is working');
          result['success'] = true;
          return result;
        } else {
          (result['steps'] as List<String>).add(
            '❌ Current token is not working',
          );
        }
      } else {
        (result['steps'] as List<String>).add('❌ No auth token found');
      }

      // Step 4: Try to fix tokens
      if (diagnosis['hasAltTokens'] == true) {
        (result['steps'] as List<String>).add(
          'Attempting to fix tokens from alternative locations...',
        );
        final fixResult = await fixAuthTokens();
        if (fixResult) {
          (result['steps'] as List<String>).add('✅ Tokens fixed successfully');
          result['success'] = true;
          return result;
        } else {
          (result['steps'] as List<String>).add('❌ Token fix failed');
        }
      }

      // Step 5: If all else fails, recommend re-authentication
      (result['steps'] as List<String>).add('All fix attempts failed');
      (result['recommendations'] as List<String>).add(
        'User needs to login again',
      );
      (result['recommendations'] as List<String>).add(
        'Clear app data and restart',
      );
    } catch (e) {
      (result['errors'] as List<String>).add('Exception during fix: $e');
      (result['steps'] as List<String>).add(
        '❌ Fix process failed with exception',
      );
    }

    return result;
  }
}
