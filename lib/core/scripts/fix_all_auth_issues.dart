import '../services/storage_service.dart';
import '../services/authentication_service.dart';
import '../services/auth_token_fix.dart';

/// Comprehensive script to fix all authentication issues across the project
class FixAllAuthIssues {
  static Future<Map<String, dynamic>> runComprehensiveFix() async {
    print('🚀 COMPREHENSIVE AUTHENTICATION FIX SCRIPT');
    print('==========================================');
    print('');

    final result = <String, dynamic>{
      'success': false,
      'steps': <String>[],
      'errors': <String>[],
      'warnings': <String>[],
      'recommendations': <String>[],
      'details': <String, dynamic>{},
    };

    try {
      // Step 1: Initialize storage service
      (result['steps'] as List<String>).add('Initializing storage service...');
      await StorageService.init();
      (result['steps'] as List<String>).add('✅ Storage service initialized');

      // Step 2: Test storage functionality
      (result['steps'] as List<String>).add('Testing storage functionality...');
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
      (result['steps'] as List<String>).add('✅ Storage functionality verified');

      // Step 3: Check current authentication status
      (result['steps'] as List<String>).add(
        'Checking current authentication status...',
      );
      final authStatus = AuthenticationService.getAuthStatus();
      (result['details'] as Map<String, dynamic>)['initialAuthStatus'] =
          authStatus;

      if (authStatus['hasAuthToken'] == true &&
          authStatus['tokenFormat'] == 'JWT') {
        (result['steps'] as List<String>).add(
          '✅ Valid authentication token found',
        );

        // Test the token
        (result['steps'] as List<String>).add(
          'Testing authentication token...',
        );
        // Note: This would need a WidgetRef to test properly
        (result['steps'] as List<String>).add(
          '⚠️ Token testing requires UI context',
        );
      } else {
        (result['steps'] as List<String>).add(
          '❌ No valid authentication token found',
        );
        (result['warnings'] as List<String>).add('User needs to authenticate');
      }

      // Step 4: Run enhanced authentication fix
      (result['steps'] as List<String>).add(
        'Running enhanced authentication fix...',
      );
      final fixResult = await AuthTokenFix.enhancedAuthFix();
      (result['details'] as Map<String, dynamic>)['fixResult'] = fixResult;

      if (fixResult['success'] == true) {
        (result['steps'] as List<String>).add(
          '✅ Authentication fixed successfully',
        );
        result['success'] = true;
      } else {
        (result['steps'] as List<String>).add('❌ Authentication fix failed');
        (result['errors'] as List<String>).addAll(
          fixResult['errors'] as List<String>? ?? [],
        );
        (result['recommendations'] as List<String>).addAll(
          fixResult['recommendations'] as List<String>? ?? [],
        );
      }

      // Step 5: Final status check
      (result['steps'] as List<String>).add('Performing final status check...');
      final finalAuthStatus = AuthenticationService.getAuthStatus();
      (result['details'] as Map<String, dynamic>)['finalAuthStatus'] =
          finalAuthStatus;

      if (finalAuthStatus['hasAuthToken'] == true &&
          finalAuthStatus['tokenFormat'] == 'JWT') {
        (result['steps'] as List<String>).add(
          '✅ Final authentication status: Valid',
        );
        result['success'] = true;
      } else {
        (result['steps'] as List<String>).add(
          '❌ Final authentication status: Invalid',
        );
        (result['recommendations'] as List<String>).add(
          'User needs to login again',
        );
      }

      // Step 6: Generate summary
      (result['steps'] as List<String>).add('Generating fix summary...');
      _generateSummary(result);
    } catch (e) {
      (result['errors'] as List<String>).add('Exception during fix: $e');
      (result['steps'] as List<String>).add(
        '❌ Fix process failed with exception',
      );
    }

    return result;
  }

  /// Quick authentication status check
  static Map<String, dynamic> quickStatusCheck() {
    print('🔍 QUICK AUTHENTICATION STATUS CHECK');
    print('===================================');
    print('');

    final result = <String, dynamic>{
      'success': false,
      'status': <String, dynamic>{},
      'issues': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Check storage status
      final storageStatus = StorageService.getStorageStatus();
      (result['status'] as Map<String, dynamic>)['storage'] = storageStatus;

      if (!storageStatus['isInitialized']) {
        (result['issues'] as List<String>).add(
          'Storage service not initialized',
        );
        (result['recommendations'] as List<String>).add(
          'Restart the application',
        );
      }

      // Check authentication status
      final authStatus = AuthenticationService.getAuthStatus();
      (result['status'] as Map<String, dynamic>)['authentication'] = authStatus;

      if (authStatus['hasAuthToken'] != true) {
        (result['issues'] as List<String>).add('No authentication token found');
        (result['recommendations'] as List<String>).add('User needs to login');
      } else if (authStatus['tokenFormat'] != 'JWT') {
        (result['issues'] as List<String>).add('Invalid token format');
        (result['recommendations'] as List<String>).add(
          'Token may be corrupted',
        );
      } else {
        result['success'] = true;
      }

      // Print status
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

      if (result['success'] == true) {
        print('✅ Authentication appears to be working');
      } else {
        print('❌ Authentication issues detected:');
        for (final issue in result['issues'] as List<String>) {
          print('   - $issue');
        }
        print('');
        print('💡 Recommendations:');
        for (final recommendation
            in result['recommendations'] as List<String>) {
          print('   - $recommendation');
        }
      }
    } catch (e) {
      (result['issues'] as List<String>).add('Status check failed: $e');
      print('❌ Status check failed: $e');
    }

    return result;
  }

  /// Generate comprehensive fix summary
  static void _generateSummary(Map<String, dynamic> result) {
    print('');
    print('📊 AUTHENTICATION FIX SUMMARY');
    print('=============================');
    print('');

    print('✅ Steps Completed:');
    for (final step in result['steps'] as List<String>) {
      print('   $step');
    }
    print('');

    if ((result['errors'] as List<String>).isNotEmpty) {
      print('❌ Errors Encountered:');
      for (final error in result['errors'] as List<String>) {
        print('   - $error');
      }
      print('');
    }

    if ((result['warnings'] as List<String>).isNotEmpty) {
      print('⚠️ Warnings:');
      for (final warning in result['warnings'] as List<String>) {
        print('   - $warning');
      }
      print('');
    }

    if ((result['recommendations'] as List<String>).isNotEmpty) {
      print('💡 Recommendations:');
      for (final recommendation in result['recommendations'] as List<String>) {
        print('   - $recommendation');
      }
      print('');
    }

    if (result['success'] == true) {
      print('🎉 AUTHENTICATION FIX COMPLETED SUCCESSFULLY!');
    } else {
      print('❌ AUTHENTICATION FIX FAILED - MANUAL INTERVENTION REQUIRED');
    }
  }

  /// Force clear all authentication data
  static Future<void> forceClearAllAuth() async {
    print('🔄 FORCING CLEAR ALL AUTHENTICATION DATA');
    print('=======================================');
    print('');

    try {
      await AuthTokenFix.forceReAuthentication();
      print('✅ All authentication data cleared');
      print('💡 User needs to login again');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }
}
