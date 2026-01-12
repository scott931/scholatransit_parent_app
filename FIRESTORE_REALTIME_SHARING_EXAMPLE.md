# Real-time Data Sharing Between Two Android Apps Using Cloud Firestore

This guide provides complete code examples for real-time location sharing between a "Driver" app and a "Parent" app using Cloud Firestore.

## Table of Contents
1. [Data Models](#data-models)
2. [Android Native Implementation (Kotlin)](#android-native-implementation-kotlin)
3. [Android Native Implementation (Java)](#android-native-implementation-java)
4. [Flutter/Dart Implementation](#flutterdart-implementation)
5. [Firestore Security Rules](#firestore-security-rules)
6. [Setup Instructions](#setup-instructions)

---

## Data Models

### Kotlin Data Class
```kotlin
data class LocationUpdate(
    val driverId: String = "",
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val timestamp: Long = System.currentTimeMillis(),
    val speed: Double? = null,
    val heading: Double? = null,
    val accuracy: Float? = null
) {
    fun toMap(): Map<String, Any> {
        val map = mutableMapOf<String, Any>(
            "driverId" to driverId,
            "latitude" to latitude,
            "longitude" to longitude,
            "timestamp" to timestamp
        )
        speed?.let { map["speed"] = it }
        heading?.let { map["heading"] = it }
        accuracy?.let { map["accuracy"] = it }
        return map
    }

    companion object {
        fun fromMap(map: Map<String, Any>): LocationUpdate {
            return LocationUpdate(
                driverId = map["driverId"] as? String ?: "",
                latitude = (map["latitude"] as? Number)?.toDouble() ?: 0.0,
                longitude = (map["longitude"] as? Number)?.toDouble() ?: 0.0,
                timestamp = (map["timestamp"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                speed = (map["speed"] as? Number)?.toDouble(),
                heading = (map["heading"] as? Number)?.toDouble(),
                accuracy = (map["accuracy"] as? Number)?.toFloat()
            )
        }
    }
}
```

### Java POJO
```java
import java.util.HashMap;
import java.util.Map;

public class LocationUpdate {
    public String driverId;
    public double latitude;
    public double longitude;
    public long timestamp;
    public Double speed;
    public Double heading;
    public Float accuracy;

    // No-argument constructor required for Firestore
    public LocationUpdate() {}

    public LocationUpdate(String driverId, double latitude, double longitude, 
                         long timestamp, Double speed, Double heading, Float accuracy) {
        this.driverId = driverId;
        this.latitude = latitude;
        this.longitude = longitude;
        this.timestamp = timestamp;
        this.speed = speed;
        this.heading = heading;
        this.accuracy = accuracy;
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        map.put("driverId", driverId);
        map.put("latitude", latitude);
        map.put("longitude", longitude);
        map.put("timestamp", timestamp);
        if (speed != null) map.put("speed", speed);
        if (heading != null) map.put("heading", heading);
        if (accuracy != null) map.put("accuracy", accuracy);
        return map;
    }

    public static LocationUpdate fromMap(Map<String, Object> map) {
        LocationUpdate update = new LocationUpdate();
        update.driverId = (String) map.get("driverId");
        update.latitude = ((Number) map.getOrDefault("latitude", 0.0)).doubleValue();
        update.longitude = ((Number) map.getOrDefault("longitude", 0.0)).doubleValue();
        update.timestamp = ((Number) map.getOrDefault("timestamp", System.currentTimeMillis())).longValue();
        if (map.get("speed") != null) {
            update.speed = ((Number) map.get("speed")).doubleValue();
        }
        if (map.get("heading") != null) {
            update.heading = ((Number) map.get("heading")).doubleValue();
        }
        if (map.get("accuracy") != null) {
            update.accuracy = ((Number) map.get("accuracy")).floatValue();
        }
        return update;
    }
}
```

---

## Android Native Implementation (Kotlin)

### 1. Driver App - Location Update Service

```kotlin
import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import androidx.core.app.ActivityCompat
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions

class DriverLocationService(private val context: Context) {
    private val firestore = FirebaseFirestore.getInstance()
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private var locationListener: LocationListener? = null
    private val driverId: String = "driver_123" // Get from authentication
    
    companion object {
        private const val COLLECTION_NAME = "driver_locations"
        private const val MIN_UPDATE_INTERVAL_MS = 10000L // 10 seconds
        private const val MIN_DISTANCE_METERS = 50f // 50 meters
    }

    interface LocationUpdateCallback {
        fun onLocationUpdated(location: LocationUpdate)
        fun onError(error: String)
    }

    private var callback: LocationUpdateCallback? = null

    fun setCallback(callback: LocationUpdateCallback) {
        this.callback = callback
    }

    fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            callback?.onError("Location permissions not granted")
            return
        }

        locationListener = LocationListener { location ->
            updateLocationToFirestore(location)
        }

        locationManager.requestLocationUpdates(
            LocationManager.GPS_PROVIDER,
            MIN_UPDATE_INTERVAL_MS,
            MIN_DISTANCE_METERS,
            locationListener!!
        )
    }

    fun stopLocationUpdates() {
        locationListener?.let {
            locationManager.removeUpdates(it)
            locationListener = null
        }
    }

    private fun updateLocationToFirestore(location: Location) {
        val locationUpdate = LocationUpdate(
            driverId = driverId,
            latitude = location.latitude,
            longitude = location.longitude,
            timestamp = System.currentTimeMillis(),
            speed = if (location.hasSpeed()) location.speed.toDouble() else null,
            heading = if (location.hasBearing()) location.bearing.toDouble() else null,
            accuracy = location.accuracy
        )

        // Use merge to update only specific fields
        firestore.collection(COLLECTION_NAME)
            .document(driverId)
            .set(locationUpdate.toMap(), SetOptions.merge())
            .addOnSuccessListener {
                callback?.onLocationUpdated(locationUpdate)
                println("✅ Location updated to Firestore: ${locationUpdate.latitude}, ${locationUpdate.longitude}")
            }
            .addOnFailureListener { e ->
                callback?.onError("Failed to update location: ${e.message}")
                println("❌ Error updating location: ${e.message}")
            }
    }

    // Manual location update (useful for testing)
    fun updateLocationManually(latitude: Double, longitude: Double) {
        val locationUpdate = LocationUpdate(
            driverId = driverId,
            latitude = latitude,
            longitude = longitude,
            timestamp = System.currentTimeMillis()
        )

        firestore.collection(COLLECTION_NAME)
            .document(driverId)
            .set(locationUpdate.toMap(), SetOptions.merge())
            .addOnSuccessListener {
                callback?.onLocationUpdated(locationUpdate)
            }
            .addOnFailureListener { e ->
                callback?.onError("Failed to update location: ${e.message}")
            }
    }
}
```

### 2. Parent App - Real-time Location Listener

```kotlin
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration

class ParentLocationListener {
    private val firestore = FirebaseFirestore.getInstance()
    private var listenerRegistration: ListenerRegistration? = null
    
    companion object {
        private const val COLLECTION_NAME = "driver_locations"
    }

    interface LocationUpdateCallback {
        fun onLocationReceived(location: LocationUpdate)
        fun onLocationRemoved()
        fun onError(error: String)
    }

    private var callback: LocationUpdateCallback? = null

    fun setCallback(callback: LocationUpdateCallback) {
        this.callback = callback
    }

    /**
     * Listen to a specific driver's location updates
     */
    fun listenToDriverLocation(driverId: String) {
        listenerRegistration = firestore.collection(COLLECTION_NAME)
            .document(driverId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    callback?.onError("Error listening to location: ${error.message}")
                    return@addSnapshotListener
                }

                if (snapshot != null && snapshot.exists()) {
                    val data = snapshot.data
                    if (data != null) {
                        val locationUpdate = LocationUpdate.fromMap(data)
                        callback?.onLocationReceived(locationUpdate)
                    }
                } else {
                    callback?.onLocationRemoved()
                }
            }
    }

    /**
     * Listen to multiple drivers' locations
     */
    fun listenToMultipleDrivers(driverIds: List<String>) {
        driverIds.forEach { driverId ->
            firestore.collection(COLLECTION_NAME)
                .document(driverId)
                .addSnapshotListener { snapshot, error ->
                    if (error != null) {
                        callback?.onError("Error listening to driver $driverId: ${error.message}")
                        return@addSnapshotListener
                    }

                    if (snapshot != null && snapshot.exists()) {
                        val data = snapshot.data
                        if (data != null) {
                            val locationUpdate = LocationUpdate.fromMap(data)
                            callback?.onLocationReceived(locationUpdate)
                        }
                    }
                }
        }
    }

    /**
     * Listen to all active drivers
     */
    fun listenToAllActiveDrivers() {
        listenerRegistration = firestore.collection(COLLECTION_NAME)
            .whereGreaterThan("timestamp", System.currentTimeMillis() - 300000) // Last 5 minutes
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    callback?.onError("Error listening to locations: ${error.message}")
                    return@addSnapshotListener
                }

                snapshot?.documents?.forEach { document ->
                    val data = document.data
                    if (data != null) {
                        val locationUpdate = LocationUpdate.fromMap(data)
                        callback?.onLocationReceived(locationUpdate)
                    }
                }
            }
    }

    fun stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = null
    }
}
```

### 3. Usage Example in Activity/Fragment

```kotlin
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class DriverActivity : AppCompatActivity() {
    private lateinit var locationService: DriverLocationService

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_driver)

        locationService = DriverLocationService(this)
        locationService.setCallback(object : DriverLocationService.LocationUpdateCallback {
            override fun onLocationUpdated(location: LocationUpdate) {
                runOnUiThread {
                    // Update UI with new location
                    updateMapMarker(location)
                }
            }

            override fun onError(error: String) {
                runOnUiThread {
                    // Show error message
                    showError(error)
                }
            }
        })

        locationService.startLocationUpdates()
    }

    override fun onDestroy() {
        super.onDestroy()
        locationService.stopLocationUpdates()
    }

    private fun updateMapMarker(location: LocationUpdate) {
        // Update map with new location
    }

    private fun showError(error: String) {
        // Show error to user
    }
}
```

```kotlin
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class ParentActivity : AppCompatActivity() {
    private lateinit var locationListener: ParentLocationListener

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_parent)

        locationListener = ParentLocationListener()
        locationListener.setCallback(object : ParentLocationListener.LocationUpdateCallback {
            override fun onLocationReceived(location: LocationUpdate) {
                runOnUiThread {
                    // Update map with driver's location
                    updateDriverLocationOnMap(location)
                }
            }

            override fun onLocationRemoved() {
                runOnUiThread {
                    // Driver location no longer available
                    handleDriverLocationRemoved()
                }
            }

            override fun onError(error: String) {
                runOnUiThread {
                    // Show error message
                    showError(error)
                }
            }
        })

        // Listen to specific driver
        val driverId = "driver_123" // Get from your data
        locationListener.listenToDriverLocation(driverId)
    }

    override fun onDestroy() {
        super.onDestroy()
        locationListener.stopListening()
    }

    private fun updateDriverLocationOnMap(location: LocationUpdate) {
        // Update map marker with driver's location
    }

    private fun handleDriverLocationRemoved() {
        // Handle case when driver location is removed
    }

    private fun showError(error: String) {
        // Show error to user
    }
}
```

---

## Android Native Implementation (Java)

### 1. Driver App - Location Update Service

```java
import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import androidx.core.app.ActivityCompat;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;
import java.util.Map;

public class DriverLocationService {
    private static final String COLLECTION_NAME = "driver_locations";
    private static final long MIN_UPDATE_INTERVAL_MS = 10000L; // 10 seconds
    private static final float MIN_DISTANCE_METERS = 50f; // 50 meters

    private FirebaseFirestore firestore;
    private LocationManager locationManager;
    private LocationListener locationListener;
    private String driverId = "driver_123"; // Get from authentication
    private LocationUpdateCallback callback;

    public interface LocationUpdateCallback {
        void onLocationUpdated(LocationUpdate location);
        void onError(String error);
    }

    public DriverLocationService(Context context) {
        this.firestore = FirebaseFirestore.getInstance();
        this.locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
    }

    public void setCallback(LocationUpdateCallback callback) {
        this.callback = callback;
    }

    public void startLocationUpdates(Context context) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) 
                != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) 
                != PackageManager.PERMISSION_GRANTED) {
            if (callback != null) {
                callback.onError("Location permissions not granted");
            }
            return;
        }

        locationListener = new LocationListener() {
            @Override
            public void onLocationChanged(Location location) {
                updateLocationToFirestore(location);
            }

            @Override
            public void onStatusChanged(String provider, int status, Bundle extras) {}

            @Override
            public void onProviderEnabled(String provider) {}

            @Override
            public void onProviderDisabled(String provider) {}
        };

        locationManager.requestLocationUpdates(
            LocationManager.GPS_PROVIDER,
            MIN_UPDATE_INTERVAL_MS,
            MIN_DISTANCE_METERS,
            locationListener
        );
    }

    public void stopLocationUpdates() {
        if (locationListener != null) {
            locationManager.removeUpdates(locationListener);
            locationListener = null;
        }
    }

    private void updateLocationToFirestore(Location location) {
        LocationUpdate locationUpdate = new LocationUpdate(
            driverId,
            location.getLatitude(),
            location.getLongitude(),
            System.currentTimeMillis(),
            location.hasSpeed() ? location.getSpeed() : null,
            location.hasBearing() ? (double) location.getBearing() : null,
            location.getAccuracy()
        );

        firestore.collection(COLLECTION_NAME)
            .document(driverId)
            .set(locationUpdate.toMap(), SetOptions.merge())
            .addOnSuccessListener(aVoid -> {
                if (callback != null) {
                    callback.onLocationUpdated(locationUpdate);
                }
                System.out.println("✅ Location updated to Firestore");
            })
            .addOnFailureListener(e -> {
                if (callback != null) {
                    callback.onError("Failed to update location: " + e.getMessage());
                }
                System.out.println("❌ Error updating location: " + e.getMessage());
            });
    }

    public void updateLocationManually(double latitude, double longitude) {
        LocationUpdate locationUpdate = new LocationUpdate(
            driverId,
            latitude,
            longitude,
            System.currentTimeMillis(),
            null, null, null
        );

        firestore.collection(COLLECTION_NAME)
            .document(driverId)
            .set(locationUpdate.toMap(), SetOptions.merge())
            .addOnSuccessListener(aVoid -> {
                if (callback != null) {
                    callback.onLocationUpdated(locationUpdate);
                }
            })
            .addOnFailureListener(e -> {
                if (callback != null) {
                    callback.onError("Failed to update location: " + e.getMessage());
                }
            });
    }
}
```

### 2. Parent App - Real-time Location Listener

```java
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.DocumentSnapshot;
import java.util.Map;

public class ParentLocationListener {
    private static final String COLLECTION_NAME = "driver_locations";
    
    private FirebaseFirestore firestore;
    private ListenerRegistration listenerRegistration;
    private LocationUpdateCallback callback;

    public interface LocationUpdateCallback {
        void onLocationReceived(LocationUpdate location);
        void onLocationRemoved();
        void onError(String error);
    }

    public ParentLocationListener() {
        this.firestore = FirebaseFirestore.getInstance();
    }

    public void setCallback(LocationUpdateCallback callback) {
        this.callback = callback;
    }

    public void listenToDriverLocation(String driverId) {
        listenerRegistration = firestore.collection(COLLECTION_NAME)
            .document(driverId)
            .addSnapshotListener((snapshot, error) -> {
                if (error != null) {
                    if (callback != null) {
                        callback.onError("Error listening to location: " + error.getMessage());
                    }
                    return;
                }

                if (snapshot != null && snapshot.exists()) {
                    Map<String, Object> data = snapshot.getData();
                    if (data != null) {
                        LocationUpdate locationUpdate = LocationUpdate.fromMap(data);
                        if (callback != null) {
                            callback.onLocationReceived(locationUpdate);
                        }
                    }
                } else {
                    if (callback != null) {
                        callback.onLocationRemoved();
                    }
                }
            });
    }

    public void stopListening() {
        if (listenerRegistration != null) {
            listenerRegistration.remove();
            listenerRegistration = null;
        }
    }
}
```

---

## Flutter/Dart Implementation

### 1. Data Model

```dart
class LocationUpdate {
  final String driverId;
  final double latitude;
  final double longitude;
  final int timestamp;
  final double? speed;
  final double? heading;
  final double? accuracy;

  LocationUpdate({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.heading,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }

  factory LocationUpdate.fromMap(Map<String, dynamic> map) {
    return LocationUpdate(
      driverId: map['driverId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
    );
  }
}
```

### 2. Driver App - Location Update Service

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationService {
  static const String collectionName = 'driver_locations';
  static const Duration minUpdateInterval = Duration(seconds: 10);
  static const double minDistanceMeters = 50.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _locationSubscription;
  final String driverId;

  DriverLocationService({required this.driverId});

  void Function(LocationUpdate)? onLocationUpdated;
  void Function(String)? onError;

  Future<void> startLocationUpdates() async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        onError?.call('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onError?.call('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onError?.call('Location permissions are permanently denied');
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
        },
      );
    } catch (e) {
      onError?.call('Failed to start location updates: $e');
    }
  }

  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _updateLocationToFirestore(Position position) async {
    try {
      final locationUpdate = LocationUpdate(
        driverId: driverId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
      );

      await _firestore
          .collection(collectionName)
          .doc(driverId)
          .set(locationUpdate.toMap(), SetOptions(merge: true));

      onLocationUpdated?.call(locationUpdate);
      print('✅ Location updated to Firestore: ${locationUpdate.latitude}, ${locationUpdate.longitude}');
    } catch (e) {
      onError?.call('Failed to update location: $e');
      print('❌ Error updating location: $e');
    }
  }

  // Manual location update (useful for testing)
  Future<void> updateLocationManually(double latitude, double longitude) async {
    try {
      final locationUpdate = LocationUpdate(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _firestore
          .collection(collectionName)
          .doc(driverId)
          .set(locationUpdate.toMap(), SetOptions(merge: true));

      onLocationUpdated?.call(locationUpdate);
    } catch (e) {
      onError?.call('Failed to update location: $e');
    }
  }
}
```

### 3. Parent App - Real-time Location Listener

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ParentLocationListener {
  static const String collectionName = 'driver_locations';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _locationSubscription;

  void Function(LocationUpdate)? onLocationReceived;
  void Function()? onLocationRemoved;
  void Function(String)? onError;

  /// Listen to a specific driver's location updates
  void listenToDriverLocation(String driverId) {
    _locationSubscription?.cancel();

    _locationSubscription = _firestore
        .collection(collectionName)
        .doc(driverId)
        .snapshots()
        .listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final locationUpdate = LocationUpdate.fromMap(
              snapshot.data() as Map<String, dynamic>,
            );
            onLocationReceived?.call(locationUpdate);
          } catch (e) {
            onError?.call('Error parsing location data: $e');
          }
        } else {
          onLocationRemoved?.call();
        }
      },
      onError: (error) {
        onError?.call('Error listening to location: $error');
      },
    );
  }

  /// Listen to multiple drivers' locations
  void listenToMultipleDrivers(List<String> driverIds) {
    for (String driverId in driverIds) {
      _firestore
          .collection(collectionName)
          .doc(driverId)
          .snapshots()
          .listen(
        (DocumentSnapshot snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            try {
              final locationUpdate = LocationUpdate.fromMap(
                snapshot.data() as Map<String, dynamic>,
              );
              onLocationReceived?.call(locationUpdate);
            } catch (e) {
              onError?.call('Error parsing location data for $driverId: $e');
            }
          }
        },
        onError: (error) {
          onError?.call('Error listening to driver $driverId: $error');
        },
      );
    }
  }

  /// Listen to all active drivers (last 5 minutes)
  void listenToAllActiveDrivers() {
    final fiveMinutesAgo = DateTime.now().millisecondsSinceEpoch - 300000;

    _locationSubscription?.cancel();

    _locationSubscription = _firestore
        .collection(collectionName)
        .where('timestamp', isGreaterThan: fiveMinutesAgo)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) {
        for (var doc in snapshot.docs) {
          if (doc.data() != null) {
            try {
              final locationUpdate = LocationUpdate.fromMap(
                doc.data() as Map<String, dynamic>,
              );
              onLocationReceived?.call(locationUpdate);
            } catch (e) {
              onError?.call('Error parsing location data: $e');
            }
          }
        }
      },
      onError: (error) {
        onError?.call('Error listening to locations: $error');
      },
    );
  }

  void stopListening() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }
}
```

### 4. Usage Example in Flutter Widget

```dart
import 'package:flutter/material.dart';

class DriverScreen extends StatefulWidget {
  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  late DriverLocationService _locationService;
  LocationUpdate? _currentLocation;

  @override
  void initState() {
    super.initState();
    _locationService = DriverLocationService(driverId: 'driver_123');
    _locationService.onLocationUpdated = (location) {
      setState(() {
        _currentLocation = location;
      });
      // Update map marker
    };
    _locationService.onError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    };
    _locationService.startLocationUpdates();
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Driver Location')),
      body: Center(
        child: _currentLocation != null
            ? Text('Lat: ${_currentLocation!.latitude}, Lng: ${_currentLocation!.longitude}')
            : Text('Waiting for location...'),
      ),
    );
  }
}
```

```dart
import 'package:flutter/material.dart';

class ParentScreen extends StatefulWidget {
  @override
  _ParentScreenState createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late ParentLocationListener _locationListener;
  Map<String, LocationUpdate> _driverLocations = {};

  @override
  void initState() {
    super.initState();
    _locationListener = ParentLocationListener();
    _locationListener.onLocationReceived = (location) {
      setState(() {
        _driverLocations[location.driverId] = location;
      });
      // Update map with driver location
    };
    _locationListener.onLocationRemoved = () {
      // Handle driver location removed
    };
    _locationListener.onError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    };

    // Listen to specific driver
    final driverId = 'driver_123'; // Get from your data
    _locationListener.listenToDriverLocation(driverId);
  }

  @override
  void dispose() {
    _locationListener.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Driver')),
      body: ListView.builder(
        itemCount: _driverLocations.length,
        itemBuilder: (context, index) {
          final location = _driverLocations.values.elementAt(index);
          return ListTile(
            title: Text('Driver: ${location.driverId}'),
            subtitle: Text('Lat: ${location.latitude}, Lng: ${location.longitude}'),
          );
        },
      ),
    );
  }
}
```

---

## Firestore Security Rules

Add these rules to your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Driver locations collection
    match /driver_locations/{driverId} {
      // Drivers can write their own location
      allow write: if request.auth != null && 
                     request.auth.uid == driverId;
      
      // Parents can read any driver location (adjust based on your auth logic)
      allow read: if request.auth != null;
      
      // Or restrict to specific parent-driver relationships
      // allow read: if request.auth != null && 
      //              exists(/databases/$(database)/documents/parent_driver_relationships/$(request.auth.uid + '_' + driverId));
    }
  }
}
```

---

## Setup Instructions

### For Android Native (Kotlin/Java)

1. **Add Firebase to your project:**
   - Add to `build.gradle` (project level):
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
   
   - Add to `build.gradle` (app level):
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   
   dependencies {
       implementation 'com.google.firebase:firebase-firestore:24.10.0'
       implementation 'com.google.firebase:firebase-core:21.1.1'
   }
   ```

2. **Add location permissions to AndroidManifest.xml:**
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   ```

3. **Request runtime permissions** (Android 6.0+)

### For Flutter

1. **Add dependencies to `pubspec.yaml`:**
   ```yaml
   dependencies:
     cloud_firestore: ^4.13.6
     firebase_core: ^2.24.2
     geolocator: ^12.0.0
   ```

2. **Run:**
   ```bash
   flutter pub get
   ```

3. **Initialize Firebase in your app:**
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(MyApp());
   }
   ```

4. **Add location permissions** to `AndroidManifest.xml` and `Info.plist` (iOS)

---

## Best Practices

1. **Throttle Updates**: Don't update Firestore on every location change. Use distance and time filters.

2. **Handle Offline**: Firestore automatically handles offline scenarios, but ensure your app gracefully handles connection issues.

3. **Clean Up**: Always remove listeners when activities/fragments/widgets are destroyed.

4. **Error Handling**: Implement robust error handling for network issues, permissions, and Firestore errors.

5. **Security**: Use proper Firestore security rules to control who can read/write location data.

6. **Battery Optimization**: Consider using background location updates sparingly and with appropriate accuracy settings.

7. **Data Retention**: Consider implementing a cleanup mechanism to remove old location data from Firestore.

---

## Testing

You can test the implementation by:

1. **Manual Updates**: Use the `updateLocationManually()` method to simulate location updates
2. **Firebase Console**: Monitor Firestore database in real-time
3. **Multiple Devices**: Run driver app on one device and parent app on another

---

## Troubleshooting

- **No updates received**: Check Firestore security rules and authentication
- **High battery drain**: Increase `minUpdateInterval` and `minDistanceMeters`
- **Permission errors**: Ensure runtime permissions are requested and granted
- **Firestore connection issues**: Check internet connectivity and Firebase configuration
