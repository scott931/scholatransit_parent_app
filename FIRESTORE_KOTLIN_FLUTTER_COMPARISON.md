# Firestore Real-time Updates: Kotlin vs Flutter Comparison

This document shows the direct equivalence between Kotlin/Android and Flutter/Dart implementations for listening to real-time Firestore updates.

## Parent App - Listening for Real-time Updates

### Kotlin/Android Implementation

```kotlin
// Get a Firestore instance
val db = FirebaseFirestore.getInstance()

// Assume you know the driverId you want to track
val targetDriverId = "driver_123"

// Reference to the specific driver's location document
val docRef = db.collection("locations").document(targetDriverId)

// Listen for real-time updates
docRef.addSnapshotListener { snapshot, e ->
    if (e != null) {
        Log.w("ParentApp", "Listen failed.", e)
        return@addSnapshotListener
    }

    if (snapshot != null && snapshot.exists()) {
        val locationUpdate = snapshot.toObject(LocationUpdate::class.java)
        locationUpdate?.let {
            Log.d("ParentApp", "Current location: Lat ${it.latitude}, Lon ${it.longitude}")
            // Update your UI, e.g., move a marker on a map
        }
    } else {
        Log.d("ParentApp", "Current data: null")
    }
}
```

### Flutter/Dart Equivalent

```dart
// Get a Firestore instance
final db = FirebaseFirestore.instance;

// Assume you know the driverId you want to track
final targetDriverId = "driver_123";

// Reference to the specific driver's location document
final docRef = db.collection("driver_locations").doc(targetDriverId);

// Listen for real-time updates
docRef.snapshots().listen(
  (DocumentSnapshot snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      final locationUpdate = FirestoreLocationUpdate.fromMap(
        snapshot.data() as Map<String, dynamic>,
      );
      print('Current location: Lat ${locationUpdate.latitude}, '
            'Lon ${locationUpdate.longitude}');
      // Update your UI, e.g., move a marker on a map
    } else {
      print('Current data: null');
    }
  },
  onError: (error) {
    print('Listen failed: $error');
  },
);
```

## Direct Mapping

| Kotlin/Android | Flutter/Dart | Description |
|----------------|--------------|-------------|
| `FirebaseFirestore.getInstance()` | `FirebaseFirestore.instance` | Get Firestore instance |
| `db.collection("locations")` | `db.collection("driver_locations")` | Reference collection |
| `.document(targetDriverId)` | `.doc(targetDriverId)` | Reference document |
| `.addSnapshotListener { ... }` | `.snapshots().listen(...)` | Listen for real-time updates |
| `snapshot.exists()` | `snapshot.exists` | Check if document exists |
| `snapshot.toObject(LocationUpdate::class.java)` | `FirestoreLocationUpdate.fromMap(snapshot.data())` | Parse data to model |
| `e != null` (error check) | `onError: (error) { ... }` | Handle errors |

## Our Service Implementation

Our `FirestoreParentLocationListener` service wraps this pattern with additional features:

```dart
class FirestoreParentLocationListener {
  // Equivalent to the Kotlin example
  void listenToDriverLocation(String driverId) {
    _firestore
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
          } catch (e) {
            onError?.call('Error parsing location data: $e');
          }
        } else {
          onLocationRemoved?.call(driverId);
        }
      },
      onError: (error) {
        onError?.call('Error listening to driver $driverId: $error');
      },
    );
  }
}
```

## Usage Comparison

### Kotlin/Android Usage

```kotlin
class ParentActivity : AppCompatActivity() {
    private var listenerRegistration: ListenerRegistration? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val docRef = db.collection("locations").document("driver_123")
        listenerRegistration = docRef.addSnapshotListener { snapshot, e ->
            // Handle updates
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        listenerRegistration?.remove()
    }
}
```

### Flutter/Dart Usage

```dart
class ParentScreen extends StatefulWidget {
  @override
  _ParentScreenState createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late FirestoreParentLocationListener _locationListener;
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _locationListener = FirestoreParentLocationListener();
    _locationListener.onLocationReceived = (location) {
      // Handle updates
    };
    _locationListener.listenToDriverLocation("driver_123");
  }
  
  @override
  void dispose() {
    _locationListener.dispose();
    super.dispose();
  }
}
```

## Key Differences

1. **Error Handling**: 
   - Kotlin: Error passed as parameter in lambda
   - Flutter: Error handled via `onError` callback

2. **Data Parsing**:
   - Kotlin: Uses `toObject()` with reflection
   - Flutter: Uses `fromMap()` factory method

3. **Lifecycle Management**:
   - Kotlin: Returns `ListenerRegistration` to cancel
   - Flutter: Returns `StreamSubscription` to cancel

4. **Null Safety**:
   - Kotlin: Uses nullable types and safe calls (`?.`)
   - Flutter: Uses null safety and optional chaining

## Collection Name Note

The Kotlin example uses `"locations"` while our Flutter implementation uses `"driver_locations"`. Both work the same way - just ensure consistency across your apps:

```dart
// In FirestoreParentLocationListener
static const String collectionName = 'driver_locations'; // or 'locations'
```

## Complete Example

See `lib/features/firestore_location_example.dart` for a complete, runnable example that demonstrates this pattern with:
- Real-time updates
- Error handling
- UI updates
- Map integration
- Lifecycle management
