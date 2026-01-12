# Firestore Real-time Location Sharing - Quick Setup Guide

This guide will help you set up real-time location sharing between Driver and Parent apps using Cloud Firestore.

## Files Created

1. **`lib/core/models/firestore_location_update.dart`** - Data model for location updates
2. **`lib/core/services/firestore_driver_location_service.dart`** - Service for drivers to update location
3. **`lib/core/services/firestore_parent_location_listener.dart`** - Service for parents to listen to driver locations
4. **`lib/features/firestore_location_example.dart`** - Example widgets showing usage
5. **`FIRESTORE_REALTIME_SHARING_EXAMPLE.md`** - Comprehensive documentation with Android native examples

## Quick Start

### 1. Install Dependencies

The `cloud_firestore` package has been added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

### 2. Initialize Firebase

Make sure Firebase is initialized in your app. In your `main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### 3. Driver App - Update Location

```dart
import 'package:your_app/core/services/firestore_driver_location_service.dart';

// Create service instance
final locationService = FirestoreDriverLocationService(
  driverId: 'driver_123', // Get from your auth system
);

// Set callbacks
locationService.onLocationUpdated = (location) {
  print('Location updated: ${location.latitude}, ${location.longitude}');
  // Update your UI or map
};

locationService.onError = (error) {
  print('Error: $error');
};

// Start tracking
await locationService.startLocationUpdates();

// Stop tracking when done
locationService.stopLocationUpdates();
```

### 4. Parent App - Listen to Location

```dart
import 'package:your_app/core/services/firestore_parent_location_listener.dart';

// Create listener instance
final locationListener = FirestoreParentLocationListener();

// Set callbacks
locationListener.onLocationReceived = (location) {
  print('Driver location: ${location.latitude}, ${location.longitude}');
  // Update your map marker
};

locationListener.onLocationRemoved = (driverId) {
  print('Driver $driverId location removed');
};

locationListener.onError = (error) {
  print('Error: $error');
};

// Start listening to a specific driver
locationListener.listenToDriverLocation('driver_123');

// Stop listening when done
locationListener.stopListening();
```

### 5. Firestore Security Rules

Add these rules to your Firestore console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /driver_locations/{driverId} {
      // Drivers can write their own location
      allow write: if request.auth != null && 
                     request.auth.uid == driverId;
      
      // Parents can read any driver location
      allow read: if request.auth != null;
    }
  }
}
```

## Example Usage

See `lib/features/firestore_location_example.dart` for complete working examples:

- `DriverLocationExample` - Widget for driver app
- `ParentLocationTrackingExample` - Widget for parent app

## Key Features

✅ **Real-time Updates** - Automatic location sync via Firestore listeners  
✅ **Throttling** - Built-in distance and time filters to save battery  
✅ **Error Handling** - Comprehensive error callbacks  
✅ **Multiple Drivers** - Listen to multiple drivers simultaneously  
✅ **Offline Support** - Firestore handles offline scenarios automatically  

## Testing

1. Run the driver app on one device/emulator
2. Run the parent app on another device/emulator
3. Start location tracking in the driver app
4. Start listening in the parent app
5. Watch locations update in real-time!

## Troubleshooting

- **No updates received**: Check Firestore security rules and authentication
- **Permission errors**: Ensure location permissions are granted
- **Firestore connection issues**: Verify Firebase configuration files are correct

## Next Steps

1. Integrate with your existing authentication system
2. Add map markers using `google_maps_flutter` or `mapbox_maps_flutter`
3. Customize update intervals based on your needs
4. Add additional fields to `FirestoreLocationUpdate` model if needed

For detailed Android native (Kotlin/Java) examples, see `FIRESTORE_REALTIME_SHARING_EXAMPLE.md`.
