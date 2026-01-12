import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/firestore_location_update.dart';

/// Service for drivers to update their location to Firestore in real-time
class FirestoreDriverLocationService {
  static const String collectionName = 'driver_locations';
  static const Duration minUpdateInterval = Duration(seconds: 10);
  static const double minDistanceMeters = 50.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _locationSubscription;
  final String driverId;
  bool _isTracking = false;

  /// Callback when location is successfully updated
  void Function(FirestoreLocationUpdate)? onLocationUpdated;

  /// Callback when an error occurs
  void Function(String)? onError;

  FirestoreDriverLocationService({required this.driverId});

  /// Check if location tracking is currently active
  bool get isTracking => _isTracking;

  /// Start real-time location updates to Firestore
  Future<void> startLocationUpdates() async {
    if (_isTracking) {
      print('⚠️ Location tracking already started');
      return;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        onError?.call('Location services are disabled. Please enable them.');
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onError?.call('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onError?.call(
          'Location permissions are permanently denied. Please enable them in settings.',
        );
        return;
      }

      // Start listening to location updates
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: minDistanceMeters,
          timeLimit: minUpdateInterval,
        ),
      ).listen(
        (Position position) {
          _updateLocationToFirestore(position);
        },
        onError: (error) {
          onError?.call('Location error: $error');
          print('❌ Location stream error: $error');
        },
        cancelOnError: false,
      );

      _isTracking = true;
      print('✅ Started location tracking for driver: $driverId');
    } catch (e) {
      _isTracking = false;
      onError?.call('Failed to start location updates: $e');
      print('❌ Error starting location updates: $e');
    }
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    print('🛑 Stopped location tracking for driver: $driverId');
  }

  /// Update location to Firestore
  Future<void> _updateLocationToFirestore(Position position) async {
    try {
      final locationUpdate = FirestoreLocationUpdate(
        driverId: driverId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        speed: position.speed >= 0 ? position.speed : null,
        heading: position.heading >= 0 ? position.heading : null,
        accuracy: position.accuracy >= 0 ? position.accuracy : null,
      );

      await _firestore
          .collection(collectionName)
          .doc(driverId)
          .set(locationUpdate.toMap(), SetOptions(merge: true));

      onLocationUpdated?.call(locationUpdate);
      print(
        '✅ Location updated to Firestore: ${locationUpdate.latitude}, '
        '${locationUpdate.longitude}',
      );
    } catch (e) {
      onError?.call('Failed to update location: $e');
      print('❌ Error updating location to Firestore: $e');
    }
  }

  /// Manually update location (useful for testing or one-time updates)
  Future<void> updateLocationManually({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      final locationUpdate = FirestoreLocationUpdate(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        speed: speed,
        heading: heading,
        accuracy: accuracy,
      );

      await _firestore
          .collection(collectionName)
          .doc(driverId)
          .set(locationUpdate.toMap(), SetOptions(merge: true));

      onLocationUpdated?.call(locationUpdate);
      print('✅ Manual location update sent to Firestore');
    } catch (e) {
      onError?.call('Failed to update location manually: $e');
      print('❌ Error in manual location update: $e');
    }
  }

  /// Delete driver location from Firestore (when driver goes offline)
  Future<void> removeLocation() async {
    try {
      await _firestore.collection(collectionName).doc(driverId).delete();
      print('✅ Driver location removed from Firestore');
    } catch (e) {
      onError?.call('Failed to remove location: $e');
      print('❌ Error removing location: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
  }
}
