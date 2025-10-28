import 'package:flutter/material.dart';
import '../services/auth_token_fix.dart';

/// Authentication Token Debug Widget
/// Shows token status and provides fix options
class AuthTokenDebugWidget extends StatefulWidget {
  const AuthTokenDebugWidget({super.key});

  @override
  State<AuthTokenDebugWidget> createState() => _AuthTokenDebugWidgetState();
}

class _AuthTokenDebugWidgetState extends State<AuthTokenDebugWidget> {
  Map<String, dynamic>? _diagnosis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDiagnosis();
  }

  void _loadDiagnosis() async {
    setState(() => _isLoading = true);

    try {
      final diagnosis = await AuthTokenFix.diagnoseAuthTokens();
      setState(() => _diagnosis = diagnosis);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fixTokens() async {
    setState(() => _isLoading = true);

    try {
      final success = await AuthTokenFix.fixAuthTokens();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Authentication tokens fixed!'
                  : '❌ Could not fix tokens automatically',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

      if (success) {
        _loadDiagnosis();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceReAuth() async {
    setState(() => _isLoading = true);

    try {
      await AuthTokenFix.forceReAuthentication();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔄 Authentication data cleared. Please login again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _loadDiagnosis();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeFix() async {
    setState(() => _isLoading = true);

    try {
      final success = await AuthTokenFix.completeAuthFix();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Authentication completely fixed!'
                  : '❌ Complete fix failed - please login again',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

      _loadDiagnosis();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_diagnosis == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Authentication Token Debug',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadDiagnosis,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Token Status
            _buildStatusRow(
              'Auth Token',
              _diagnosis!['hasAuthToken'] ? 'Present' : 'Missing',
              _diagnosis!['hasAuthToken'] ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Refresh Token',
              _diagnosis!['hasRefreshToken'] ? 'Present' : 'Missing',
              _diagnosis!['hasRefreshToken'] ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Parent ID',
              _diagnosis!['hasParentId'] ? 'Present' : 'Missing',
              _diagnosis!['hasParentId'] ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'User Profile',
              _diagnosis!['hasUserProfile'] ? 'Present' : 'Missing',
              _diagnosis!['hasUserProfile'] ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 16),

            // Token Details
            if (_diagnosis!['authTokenLength'] > 0)
              _buildInfoRow(
                'Auth Token Length',
                '${_diagnosis!['authTokenLength']}',
              ),
            if (_diagnosis!['refreshTokenLength'] > 0)
              _buildInfoRow(
                'Refresh Token Length',
                '${_diagnosis!['refreshTokenLength']}',
              ),
            if (_diagnosis!['parentId'] != null)
              _buildInfoRow('Parent ID', '${_diagnosis!['parentId']}'),

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fixTokens,
                  icon: const Icon(Icons.build),
                  label: const Text('Fix Tokens'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _forceReAuth,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _completeFix,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Complete Fix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          const Text(': '),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
