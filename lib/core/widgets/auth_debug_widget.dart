import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/authentication_service.dart';
import '../services/auth_token_fix.dart';
import '../services/api_service.dart';
import '../config/api_endpoints.dart';

/// Debug widget for diagnosing and fixing authentication issues
class AuthDebugWidget extends ConsumerStatefulWidget {
  const AuthDebugWidget({super.key});

  @override
  ConsumerState<AuthDebugWidget> createState() => _AuthDebugWidgetState();
}

class _AuthDebugWidgetState extends ConsumerState<AuthDebugWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _authStatus;
  Map<String, dynamic>? _storageStatus;
  String _debugOutput = '';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() {
    setState(() {
      _authStatus = AuthenticationService.getAuthStatus();
      _storageStatus = StorageService.getStorageStatus();
    });
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _debugOutput += '🔍 AUTHENTICATION DIAGNOSIS\n';
      _debugOutput += '========================\n\n';

      // Step 1: Check storage status
      _debugOutput += '📱 Storage Service Status:\n';
      _debugOutput +=
          '   - Initialized: ${_storageStatus?['isInitialized'] ?? 'Unknown'}\n';
      _debugOutput +=
          '   - Auth Token: ${_storageStatus?['hasAuthToken'] ?? 'Unknown'}\n';
      _debugOutput +=
          '   - Refresh Token: ${_storageStatus?['hasRefreshToken'] ?? 'Unknown'}\n';
      _debugOutput +=
          '   - User Profile: ${_storageStatus?['hasUserProfile'] ?? 'Unknown'}\n\n';

      // Step 2: Check authentication status
      _debugOutput += '🔐 Authentication Status:\n';
      _debugOutput +=
          '   - Has Auth Token: ${_authStatus?['hasAuthToken'] ?? 'Unknown'}\n';
      _debugOutput +=
          '   - Has Refresh Token: ${_authStatus?['hasRefreshToken'] ?? 'Unknown'}\n';
      _debugOutput +=
          '   - Token Format: ${_authStatus?['tokenFormat'] ?? 'Unknown'}\n';
      _debugOutput +=
          '   - Token Length: ${_authStatus?['authTokenLength'] ?? 0}\n\n';

      // Step 3: Test storage functionality
      _debugOutput += '🧪 Testing Storage Functionality:\n';
      final storageTest = await StorageService.testStorage();
      _debugOutput +=
          '   - Storage Test: ${storageTest ? '✅ Passed' : '❌ Failed'}\n\n';

      // Step 4: Test API authentication
      _debugOutput += '🌐 Testing API Authentication:\n';
      try {
        final response = await ApiService.get<Map<String, dynamic>>(
          ApiEndpoints.profile,
        );
        _debugOutput +=
            '   - API Test: ${response.success ? '✅ Success' : '❌ Failed'}\n';
        _debugOutput += '   - Status Code: ${response.statusCode}\n';
        _debugOutput += '   - Error: ${response.error ?? 'None'}\n\n';
      } catch (e) {
        _debugOutput += '   - API Test: ❌ Exception: $e\n\n';
      }

      // Step 5: Recommendations
      _debugOutput += '💡 Recommendations:\n';
      if (!(_storageStatus?['isInitialized'] ?? false)) {
        _debugOutput += '   - ❌ Storage not initialized - restart app\n';
      } else if (!(_authStatus?['hasAuthToken'] ?? false)) {
        _debugOutput += '   - ❌ No auth token - user needs to login\n';
      } else if (!(_authStatus?['tokenFormat'] == 'JWT')) {
        _debugOutput += '   - ⚠️ Token format issue - may need refresh\n';
      } else {
        _debugOutput += '   - ✅ Authentication appears to be working\n';
      }
    } catch (e) {
      _debugOutput += '❌ Diagnosis failed: $e\n';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fixAuthTokens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _debugOutput += '\n🔧 ATTEMPTING TO FIX AUTHENTICATION\n';
      _debugOutput += '==================================\n\n';

      // Try to fix tokens
      final fixResult = await AuthTokenFix.fixAuthTokens();
      _debugOutput += 'Fix Result: ${fixResult ? '✅ Success' : '❌ Failed'}\n\n';

      // Reload status
      _loadStatus();
    } catch (e) {
      _debugOutput += '❌ Fix failed: $e\n';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceReAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _debugOutput += '\n🔄 FORCING RE-AUTHENTICATION\n';
      _debugOutput += '============================\n\n';

      await AuthTokenFix.forceReAuthentication();
      _debugOutput += '✅ All authentication data cleared\n';
      _debugOutput += '💡 User needs to login again\n\n';

      // Reload status
      _loadStatus();
    } catch (e) {
      _debugOutput += '❌ Force re-auth failed: $e\n';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Initialized: ${_storageStatus?['isInitialized'] ?? 'Unknown'}',
                    ),
                    Text(
                      'Auth Token: ${_storageStatus?['hasAuthToken'] ?? 'Unknown'}',
                    ),
                    Text(
                      'Refresh Token: ${_storageStatus?['hasRefreshToken'] ?? 'Unknown'}',
                    ),
                    Text(
                      'User Profile: ${_storageStatus?['hasUserProfile'] ?? 'Unknown'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Has Auth Token: ${_authStatus?['hasAuthToken'] ?? 'Unknown'}',
                    ),
                    Text(
                      'Token Format: ${_authStatus?['tokenFormat'] ?? 'Unknown'}',
                    ),
                    Text(
                      'Token Length: ${_authStatus?['authTokenLength'] ?? 0}',
                    ),
                    if (_authStatus?['authTokenPreview'] != null)
                      Text(
                        'Token Preview: ${_authStatus?['authTokenPreview']}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runDiagnosis,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Run Diagnosis'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fixAuthTokens,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Fix Tokens'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _forceReAuth,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Force Re-Authentication'),
              ),
            ),
            const SizedBox(height: 16),
            // Debug Output
            if (_debugOutput.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Output',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _debugOutput,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
