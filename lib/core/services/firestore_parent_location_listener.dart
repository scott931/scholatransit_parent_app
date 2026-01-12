import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_location_update.dart';

/// Service for parents to listen to real-time driver location updates from Firestore
class FirestoreParentLocationListener {
  static const String collectionName = 'driver_locations';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, StreamSubscription> _driverSubscriptions = {};

  /// Callback when a location update is received
  void Function(FirestoreLocationUpdate)? onLocationReceived;

  /// Callback when a driver's location is removed
  void Function(String driverId)? onLocationRemoved;

  /// Callback when an error occurs
  void Function(String)? onError;

  /// Listen to a specific driver's location updates
  /// 
  /// This is the Flutter equivalent of the Kotlin pattern:
  /// ```kotlin
  /// val docRef = db.collection("locations").document(targetDriverId)
  /// docRef.addSnapshotListener { snapshot, e ->
  ///     if (e != null) { /* handle error */ }
  ///     if (snapshot != null && snapshot.exists()) {
  ///         val locationUpdate = snapshot.toObject(LocationUpdate::class.java)
  ///         // Update UI
  ///     }
  /// }
  /// ```
  /// 
  /// Flutter equivalent:
  /// ```dart
  /// final docRef = db.collection("driver_locations").doc(driverId)
  /// docRef.snapshots().listen(
  ///   (snapshot) {
  ///     if (snapshot.exists && snapshot.data() != null) {
  ///       final locationUpdate = FirestoreLocationUpdate.fromMap(...)
  ///       // Update UI
  ///     }
  ///   },
  ///   onError: (error) { /* handle error */ },
  /// )
  /// ```
  void listenToDriverLocation(String driverId) {
    // Cancel existing subscription for this driver if any
    _driverSubscriptions[driverId]?.cancel();

    final subscription = _firestore
        .collection(collectionName)
        .doc(driverId)
        .snapshots()
        .listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final locationUpdate = FirestoreLocationUpdate.fromMap(
              snapshot.data() as Map<String, dynamic>,
            );
            onLocationReceived?.call(locationUpdate);
            print(
              '📍 Location received for driver $driverId: '
              '${locationUpdate.latitude}, ${locationUpdate.longitude}',
            );
          } catch (e) {
            onError?.call('Error parsing location data for $driverId: $e');
            print('❌ Error parsing location data: $e');
          }
        } else {
          onLocationRemoved?.call(driverId);
          print('⚠️ Driver location removed: $driverId');
        }
      },
      onError: (error) {
        onError?.call('Error listening to driver $driverId: $error');
        print('❌ Error listening to driver $driverId: $error');
      },
    );

    _driverSubscriptions[driverId] = subscription;
    _subscriptions.add(subscription);
  }

  /// Listen to multiple drivers' locations
  void listenToMultipleDrivers(List<String> driverIds) {
    for (String driverId in driverIds) {
      listenToDriverLocation(driverId);
    }
  }

  /// Listen to all active drivers (last 5 minutes)
  void listenToAllActiveDrivers() {
    final fiveMinutesAgo = DateTime.now().millisecondsSinceEpoch - 300000;

    final subscription = _firestore
        .collection(collectionName)
        .where('timestamp', isGreaterThan: fiveMinutesAgo)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) {
        for (var doc in snapshot.docs) {
          if (doc.data() != null) {
            try {
              final locationUpdate = FirestoreLocationUpdate.fromMap(
                doc.data() as Map<String, dynamic>,
              );
              onLocationReceived?.call(locationUpdate);
            } catch (e) {
              onError?.call('Error parsing location data: $e');
              print('❌ Error parsing location data: $e');
            }
          }
        }
      },
      onError: (error) {
        onError?.call('Error listening to active drivers: $error');
        print('❌ Error listening to active drivers: $error');
      },
    );

    _subscriptions.add(subscription);
  }

  /// Stop listening to a specific driver
  void stopListeningToDriver(String driverId) {
    _driverSubscriptions[driverId]?.cancel();
    _driverSubscriptions.remove(driverId);
  }

  /// Stop all listeners
  void stopListening() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _driverSubscriptions.clear();
    print('🛑 Stopped all location listeners');
  }

  /// Get current location for a driver (one-time read)
  Future<FirestoreLocationUpdate?> getDriverLocation(String driverId) async {
    try {
      final doc = await _firestore
          .collection(collectionName)
          .doc(driverId)
          .get();

      if (doc.exists && doc.data() != null) {
        return FirestoreLocationUpdate.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      onError?.call('Error getting driver location: $e');
      print('❌ Error getting driver location: $e');
      return null;
    }
  }

  /// Get all active drivers' locations (one-time read)
  Future<List<FirestoreLocationUpdate>> getAllActiveDriverLocations() async {
    try {
      final fiveMinutesAgo = DateTime.now().millisecondsSinceEpoch - 300000;

      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('timestamp', isGreaterThan: fiveMinutesAgo)
          .get();

      return querySnapshot.docs
          .map((doc) => FirestoreLocationUpdate.fromMap(
                doc.data() as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      onError?.call('Error getting active driver locations: $e');
      print('❌ Error getting active driver locations: $e');
      return [];
    }
  }

  /// Dispose all resources
  void dispose() {
    stopListening();
  }
}

/// ============================================================================
/// SIMPLE STANDALONE EXAMPLE - Direct Kotlin Equivalent
/// ============================================================================
/// 
/// This function shows the simplest possible implementation that directly
/// mirrors the Kotlin/Android pattern:
/// 
/// Kotlin:
/// ```kotlin
/// val db = FirebaseFirestore.getInstance()
/// val targetDriverId = "driver_123"
/// val docRef = db.collection("locations").document(targetDriverId)
/// docRef.addSnapshotListener { snapshot, e ->
///     if (e != null) {
///         Log.w("ParentApp", "Listen failed.", e)
///         return@addSnapshotListener
///     }
///     if (snapshot != null && snapshot.exists()) {
///         val locationUpdate = snapshot.toObject(LocationUpdate::class.java)
///         locationUpdate?.let {
///             Log.d("ParentApp", "Current location: Lat ${it.latitude}, Lon ${it.longitude}")
///             // Update your UI, e.g., move a marker on a map
///         }
///     } else {
///         Log.d("ParentApp", "Current data: null")
///     }
/// }
/// ```
/// 
/// Flutter equivalent:
void listenToDriverLocationSimple(String targetDriverId) {
  // Get a Firestore instance
  final db = FirebaseFirestore.instance;
  
  // Reference to the specific driver's location document
  final docRef = db.collection('driver_locations').doc(targetDriverId);
  
  // Listen for real-time updates
  docRef.snapshots().listen(
    (DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          final locationUpdate = FirestoreLocationUpdate.fromMap(
            snapshot.data() as Map<String, dynamic>,
          );
          print('Current location: Lat ${locationUpdate.latitude}, '
                'Lon ${locationUpdate.longitude}');
          // Update your UI, e.g., move a marker on a map
        } catch (e) {
          print('Error parsing location data: $e');
        }
      } else {
        print('Current data: null');
      }
    },
    onError: (error) {
      print('Listen failed: $error');
    },
  );
}
/// 
/// Usage in a widget:
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   listenToDriverLocationSimple('driver_123');
/// }
/// ```
/// ============================================================================
