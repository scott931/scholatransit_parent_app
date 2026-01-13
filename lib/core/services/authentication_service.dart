import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import 'api_service.dart';
import '../config/api_endpoints.dart';
import '../providers/parent_auth_provider.dart';

/// Centralized authentication service to eliminate duplicates
class AuthenticationService {
  static final AuthenticationService _instance =
      AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal();

  /// Check if user is authenticated (simple check)
  static bool isAuthenticated() {
    final token = StorageService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current authentication token
  static String? getAuthToken() {
    return StorageService.getAuthToken();
  }

  /// Comprehensive authentication validation with automatic refresh
  static Future<bool> validateAndRefreshAuth(WidgetRef? ref) async {
    try {
      print('🔐 AuthService: Starting authentication validation...');

      // First check if storage is working
      final storageStatus = StorageService.getStorageStatus();
      if (!storageStatus['isInitialized']) {
        print('❌ AuthService: Storage service not initialized');
        return false;
      }

      final token = StorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        print('🔐 AuthService: No authentication token found');
        print('🔐 AuthService: Storage status: $storageStatus');
        return false;
      }

      // Validate token format
      if (!token.startsWith('eyJ')) {
        print('⚠️ AuthService: Token does not have JWT format');
        print('⚠️ AuthService: Token preview: ${token.substring(0, 20)}...');
      }

      print('🔐 AuthService: Token found, validating with API...');

      // Check if token is valid by making a simple API call with timeout
      // Use a shorter timeout (15 seconds) to prevent dashboard from hanging
      ApiResponse<Map<String, dynamic>> response;
      try {
        response = await ApiService.get<Map<String, dynamic>>(
          ApiEndpoints.profile,
        ).timeout(
          const Duration(seconds: 15),
        );
      } on TimeoutException catch (e) {
        print('⏰ AuthService: Authentication validation timed out');
        // If token exists but validation times out, assume token is valid
        // This prevents blocking the dashboard on slow networks
        print('⚠️ AuthService: Assuming token is valid due to timeout');
        return true;
      } catch (e) {
        print('❌ AuthService: Error during API call: $e');
        // If there's a network error but token exists, assume valid
        // Individual API calls will handle auth errors properly
        return true;
      }

      if (response.success) {
        print('✅ AuthService: Authentication token is valid');
        return true;
      } else if (response.error?.contains('401') == true ||
          response.error?.contains('token') == true) {
        print(
          '🔄 AuthService: Token expired or invalid, attempting refresh...',
        );

        // Try to refresh token using parent auth provider if available
        if (ref != null) {
          try {
            final authNotifier = ref.read(parentAuthProvider.notifier);
            final refreshSuccess = await authNotifier.refreshToken();
            if (refreshSuccess) {
              print('✅ AuthService: Token refreshed successfully');
              return true;
            } else {
              print('❌ AuthService: Token refresh failed, user needs to login');
              return false;
            }
          } catch (e) {
            print('❌ AuthService: Token refresh error: $e');
            return false;
          }
        } else {
          print('⚠️ AuthService: No ref provided for token refresh');
          return false;
        }
      } else {
        print('❌ AuthService: API call failed with error: ${response.error}');
        return false;
      }
    } catch (e) {
      print('❌ AuthService: Authentication validation error: $e');
      return false;
    }
  }

  /// Get comprehensive authentication status
  static Map<String, dynamic> getAuthStatus() {
    try {
      final storageStatus = StorageService.getStorageStatus();
      final authToken = StorageService.getAuthToken();
      final refreshToken = StorageService.getRefreshToken();
      final parentId = StorageService.getInt('parent_id');
      final userProfile = StorageService.getUserProfile();

      return {
        'storageInitialized': storageStatus['isInitialized'],
        'hasAuthToken': authToken != null && authToken.isNotEmpty,
        'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
        'hasParentId': parentId != null,
        'hasUserProfile': userProfile != null,
        'authTokenLength': authToken?.length ?? 0,
        'refreshTokenLength': refreshToken?.length ?? 0,
        'parentId': parentId,
        'authTokenPreview': authToken?.substring(0, 20) ?? 'null',
        'refreshTokenPreview': refreshToken?.substring(0, 20) ?? 'null',
        'tokenFormat': authToken?.startsWith('eyJ') == true ? 'JWT' : 'Other',
        'storageError': storageStatus['error'],
      };
    } catch (e) {
      return {
        'storageInitialized': false,
        'hasAuthToken': false,
        'hasRefreshToken': false,
        'hasParentId': false,
        'hasUserProfile': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear all authentication data
  static Future<void> clearAuth() async {
    await StorageService.clearAuthTokens();
    await StorageService.clearUserProfile();
    await StorageService.remove('parent_id');
  }

  /// Validate storage service is working
  static Future<bool> validateStorage() async {
    try {
      final testKey = 'auth_test_${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'test_value_${DateTime.now().millisecondsSinceEpoch}';

      await StorageService.setString(testKey, testValue);
      final retrievedValue = StorageService.getString(testKey);
      await StorageService.remove(testKey);

      return retrievedValue == testValue;
    } catch (e) {
      print('❌ AuthService: Storage validation failed: $e');
      return false;
    }
  }
}

/// Provider for authentication service
final authServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService();
});

/// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return AuthenticationService.isAuthenticated();
});

/// Provider for comprehensive authentication validation
final authValidationProvider = FutureProvider<bool>((ref) async {
  return await AuthenticationService.validateAndRefreshAuth(null);
});
