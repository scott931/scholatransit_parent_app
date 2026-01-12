# Firestore Real-time Location Sharing - Quick Start Guide

## Overview

This implementation provides real-time location sharing between a Driver app and a Parent app using Cloud Firestore. The Driver app publishes location updates, and the Parent app receives them in real-time.

## Architecture

```
Driver App                    Firestore                    Parent App
    |                            |                            |
    |-- Location Update -------->|                            |
    |                            |-- Real-time Stream ------->|
    |                            |                            |
```

## Files Structure

```
lib/
├── core/
│   ├── models/
│   │   └── firestore_location_update.dart      # Data model
│   └── services/
│       ├── firestore_driver_location_service.dart    # Driver service
│       └── firestore_parent_location_listener.dart   # Parent listener
└── features/
    └── firestore_location_example.dart         # Complete examples
```

## Quick Start

### 1. Driver App - Share Location

```dart
import 'package:flutter/material.dart';
import 'package:your_app/core/services/firestore_driver_location_service.dart';

class DriverScreen extends StatefulWidget {
  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  late FirestoreDriverLocationService _locationService;
  
  @override
  void initState() {
    super.initState();
    _locationService = FirestoreDriverLocationService(
      driverId: 'driver_123', // Your driver ID
    );
    
    _locationService.onLocationUpdated = (location) {
      // Handle location update
      print('Location updated: ${location.latitude}, ${location.longitude}');
    };
    
    _locationService.onError = (error) {
      // Handle error
      print('Error: $error');
    };
  }
  
  Future<void> _startTracking() async {
    await _locationService.startLocationUpdates();
  }
  
  void _stopTracking() {
    _locationService.stopLocationUpdates();
  }
  
  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startTracking,
            child: Text('Start Tracking'),
          ),
          ElevatedButton(
            onPressed: _stopTracking,
            child: Text('Stop Tracking'),
          ),
        ],
      ),
    );
  }
}
```

### 2. Parent App - Receive Location

```dart
import 'package:flutter/material.dart';
import 'package:your_app/core/services/firestore_parent_location_listener.dart';

class ParentScreen extends StatefulWidget {
  @override
  _ParentScreenState createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late FirestoreParentLocationListener _locationListener;
  FirestoreLocationUpdate? _driverLocation;
  
  @override
  void initState() {
    super.initState();
    _locationListener = FirestoreParentLocationListener();
    
    _locationListener.onLocationReceived = (location) {
      setState(() {
        _driverLocation = location;
      });
      // Update map marker, etc.
    };
    
    _locationListener.onLocationRemoved = (driverId) {
      setState(() {
        _driverLocation = null;
      });
    };
    
    _locationListener.onError = (error) {
      print('Error: $error');
    };
  }
  
  void _startListening() {
    _locationListener.listenToDriverLocation('driver_123');
  }
  
  void _stopListening() {
    _locationListener.stopListening();
  }
  
  @override
  void dispose() {
    _locationListener.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_driverLocation != null)
            Text('Lat: ${_driverLocation!.latitude}, '
                 'Lng: ${_driverLocation!.longitude}'),
          ElevatedButton(
            onPressed: _startListening,
            child: Text('Start Listening'),
          ),
          ElevatedButton(
            onPressed: _stopListening,
            child: Text('Stop Listening'),
          ),
        ],
      ),
    );
  }
}
```

## Complete Examples

For complete, runnable examples with maps integration, see:
- `lib/features/firestore_location_example.dart`

This file includes:
- `DriverLocationExample` - Full driver implementation with map
- `ParentLocationTrackingExample` - Full parent implementation with map
- `MultiDriverTrackingExample` - Track multiple drivers

## API Reference

### FirestoreDriverLocationService

**Methods:**
- `startLocationUpdates()` - Start sharing location in real-time
- `stopLocationUpdates()` - Stop sharing location
- `updateLocationManually(lat, lng, ...)` - Manually update location (for testing)
- `removeLocation()` - Remove location from Firestore
- `dispose()` - Clean up resources

**Properties:**
- `isTracking` - Whether location tracking is active
- `onLocationUpdated` - Callback when location is updated
- `onError` - Callback when an error occurs

### FirestoreParentLocationListener

**Methods:**
- `listenToDriverLocation(driverId)` - Listen to a specific driver
- `listenToMultipleDrivers(driverIds)` - Listen to multiple drivers
- `listenToAllActiveDrivers()` - Listen to all active drivers (last 5 minutes)
- `stopListening()` - Stop all listeners
- `getDriverLocation(driverId)` - Get current location (one-time read)
- `getAllActiveDriverLocations()` - Get all active locations (one-time read)
- `dispose()` - Clean up resources

**Properties:**
- `onLocationReceived` - Callback when location is received
- `onLocationRemoved` - Callback when location is removed
- `onError` - Callback when an error occurs

## Data Model

```dart
class FirestoreLocationUpdate {
  final String driverId;
  final double latitude;
  final double longitude;
  final int timestamp;
  final double? speed;
  final double? heading;
  final double? accuracy;
}
```

## Firestore Structure

```
driver_locations/
  └── {driverId}/
      ├── driverId: "driver_123"
      ├── latitude: 37.7749
      ├── longitude: -122.4194
      ├── timestamp: 1234567890
      ├── speed: 15.5 (optional)
      ├── heading: 90.0 (optional)
      └── accuracy: 10.0 (optional)
```

## Security Rules

Add these rules to your Firestore database:

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

## Configuration

### Android

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS

Add to `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to share it with parents</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to share it with parents</string>
```

## Dependencies

Already included in `pubspec.yaml`:
- `cloud_firestore: ^5.4.6`
- `geolocator: ^12.0.0`
- `google_maps_flutter: ^2.6.1` (for map examples)

## Testing

### Manual Testing

1. **Driver App**: Use `updateLocationManually()` to test without GPS
2. **Parent App**: Use `getDriverLocation()` for one-time reads
3. **Firebase Console**: Monitor Firestore in real-time

### Test Locations

```dart
// San Francisco
await _locationService.updateLocationManually(
  latitude: 37.7749,
  longitude: -122.4194,
);

// New York
await _locationService.updateLocationManually(
  latitude: 40.7128,
  longitude: -74.0060,
);
```

## Best Practices

1. **Throttle Updates**: Location updates are automatically throttled (10s interval, 50m distance)
2. **Clean Up**: Always call `dispose()` when done
3. **Error Handling**: Always implement `onError` callbacks
4. **Offline Support**: Firestore handles offline scenarios automatically
5. **Battery Optimization**: The service uses efficient location settings

## Troubleshooting

### No location updates received
- Check Firestore security rules
- Verify Firebase authentication
- Check internet connectivity
- Verify driver ID matches

### Permission errors
- Request location permissions at runtime
- Check AndroidManifest.xml / Info.plist permissions

### High battery drain
- Adjust `minUpdateInterval` and `minDistanceMeters` in service
- Consider using lower accuracy settings

## Next Steps

1. Integrate with your existing app
2. Add map visualization (see examples)
3. Implement driver selection UI
4. Add location history if needed
5. Set up proper Firestore security rules

## Support

For detailed documentation, see:
- `FIRESTORE_REALTIME_SHARING_EXAMPLE.md` - Complete guide with Kotlin/Java examples
- `FIRESTORE_SETUP_GUIDE.md` - Setup instructions
