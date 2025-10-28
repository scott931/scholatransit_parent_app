import '../services/storage_service.dart';
import '../services/authentication_service.dart';
import '../services/auth_token_fix.dart';

/// Script to test and fix authentication issues
/// This can be run from anywhere in the app to diagnose and fix auth problems
class AuthFixScript {
  static Future<void> runAuthFix() async {
    print('🚀 RUNNING AUTHENTICATION FIX SCRIPT');
    print('====================================');
    print('');

    try {
      // Step 1: Initialize storage if needed
      print('📱 Step 1: Initializing storage service...');
      await StorageService.init();
      print('✅ Storage service initialized');
      print('');

      // Step 2: Check storage status
      print('📱 Step 2: Checking storage status...');
      final storageStatus = StorageService.getStorageStatus();
      print('   - Initialized: ${storageStatus['isInitialized']}');
      print('   - Auth Token: ${storageStatus['hasAuthToken']}');
      print('   - Refresh Token: ${storageStatus['hasRefreshToken']}');
      print('   - User Profile: ${storageStatus['hasUserProfile']}');
      print('');

      // Step 3: Check authentication status
      print('🔐 Step 3: Checking authentication status...');
      final authStatus = AuthenticationService.getAuthStatus();
      print('   - Has Auth Token: ${authStatus['hasAuthToken']}');
      print('   - Token Format: ${authStatus['tokenFormat']}');
      print('   - Token Length: ${authStatus['authTokenLength']}');
      print('');

      // Step 4: Test storage functionality
      print('🧪 Step 4: Testing storage functionality...');
      final storageTest = await StorageService.testStorage();
      print('   - Storage Test: ${storageTest ? '✅ Passed' : '❌ Failed'}');
      print('');

      // Step 5: Run enhanced authentication fix
      print('🔧 Step 5: Running enhanced authentication fix...');
      final fixResult = await AuthTokenFix.enhancedAuthFix();

      print('   - Success: ${fixResult['success']}');
      print('   - Steps:');
      for (final step in fixResult['steps']) {
        print('     $step');
      }

      if (fixResult['errors'].isNotEmpty) {
        print('   - Errors:');
        for (final error in fixResult['errors']) {
          print('     ❌ $error');
        }
      }

      if (fixResult['recommendations'].isNotEmpty) {
        print('   - Recommendations:');
        for (final recommendation in fixResult['recommendations']) {
          print('     💡 $recommendation');
        }
      }
      print('');

      // Step 6: Final status check
      print('📊 Step 6: Final status check...');
      final finalAuthStatus = AuthenticationService.getAuthStatus();
      print(
        '   - Final Auth Status: ${finalAuthStatus['hasAuthToken'] ? '✅ Authenticated' : '❌ Not Authenticated'}',
      );
      print('   - Token Format: ${finalAuthStatus['tokenFormat']}');
      print('');

      if (fixResult['success']) {
        print('🎉 AUTHENTICATION FIX COMPLETED SUCCESSFULLY!');
      } else {
        print('❌ AUTHENTICATION FIX FAILED - USER NEEDS TO LOGIN');
      }
    } catch (e) {
      print('💥 AUTHENTICATION FIX SCRIPT FAILED: $e');
    }
  }

  /// Quick status check without fixing
  static void quickStatusCheck() {
    print('🔍 QUICK AUTHENTICATION STATUS CHECK');
    print('===================================');
    print('');

    try {
      final authStatus = AuthenticationService.getAuthStatus();
      final storageStatus = StorageService.getStorageStatus();

      print('📱 Storage Status:');
      print('   - Initialized: ${storageStatus['isInitialized']}');
      print('   - Auth Token: ${storageStatus['hasAuthToken']}');
      print('   - Refresh Token: ${storageStatus['hasRefreshToken']}');
      print('');

      print('🔐 Authentication Status:');
      print('   - Has Auth Token: ${authStatus['hasAuthToken']}');
      print('   - Token Format: ${authStatus['tokenFormat']}');
      print('   - Token Length: ${authStatus['authTokenLength']}');
      print('');

      if (authStatus['hasAuthToken'] == true &&
          authStatus['tokenFormat'] == 'JWT') {
        print('✅ Authentication appears to be working');
      } else {
        print('❌ Authentication issues detected');
        print('💡 Run AuthFixScript.runAuthFix() to attempt automatic fix');
      }
    } catch (e) {
      print('❌ Status check failed: $e');
    }
  }
}
