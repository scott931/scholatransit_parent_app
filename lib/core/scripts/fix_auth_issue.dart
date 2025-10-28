import '../services/auth_debug_service.dart';
import '../services/storage_service.dart';

/// Authentication Fix Script
/// Run this to diagnose and fix authentication issues
class AuthFixScript {
  /// Main fix function - run this to diagnose and fix auth issues
  static Future<void> runAuthFix() async {
    print('🔧 AUTHENTICATION FIX SCRIPT');
    print('============================');
    print('');

    // Step 1: Check current status
    print('📋 STEP 1: Checking current authentication status...');
    AuthDebugService.printAuthStatus();
    print('');

    // Step 2: Test API authentication
    print('🧪 STEP 2: Testing API authentication...');
    final apiWorking = await AuthDebugService.testApiAuthentication();
    print('');

    // Step 3: Determine the issue and fix
    if (!apiWorking) {
      print('🔍 STEP 3: API authentication failed, diagnosing issue...');

      final authToken = StorageService.getAuthToken();
      final refreshToken = StorageService.getRefreshToken();

      if (authToken == null || authToken.isEmpty) {
        print('🚨 ISSUE: No authentication token found');
        print('💡 SOLUTION: User needs to complete login flow');
        print('   - Go to login screen');
        print('   - Enter email and password');
        print('   - Complete OTP verification');
        print('   - Tokens will be saved automatically');
      } else if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ ISSUE: No refresh token found');
        print('💡 SOLUTION: User needs to login again');
        print('   - Clear current auth data');
        print('   - Go to login screen');
        print('   - Complete full login flow');
      } else {
        print('🔍 ISSUE: Tokens exist but API calls are failing');
        print('💡 SOLUTION: Tokens may be expired or invalid');
        print('   - Try refreshing tokens');
        print('   - If refresh fails, user needs to login again');
      }
    } else {
      print('✅ STEP 3: API authentication is working!');
      print('🎉 No fixes needed - authentication is healthy');
    }

    print('');
    print('📝 SUMMARY:');
    print('============');

    final health = await AuthDebugService.healthCheck();

    if (health['overallHealthy']) {
      print('✅ Authentication is working correctly');
    } else {
      print('❌ Authentication issues detected');
      print('💡 Follow the solutions above to fix the issues');
    }
  }

  /// Quick fix for missing tokens
  static Future<void> quickFixMissingTokens() async {
    print('⚡ QUICK FIX: Missing Tokens');
    print('===========================');

    final authToken = StorageService.getAuthToken();
    final refreshToken = StorageService.getRefreshToken();

    if (authToken == null || authToken.isEmpty) {
      print('🚨 No auth token found');
      print('💡 User needs to login');
      print('   - Navigate to /login');
      print('   - Enter credentials');
      print('   - Complete OTP verification');
    } else if (refreshToken == null || refreshToken.isEmpty) {
      print('⚠️ No refresh token found');
      print('💡 User needs to login again');
      print('   - Clear auth data');
      print('   - Navigate to /login');
    } else {
      print('✅ Tokens are present');
      print('🔍 Testing API calls...');

      final apiWorking = await AuthDebugService.testApiAuthentication();
      if (!apiWorking) {
        print('❌ API calls failing despite having tokens');
        print('💡 Tokens may be expired - user needs to login again');
      } else {
        print('✅ API calls working - no fix needed');
      }
    }
  }

  /// Emergency reset - clears all auth data
  static Future<void> emergencyReset() async {
    print('🚨 EMERGENCY AUTHENTICATION RESET');
    print('=================================');

    await AuthDebugService.clearAllAuthData();

    print('✅ All authentication data cleared');
    print('💡 User will need to login again');
    print('   - Navigate to /login');
    print('   - Enter email and password');
    print('   - Complete OTP verification');
  }
}

/// Quick function to run the auth fix
Future<void> fixAuthIssue() async {
  await AuthFixScript.runAuthFix();
}

/// Quick function to check auth status
Future<void> checkAuthStatus() async {
  AuthDebugService.printAuthStatus();
  await AuthDebugService.testApiAuthentication();
}
