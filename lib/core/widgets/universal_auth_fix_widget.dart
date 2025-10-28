import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/authentication_service.dart';
import '../middleware/auth_middleware.dart';
import '../scripts/fix_all_auth_issues.dart';

/// Universal authentication fix widget that can be added to any screen
class UniversalAuthFixWidget extends ConsumerStatefulWidget {
  final bool showAsFloatingButton;
  final bool showDetailedInfo;
  final Color? backgroundColor;
  final Color? textColor;

  const UniversalAuthFixWidget({
    super.key,
    this.showAsFloatingButton = true,
    this.showDetailedInfo = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  ConsumerState<UniversalAuthFixWidget> createState() =>
      _UniversalAuthFixWidgetState();
}

class _UniversalAuthFixWidgetState
    extends ConsumerState<UniversalAuthFixWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _authStatus;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAuthStatus();
  }

  void _loadAuthStatus() {
    setState(() {
      _authStatus = AuthenticationService.getAuthStatus();
      _updateStatusMessage();
    });
  }

  void _updateStatusMessage() {
    if (_authStatus == null) {
      _statusMessage = 'Checking authentication...';
      return;
    }

    final hasToken = _authStatus!['hasAuthToken'] == true;
    final tokenFormat = _authStatus!['tokenFormat'];
    final storageInitialized = _authStatus!['storageInitialized'] == true;

    if (!storageInitialized) {
      _statusMessage = 'Storage not initialized';
    } else if (!hasToken) {
      _statusMessage = 'No authentication token';
    } else if (tokenFormat != 'JWT') {
      _statusMessage = 'Invalid token format';
    } else {
      _statusMessage = 'Authentication OK';
    }
  }

  Future<void> _runQuickFix() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthMiddleware.checkAndFixAuth(
        context,
        ref,
        showSnackBar: false,
        autoRedirect: false,
      );

      if (success) {
        _showSnackBar('Authentication fixed successfully!', Colors.green);
      } else {
        _showSnackBar(
          'Could not fix authentication automatically',
          Colors.orange,
        );
      }

      _loadAuthStatus();
    } catch (e) {
      _showSnackBar('Fix failed: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runComprehensiveFix() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FixAllAuthIssues.runComprehensiveFix();

      if (result['success']) {
        _showSnackBar(
          'Comprehensive fix completed successfully!',
          Colors.green,
        );
      } else {
        _showSnackBar(
          'Comprehensive fix failed - check details',
          Colors.orange,
        );
        _showDetailedResults(result);
      }

      _loadAuthStatus();
    } catch (e) {
      _showSnackBar('Comprehensive fix failed: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDetailedResults(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result['steps'].isNotEmpty) ...[
                const Text(
                  'Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...result['steps'].map((step) => Text('• $step')),
                const SizedBox(height: 8),
              ],
              if (result['errors'].isNotEmpty) ...[
                const Text(
                  'Errors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                ...result['errors'].map(
                  (error) => Text(
                    '• $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (result['recommendations'].isNotEmpty) ...[
                const Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                ...result['recommendations'].map(
                  (rec) => Text(
                    '• $rec',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAuthDebugScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AuthDebugWidget()));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAsFloatingButton) {
      return _buildFloatingButton();
    } else {
      return _buildInlineWidget();
    }
  }

  Widget _buildFloatingButton() {
    final isAuthOk =
        _authStatus?['hasAuthToken'] == true &&
        _authStatus?['tokenFormat'] == 'JWT' &&
        _authStatus?['storageInitialized'] == true;

    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: _isLoading ? null : _runQuickFix,
        backgroundColor: isAuthOk ? Colors.green : Colors.orange,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(isAuthOk ? Icons.check : Icons.warning, color: Colors.white),
      ),
    );
  }

  Widget _buildInlineWidget() {
    final isAuthOk =
        _authStatus?['hasAuthToken'] == true &&
        _authStatus?['tokenFormat'] == 'JWT' &&
        _authStatus?['storageInitialized'] == true;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAuthOk ? Icons.check_circle : Icons.warning,
                  color: isAuthOk ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Authentication Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_statusMessage, style: TextStyle(color: widget.textColor)),
            if (widget.showDetailedInfo) ...[
              const SizedBox(height: 8),
              if (_authStatus != null) ...[
                Text('Token Length: ${_authStatus!['authTokenLength']}'),
                Text('Token Format: ${_authStatus!['tokenFormat']}'),
                Text(
                  'Storage: ${_authStatus!['storageInitialized'] ? 'OK' : 'Error'}',
                ),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runQuickFix,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Quick Fix'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runComprehensiveFix,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Full Fix'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showAuthDebugScreen,
                child: const Text('Debug Tools'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AuthDebugWidget import (assuming it exists)
class AuthDebugWidget extends StatelessWidget {
  const AuthDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Auth Debug Widget - Implementation needed'),
      ),
    );
  }
}
