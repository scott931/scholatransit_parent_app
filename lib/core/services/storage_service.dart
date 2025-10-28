import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static Box? _box;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      print('🔧 StorageService: Already initialized, skipping...');
      return;
    }

    try {
      print('🔧 StorageService: Initializing storage services...');
      _prefs = await SharedPreferences.getInstance();
      _box = await Hive.openBox('go_drop_parents');
      _isInitialized = true;
      print('✅ StorageService: Initialization completed successfully');
    } catch (e) {
      print('❌ StorageService: Initialization failed: $e');
      rethrow;
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized || _prefs == null || _box == null) {
      throw Exception(
        'StorageService not initialized. Call StorageService.init() first.',
      );
    }
  }

  // SharedPreferences methods
  static Future<void> setString(String key, String value) async {
    _ensureInitialized();
    try {
      await _prefs!.setString(key, value);
      print('🔧 StorageService: Saved string for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to save string for key $key: $e');
      rethrow;
    }
  }

  static String? getString(String key) {
    _ensureInitialized();
    try {
      final value = _prefs!.getString(key);
      print(
        '🔧 StorageService: Retrieved string for key: $key (${value != null ? 'found' : 'null'})',
      );
      return value;
    } catch (e) {
      print('❌ StorageService: Failed to get string for key $key: $e');
      return null;
    }
  }

  static Future<void> setInt(String key, int value) async {
    _ensureInitialized();
    try {
      await _prefs!.setInt(key, value);
      print('🔧 StorageService: Saved int for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to save int for key $key: $e');
      rethrow;
    }
  }

  static int? getInt(String key) {
    _ensureInitialized();
    try {
      final value = _prefs!.getInt(key);
      print(
        '🔧 StorageService: Retrieved int for key: $key (${value != null ? 'found' : 'null'})',
      );
      return value;
    } catch (e) {
      print('❌ StorageService: Failed to get int for key $key: $e');
      return null;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    _ensureInitialized();
    try {
      await _prefs!.setBool(key, value);
      print('🔧 StorageService: Saved bool for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to save bool for key $key: $e');
      rethrow;
    }
  }

  static bool? getBool(String key) {
    _ensureInitialized();
    try {
      final value = _prefs!.getBool(key);
      print(
        '🔧 StorageService: Retrieved bool for key: $key (${value != null ? 'found' : 'null'})',
      );
      return value;
    } catch (e) {
      print('❌ StorageService: Failed to get bool for key $key: $e');
      return null;
    }
  }

  static Future<void> setDouble(String key, double value) async {
    _ensureInitialized();
    try {
      await _prefs!.setDouble(key, value);
      print('🔧 StorageService: Saved double for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to save double for key $key: $e');
      rethrow;
    }
  }

  static double? getDouble(String key) {
    _ensureInitialized();
    try {
      final value = _prefs!.getDouble(key);
      print(
        '🔧 StorageService: Retrieved double for key: $key (${value != null ? 'found' : 'null'})',
      );
      return value;
    } catch (e) {
      print('❌ StorageService: Failed to get double for key $key: $e');
      return null;
    }
  }

  static Future<void> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    try {
      await _prefs!.setStringList(key, value);
      print('🔧 StorageService: Saved string list for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to save string list for key $key: $e');
      rethrow;
    }
  }

  static List<String>? getStringList(String key) {
    _ensureInitialized();
    try {
      final value = _prefs!.getStringList(key);
      print(
        '🔧 StorageService: Retrieved string list for key: $key (${value != null ? 'found' : 'null'})',
      );
      return value;
    } catch (e) {
      print('❌ StorageService: Failed to get string list for key $key: $e');
      return null;
    }
  }

  static Future<void> remove(String key) async {
    _ensureInitialized();
    try {
      await _prefs!.remove(key);
      print('🔧 StorageService: Removed key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to remove key $key: $e');
      rethrow;
    }
  }

  static Future<void> clear() async {
    _ensureInitialized();
    try {
      await _prefs!.clear();
      print('🔧 StorageService: Cleared all SharedPreferences data');
    } catch (e) {
      print('❌ StorageService: Failed to clear SharedPreferences: $e');
      rethrow;
    }
  }

  // Hive methods for complex data
  static Future<void> setObject(String key, dynamic value) async {
    _ensureInitialized();
    try {
      await _box!.put(key, value);
      print('🔧 StorageService: Saved object for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to save object for key $key: $e');
      rethrow;
    }
  }

  static T? getObject<T>(String key) {
    _ensureInitialized();
    try {
      final value = _box!.get(key);
      print(
        '🔧 StorageService: Retrieved object for key: $key (${value != null ? 'found' : 'null'})',
      );
      return value;
    } catch (e) {
      print('❌ StorageService: Failed to get object for key $key: $e');
      return null;
    }
  }

  static Future<void> deleteObject(String key) async {
    _ensureInitialized();
    try {
      await _box!.delete(key);
      print('🔧 StorageService: Deleted object for key: $key');
    } catch (e) {
      print('❌ StorageService: Failed to delete object for key $key: $e');
      rethrow;
    }
  }

  static Future<void> clearBox() async {
    _ensureInitialized();
    try {
      await _box!.clear();
      print('🔧 StorageService: Cleared all Hive data');
    } catch (e) {
      print('❌ StorageService: Failed to clear Hive data: $e');
      rethrow;
    }
  }

  // Auth token methods with enhanced error handling and validation
  static Future<void> saveAuthToken(String token) async {
    if (token.isEmpty) {
      print('⚠️ StorageService: Attempting to save empty auth token');
      return;
    }

    try {
      await setString(AppConfig.authTokenKey, token);
      print(
        '✅ StorageService: Auth token saved successfully (${token.length} chars)',
      );

      // Verify the token was saved correctly
      final savedToken = getAuthToken();
      if (savedToken != token) {
        print(
          '❌ StorageService: Token verification failed - saved token does not match',
        );
        throw Exception('Token verification failed');
      }
    } catch (e) {
      print('❌ StorageService: Failed to save auth token: $e');
      rethrow;
    }
  }

  static String? getAuthToken() {
    try {
      final token = getString(AppConfig.authTokenKey);
      if (token != null && token.isNotEmpty) {
        print('✅ StorageService: Auth token retrieved (${token.length} chars)');
      } else {
        print('⚠️ StorageService: No auth token found');
      }
      return token;
    } catch (e) {
      print('❌ StorageService: Failed to get auth token: $e');
      return null;
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    if (token.isEmpty) {
      print('⚠️ StorageService: Attempting to save empty refresh token');
      return;
    }

    try {
      await setString(AppConfig.refreshTokenKey, token);
      print(
        '✅ StorageService: Refresh token saved successfully (${token.length} chars)',
      );
    } catch (e) {
      print('❌ StorageService: Failed to save refresh token: $e');
      rethrow;
    }
  }

  static String? getRefreshToken() {
    try {
      final token = getString(AppConfig.refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        print(
          '✅ StorageService: Refresh token retrieved (${token.length} chars)',
        );
      } else {
        print('⚠️ StorageService: No refresh token found');
      }
      return token;
    } catch (e) {
      print('❌ StorageService: Failed to get refresh token: $e');
      return null;
    }
  }

  static Future<void> clearAuthTokens() async {
    try {
      print('🔧 StorageService: Clearing authentication tokens...');
      await remove(AppConfig.authTokenKey);
      await remove(AppConfig.refreshTokenKey);
      print('✅ StorageService: Authentication tokens cleared');
    } catch (e) {
      print('❌ StorageService: Failed to clear auth tokens: $e');
      rethrow;
    }
  }

  // User profile methods
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await setObject(AppConfig.userProfileKey, profile);
  }

  static Map<String, dynamic>? getUserProfile() {
    return getObject<Map<String, dynamic>>(AppConfig.userProfileKey);
  }

  static Future<void> clearUserProfile() async {
    await deleteObject(AppConfig.userProfileKey);
  }

  // Driver ID methods
  static Future<void> saveDriverId(int driverId) async {
    await setInt(AppConfig.driverIdKey, driverId);
  }

  static int? getDriverId() {
    return getInt(AppConfig.driverIdKey);
  }

  static Future<void> clearDriverId() async {
    await remove(AppConfig.driverIdKey);
  }

  // Current trip methods
  static Future<void> saveCurrentTrip(Map<String, dynamic> trip) async {
    await setObject(AppConfig.currentTripKey, trip);
  }

  static Map<String, dynamic>? getCurrentTrip() {
    return getObject<Map<String, dynamic>>(AppConfig.currentTripKey);
  }

  static Future<void> clearCurrentTrip() async {
    await deleteObject(AppConfig.currentTripKey);
  }

  // Location history methods
  static Future<void> saveLocationHistory(
    List<Map<String, dynamic>> locations,
  ) async {
    await setObject(AppConfig.locationHistoryKey, locations);
  }

  static List<Map<String, dynamic>>? getLocationHistory() {
    return getObject<List<Map<String, dynamic>>>(AppConfig.locationHistoryKey);
  }

  static Future<void> clearLocationHistory() async {
    await deleteObject(AppConfig.locationHistoryKey);
  }

  // Notification settings methods
  static Future<void> saveNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    await setObject(AppConfig.notificationSettingsKey, settings);
  }

  static Map<String, dynamic>? getNotificationSettings() {
    return getObject<Map<String, dynamic>>(AppConfig.notificationSettingsKey);
  }

  static Future<void> clearNotificationSettings() async {
    await deleteObject(AppConfig.notificationSettingsKey);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await clear();
    await clearBox();
  }

  // Force refresh all data (cache busting)
  static Future<void> forceRefreshAllData() async {
    await clearAllData();
    // Clear any in-memory caches
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Comprehensive storage status check
  static Map<String, dynamic> getStorageStatus() {
    try {
      _ensureInitialized();

      final authToken = getAuthToken();
      final refreshToken = getRefreshToken();
      final userProfile = getUserProfile();
      final driverId = getInt(AppConfig.driverIdKey);

      return {
        'isInitialized': _isInitialized,
        'hasAuthToken': authToken != null && authToken.isNotEmpty,
        'hasRefreshToken': refreshToken != null && refreshToken.isNotEmpty,
        'hasUserProfile': userProfile != null,
        'hasDriverId': driverId != null,
        'authTokenLength': authToken?.length ?? 0,
        'refreshTokenLength': refreshToken?.length ?? 0,
        'driverId': driverId,
        'authTokenPreview': authToken?.substring(0, 20) ?? 'null',
        'refreshTokenPreview': refreshToken?.substring(0, 20) ?? 'null',
      };
    } catch (e) {
      return {
        'isInitialized': false,
        'error': e.toString(),
        'hasAuthToken': false,
        'hasRefreshToken': false,
        'hasUserProfile': false,
        'hasDriverId': false,
      };
    }
  }

  // Test storage functionality
  static Future<bool> testStorage() async {
    try {
      _ensureInitialized();

      final testKey = 'storage_test_${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'test_value_${DateTime.now().millisecondsSinceEpoch}';

      // Test SharedPreferences
      await setString(testKey, testValue);
      final retrievedValue = getString(testKey);
      await remove(testKey);

      if (retrievedValue != testValue) {
        print('❌ StorageService: SharedPreferences test failed');
        return false;
      }

      // Test Hive
      final testObjectKey =
          'object_test_${DateTime.now().millisecondsSinceEpoch}';
      final testObject = {
        'test': 'value',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await setObject(testObjectKey, testObject);
      final retrievedObject = getObject<Map<String, dynamic>>(testObjectKey);
      await deleteObject(testObjectKey);

      if (retrievedObject == null || retrievedObject['test'] != 'value') {
        print('❌ StorageService: Hive test failed');
        return false;
      }

      print('✅ StorageService: All storage tests passed');
      return true;
    } catch (e) {
      print('❌ StorageService: Storage test failed: $e');
      return false;
    }
  }
}
