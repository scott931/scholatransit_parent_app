import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/authentication_service.dart';
import '../services/auth_token_fix.dart';

/// Authentication middleware to handle token issues across all screens
class AuthMiddleware {
  /// Comprehensive authentication check and fix
  static Future<bool> checkAndFixAuth(
    BuildContext context,
    WidgetRef ref, {
    bool showSnackBar = true,
    bool autoRedirect = true,
  }) async {
    print('🔐 AuthMiddleware: Starting comprehensive authentication check...');

    try {
      // Step 1: Check storage service status
      final storageStatus = StorageService.getStorageStatus();
      if (!storageStatus['isInitialized']) {
        print('❌ AuthMiddleware: Storage not initialized');
        if (showSnackBar) {
          _showErrorSnackBar(
            context,
            'Storage service not initialized. Please restart the app.',
          );
        }
        return false;
      }

      // Step 2: Get authentication status
      final authStatus = AuthenticationService.getAuthStatus();
      print('🔐 AuthMiddleware: Auth status: $authStatus');

      // Step 3: Check if we have a valid token
      if (authStatus['hasAuthToken'] == true &&
          authStatus['tokenFormat'] == 'JWT') {
        print('✅ AuthMiddleware: Valid authentication token found');

        // Test the token with API call
        final isValid = await AuthenticationService.validateAndRefreshAuth(ref);
        if (isValid) {
          print('✅ AuthMiddleware: Token is valid and working');
          return true;
        } else {
          print('⚠️ AuthMiddleware: Token exists but is not working');
        }
      } else {
        print('❌ AuthMiddleware: No valid authentication token found');
      }

      // Step 4: Try to fix authentication issues
      print('🔧 AuthMiddleware: Attempting to fix authentication...');
      final fixResult = await AuthTokenFix.enhancedAuthFix();

      if (fixResult['success']) {
        print('✅ AuthMiddleware: Authentication fixed successfully');
        if (showSnackBar) {
          _showSuccessSnackBar(
            context,
            'Authentication restored successfully!',
          );
        }
        return true;
      } else {
        print('❌ AuthMiddleware: Could not fix authentication automatically');

        // Show detailed error information
        if (showSnackBar) {
          _showAuthFixSnackBar(context, fixResult);
        }

        // Redirect to login if auto-redirect is enabled
        if (autoRedirect) {
          print('🔄 AuthMiddleware: Redirecting to login...');
          context.go('/login');
        }

        return false;
      }
    } catch (e) {
      print('❌ AuthMiddleware: Error during authentication check: $e');
      if (showSnackBar) {
        _showErrorSnackBar(context, 'Authentication check failed: $e');
      }
      return false;
    }
  }

  /// Quick authentication check without fixing
  static bool quickAuthCheck() {
    try {
      final authStatus = AuthenticationService.getAuthStatus();
      return authStatus['hasAuthToken'] == true &&
          authStatus['tokenFormat'] == 'JWT' &&
          authStatus['storageInitialized'] == true;
    } catch (e) {
      print('❌ AuthMiddleware: Quick auth check failed: $e');
      return false;
    }
  }

  /// Force re-authentication
  static Future<void> forceReAuth(BuildContext context) async {
    print('🔄 AuthMiddleware: Forcing re-authentication...');

    try {
      await AuthTokenFix.forceReAuthentication();

      // Clear auth state in providers
      // Note: This would need to be implemented in the providers

      _showInfoSnackBar(context, 'Please log in again.');
      context.go('/login');
    } catch (e) {
      print('❌ AuthMiddleware: Error during force re-auth: $e');
      _showErrorSnackBar(context, 'Failed to clear authentication: $e');
    }
  }

  /// Show authentication fix snackbar with detailed information
  static void _showAuthFixSnackBar(
    BuildContext context,
    Map<String, dynamic> fixResult,
  ) {
    final errors = fixResult['errors'] as List<String>? ?? [];
    final recommendations = fixResult['recommendations'] as List<String>? ?? [];

    String message = 'Authentication issues detected:\n';

    if (errors.isNotEmpty) {
      message += 'Errors: ${errors.join(', ')}\n';
    }

    if (recommendations.isNotEmpty) {
      message += 'Recommendations: ${recommendations.join(', ')}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Fix Now',
          textColor: Colors.white,
          onPressed: () => _showAuthFixDialog(context),
        ),
      ),
    );
  }

  /// Show authentication fix dialog
  static void _showAuthFixDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Issues'),
        content: const Text(
          'We detected authentication issues. Would you like to:\n\n'
          '1. Try to fix automatically\n'
          '2. Clear data and login again\n'
          '3. View detailed diagnostics',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // Navigate to auth debug widget
              context.go('/auth-debug');
            },
            child: const Text('Diagnose'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              forceReAuth(context);
            },
            child: const Text('Re-login'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show success snackbar
  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  static void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Widget wrapper for automatic authentication checking
class AuthGuard extends ConsumerWidget {
  final Widget child;
  final bool showSnackBar;
  final bool autoRedirect;
  final bool autoFix;

  const AuthGuard({
    super.key,
    required this.child,
    this.showSnackBar = true,
    this.autoRedirect = true,
    this.autoFix = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: _checkAuth(context, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        } else {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Authentication Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Please log in to continue'),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<bool> _checkAuth(BuildContext context, WidgetRef ref) async {
    if (autoFix) {
      return await AuthMiddleware.checkAndFixAuth(
        context,
        ref,
        showSnackBar: showSnackBar,
        autoRedirect: autoRedirect,
      );
    } else {
      return AuthMiddleware.quickAuthCheck();
    }
  }
}
