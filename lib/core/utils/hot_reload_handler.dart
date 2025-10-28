import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_buster.dart';
import '../providers/parent_provider.dart';

/// Handles hot reload cache issues in development mode
class HotReloadHandler {
  static bool _isInitialized = false;
  static WidgetRef? _ref;

  /// Initialize the hot reload handler
  static void initialize(WidgetRef ref) {
    if (kDebugMode && !_isInitialized) {
      _ref = ref;
      _isInitialized = true;
      print('🔥 Hot reload handler initialized');
    }
  }

  /// Clear cache on hot reload
  static Future<void> onHotReload() async {
    if (kDebugMode) {
      print('🔥 Hot reload detected - clearing cache...');
      await CacheBuster.clearHotReloadCache(_ref);
    }
  }

  /// Force clear all development caches
  static Future<void> forceClearCache() async {
    if (kDebugMode) {
      print('🧹 Force clearing all development caches...');
      await CacheBuster.clearAllCaches();
      if (_ref != null) {
        await _ref!.read(parentProvider.notifier).clearHotReloadCache();
      }
    }
  }

  /// Check if we're in development mode and should clear cache
  static bool shouldClearCacheOnReload() {
    return kDebugMode;
  }
}
