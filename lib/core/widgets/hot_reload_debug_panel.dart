import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/hot_reload_handler.dart';
import '../providers/parent_provider.dart';

/// Debug panel for handling hot reload cache issues in development
class HotReloadDebugPanel extends ConsumerWidget {
  const HotReloadDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'Hot Reload Debug',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildDebugButton('Clear Cache', Colors.red, () async {
                await HotReloadHandler.forceClearCache();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }),
              _buildDebugButton('Reset State', Colors.blue, () async {
                await ref.read(parentProvider.notifier).clearHotReloadCache();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('State reset')));
              }),
              _buildDebugButton('Force Refresh', Colors.green, () async {
                await ref.read(parentProvider.notifier).forceRefreshAllData();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Data refreshed')));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 10),
      ),
      child: Text(label),
    );
  }
}
