import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as location_package;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Consolidated Location Service
/// Combines the best features from all location services while maintaining compatibility
class ConsolidatedLocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _currentPosition;
  static bool _isTracking = false;
  static bool _isInitialized = false;
  static final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  // Circuit breaker and retry logic
  static int _consecutiveFailures = 0;
  static bool _isCircuitOpen = false;
  static Timer? _retryTimer;
  static Timer? _healthCheckTimer;
  static DateTime? _lastSuccessfulUpdate;

  // Configuration
  static const int maxConsecutiveFailures = 3;
  static const Duration circuitBreakerResetDuration = Duration(minutes: 2);
  static const Duration healthCheckInterval = Duration(seconds: 30);
  static const double _defaultDistanceFilter = 30.0;
  static const double _fallbackDistanceFilter = 50.0;

  // Callbacks
  static Function(Position)? _onLocationUpdate;
  static Function(String)? _onLocationError;

  // Getters
  static Stream<Position> get locationStream => _locationController.stream;
  static Position? get currentPosition => _currentPosition;
  static bool get isTracking => _isTracking;
  static bool get isInitialized => _isInitialized;

  /// Initialize the consolidated location service
  static Future<bool> init() async {
    try {
      if (_isInitialized) {
        debugPrint('⚠️ ConsolidatedLocationService already initialized');
        return true;
      }

      debugPrint('📍 ConsolidatedLocationService: Initializing...');

      // Check permissions
      final permission = await _checkPermissions();
      if (!permission) {
        debugPrint('❌ Location permissions not granted');
        return false;
      }

      // Configure location package for background mode
      await _configureLocationPackage();

      _isInitialized = true;
      debugPrint('✅ ConsolidatedLocationService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ ConsolidatedLocationService: Initialization failed: $e');
      return false;
    }
  }

  /// Check and request permissions
  static Future<bool> _checkPermissions() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      return false;
    }

    // Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requestPermission = await Geolocator.requestPermission();
      if (requestPermission == LocationPermission.denied) {
        debugPrint('❌ Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permission permanently denied');
      return false;
    }

    return true;
  }

  /// Configure location package settings
  static Future<void> _configureLocationPackage() async {
    try {
      final location = location_package.Location();

      // Enable background mode
      await location.enableBackgroundMode(enable: true);

      // Set location settings
      await location.changeSettings(
        accuracy: location_package.LocationAccuracy.high,
        interval: 10000, // 10 seconds
        distanceFilter: _defaultDistanceFilter,
      );

      debugPrint('✅ Location package configured');
    } catch (e) {
      debugPrint('⚠️ Could not configure location package: $e');
    }
  }

  /// Get current position with progressive fallback strategy
  static Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('📍 Getting current position...');

      // Progressive fallback strategy with optimized timeouts
      final accuracyLevels = [
        {
          'accuracy': LocationAccuracy
              .medium, // Start with medium for better reliability
          'timeout': Duration(seconds: 3),
          'name': 'medium',
        },
        {
          'accuracy': LocationAccuracy.low,
          'timeout': Duration(seconds: 2),
          'name': 'low',
        },
        {
          'accuracy': LocationAccuracy.lowest,
          'timeout': Duration(seconds: 1),
          'name': 'lowest',
        },
      ];

      for (final level in accuracyLevels) {
        try {
          debugPrint('📍 Trying ${level['name']} accuracy...');
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: level['accuracy'] as LocationAccuracy,
            timeLimit: level['timeout'] as Duration,
          );
          _currentPosition = position;
          debugPrint('✅ Position obtained with ${level['name']} accuracy');
          return position;
        } catch (e) {
          debugPrint('❌ ${level['name']} accuracy failed: $e');
          // Continue to next accuracy level
        }
      }

      // Try cached location as last resort
      debugPrint('⚠️ All accuracy levels failed, trying cached location...');
      try {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          _currentPosition = position;
          debugPrint('✅ Using cached location');
          return position;
        }
      } catch (e) {
        debugPrint('❌ Cached location failed: $e');
      }

      debugPrint('❌ All location methods failed');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting current position: $e');
      return null;
    }
  }

  /// Start location tracking with optimized settings
  static Future<void> startLocationTracking() async {
    try {
      if (_isTracking) {
        debugPrint('⚠️ Location tracking already active');
        return;
      }

      debugPrint('📍 Starting location tracking...');

      // Get initial position
      final initialPosition = await getCurrentPosition();
      if (initialPosition != null) {
        _onLocationUpdate?.call(initialPosition);
      }

      // Start location stream with optimized settings
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy:
              LocationAccuracy.low, // Use low accuracy for better reliability
          distanceFilter: AppConfig.locationAccuracyThreshold.toInt(),
          timeLimit: Duration(
            seconds: 4,
          ), // Shorter timeout for better responsiveness
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      _lastSuccessfulUpdate = DateTime.now();
      _startHealthCheck();

      debugPrint('✅ Location tracking started successfully');
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  static Future<void> stopLocationTracking() async {
    try {
      debugPrint('📍 Stopping location tracking...');

      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;

      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;

      debugPrint('✅ Location tracking stopped');
    } catch (e) {
      debugPrint('❌ Error stopping location tracking: $e');
    }
  }

  /// Handle location updates
  static void _handleLocationUpdate(Position position) {
    try {
      _currentPosition = position;
      _locationController.add(position);
      _onLocationUpdate?.call(position);
      _lastSuccessfulUpdate = DateTime.now();
      _consecutiveFailures = 0;

      debugPrint(
        '📍 Location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
      );
    } catch (e) {
      debugPrint('❌ Error handling location update: $e');
      _onLocationError?.call('Error processing location update: $e');
    }
  }

  /// Handle location errors with recovery
  static void _handleLocationError(dynamic error) {
    debugPrint('❌ Location error: $error');
    _onLocationError?.call('Location error: $error');

    _consecutiveFailures++;

    if (_consecutiveFailures >= maxConsecutiveFailures) {
      _openCircuitBreaker();
    }

    // Try to recover from timeout errors
    if (error.toString().contains('TimeoutException')) {
      debugPrint('🔄 Attempting to recover from timeout error...');
      _attemptLocationRecovery();
    }
  }

  /// Attempt to recover from location errors
  static void _attemptLocationRecovery() async {
    try {
      debugPrint('🔄 Attempting location recovery...');

      // Stop current tracking completely
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;

      // Wait before restarting to avoid conflicts
      await Future.delayed(Duration(milliseconds: 2000));

      // Try to get a fresh position first
      final freshPosition = await getCurrentPosition();
      if (freshPosition != null) {
        _onLocationUpdate?.call(freshPosition);
      }

      // Restart with lowest accuracy for maximum reliability
      debugPrint('🔄 Restarting with lowest accuracy...');
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.lowest, // Use lowest accuracy for recovery
          distanceFilter: (_fallbackDistanceFilter * 2)
              .toInt(), // Larger distance filter
          timeLimit: Duration(seconds: 2), // Very short timeout
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      debugPrint('✅ Location recovery successful');
    } catch (e) {
      debugPrint('❌ Location recovery failed: $e');
      // Try one more time with cached location
      try {
        final cachedPosition = await Geolocator.getLastKnownPosition();
        if (cachedPosition != null) {
          _currentPosition = cachedPosition;
          _onLocationUpdate?.call(cachedPosition);
          debugPrint('✅ Using cached location as fallback');
        }
      } catch (e2) {
        debugPrint('❌ Cached location also failed: $e2');
      }
    }
  }

  /// Open circuit breaker
  static void _openCircuitBreaker() {
    if (_isCircuitOpen) return;

    _isCircuitOpen = true;
    debugPrint('🔒 Circuit breaker opened due to consecutive failures');

    // Auto-reset after duration
    Timer(circuitBreakerResetDuration, () {
      if (_isCircuitOpen) {
        debugPrint('🔓 Circuit breaker reset, attempting recovery...');
        _isCircuitOpen = false;
        _consecutiveFailures = 0;
        getCurrentPosition();
      }
    });
  }

  /// Start health check timer
  static void _startHealthCheck() {
    _healthCheckTimer?.cancel();

    _healthCheckTimer = Timer.periodic(healthCheckInterval, (timer) {
      final hasRecentPosition =
          _lastSuccessfulUpdate != null &&
          DateTime.now().difference(_lastSuccessfulUpdate!) <
              Duration(minutes: 2);

      debugPrint('🏥 Health check:');
      debugPrint('   Tracking: $_isTracking');
      debugPrint('   Recent position: $hasRecentPosition');
      debugPrint('   Consecutive failures: $_consecutiveFailures');
      debugPrint('   Circuit open: $_isCircuitOpen');

      if (_isTracking && !hasRecentPosition && !_isCircuitOpen) {
        debugPrint('⚠️ Tracking but no recent position - triggering recovery');
        getCurrentPosition();
      }
    });
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// Get coordinates from address
  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return {'latitude': location.latitude, 'longitude': location.longitude};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate bearing between two points
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location is accurate
  static bool isLocationAccurate(Position position) {
    return position.accuracy <= AppConfig.locationAccuracyThreshold;
  }

  /// Get service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'is_initialized': _isInitialized,
      'is_tracking': _isTracking,
      'has_position': _currentPosition != null,
      'consecutive_failures': _consecutiveFailures,
      'circuit_open': _isCircuitOpen,
      'last_successful_update': _lastSuccessfulUpdate?.toIso8601String(),
    };
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    try {
      debugPrint('📍 ConsolidatedLocationService: Disposing...');

      await stopLocationTracking();
      await _locationController.close();

      _retryTimer?.cancel();
      _retryTimer = null;

      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;

      _isInitialized = false;
      _consecutiveFailures = 0;
      _isCircuitOpen = false;

      debugPrint('✅ ConsolidatedLocationService: Disposed');
    } catch (e) {
      debugPrint('❌ ConsolidatedLocationService: Error disposing: $e');
    }
  }
}
