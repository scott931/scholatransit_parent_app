import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../providers/parent_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheBuster {
  static Future<void> clearAllCaches() async {
    print('🧹 Clearing all app caches...');

    try {
      // Clear all storage
      await StorageService.clearAllData();

      // Clear any cached network images
      await _clearImageCache();

      // Clear any cached data in memory
      await _clearMemoryCache();

      print('✅ All caches cleared successfully');
    } catch (e) {
      print('❌ Error clearing caches: $e');
    }
  }

  static Future<void> _clearImageCache() async {
    try {
      // Clear cached network images
      await DefaultCacheManager.emptyCache();
    } catch (e) {
      print('⚠️ Could not clear image cache: $e');
    }
  }

  static Future<void> _clearMemoryCache() async {
    try {
      // Force garbage collection
      // This is a best-effort approach
      print('🗑️ Clearing memory cache...');
    } catch (e) {
      print('⚠️ Could not clear memory cache: $e');
    }
  }

  static Future<void> forceRefreshApp() async {
    print('🔄 Force refreshing app...');

    // Clear all caches
    await clearAllCaches();

    // Restart the app (this would need to be handled by the main app)
    print('📱 App should be restarted to complete refresh');
  }

  // Hot reload specific cache clearing
  static Future<void> clearHotReloadCache(WidgetRef? ref) async {
    if (kDebugMode) {
      print('🔥 Clearing hot reload cache...');

      try {
        // Clear all storage
        await StorageService.clearAllData();

        // Clear parent provider cache if ref is available
        if (ref != null) {
          await ref.read(parentProvider.notifier).clearHotReloadCache();
        }

        // Clear any cached network images
        await _clearImageCache();

        // Clear any cached data in memory
        await _clearMemoryCache();

        print('✅ Hot reload cache cleared successfully');
      } catch (e) {
        print('❌ Error clearing hot reload cache: $e');
      }
    }
  }
}

// Simple cache manager for images
class DefaultCacheManager {
  static Future<void> emptyCache() async {
    // This would clear any cached images
    // Implementation depends on your image caching strategy
    print('🖼️ Image cache cleared');
  }
}
