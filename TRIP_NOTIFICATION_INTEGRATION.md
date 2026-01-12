# Trip Notification Integration Guide

This document describes the notification integration that has been added to the trip provider for sending notifications to parents when trips start and end.

## Overview

The notification system has been integrated into the trip lifecycle to automatically notify parents when:
- A trip starts (`trip_started`)
- A trip completes (`trip_completed`)

## Implementation Details

### 1. Notification Helper Method

A new private method `_sendTripNotifications()` has been added to `TripNotifier` class in `lib/core/providers/trip_provider.dart`:

```dart
Future<void> _sendTripNotifications({
  required Trip trip,
  required String notificationType,
  required String message,
  Map<String, dynamic>? additionalData,
}) async
```

**Features:**
- Automatically loads students for the trip if not already loaded
- Extracts unique parent IDs from students on the trip
- Sends notifications to all parents via `ParentNotificationService.sendTripUpdate()`
- Handles errors gracefully without affecting trip operations
- Provides detailed logging for debugging

### 2. Integration Points

#### Trip Start (`startTrip` method)
- Location: After ETA calculation (line ~334)
- Notification Type: `trip_started`
- Message: "Trip {tripId} has started. Route: {routeName}"

#### Trip End (`endTrip` method)
- Location: After trip list refresh (line ~398)
- Notification Type: `trip_completed`
- Message: "Trip {tripId} has been completed successfully."

### 3. Notification Types Supported

The helper method supports all notification types:
- `trip_started` - Trip has started ✅ (implemented)
- `trip_completed` - Trip finished ✅ (implemented)
- `student_pickup` - Student picked up (ready to use)
- `student_dropoff` - Student dropped off (ready to use)
- `route_delay` - Route delayed (ready to use)
- `emergency_alert` - Emergency (ready to use)
- `eta_update` - ETA changed (ready to use)
- `arrival` - Bus arrived (ready to use)

### 4. Notification Service Initialization

The `NotificationService.init()` is already configured in `lib/main.dart` at line 48:

```dart
// Initialize notification service for local notifications
await NotificationService.init();
```

✅ **Already initialized** - No changes needed.

## Usage Examples

### Sending Custom Trip Notifications

You can use the helper method from anywhere in the `TripNotifier` class:

```dart
// Send student pickup notification
await _sendTripNotifications(
  trip: currentTrip,
  notificationType: 'student_pickup',
  message: 'Your child ${studentName} has been picked up',
  additionalData: {
    'student_id': studentId,
    'pickup_time': DateTime.now().toIso8601String(),
  },
);

// Send route delay notification
await _sendTripNotifications(
  trip: currentTrip,
  notificationType: 'route_delay',
  message: 'Route is running 15 minutes late due to traffic',
  additionalData: {
    'delay_minutes': 15,
    'reason': 'traffic',
  },
);

// Send ETA update
await _sendTripNotifications(
  trip: currentTrip,
  notificationType: 'eta_update',
  message: 'Bus will arrive in 10 minutes',
  additionalData: {
    'eta_minutes': 10,
    'stop_name': 'Main Street Stop',
  },
);
```

## How It Works

1. **Trip Start Flow:**
   ```
   startTrip() 
   → API call to start trip
   → Update trip state
   → Calculate ETA
   → _sendTripNotifications() ← NEW
     → Load students if needed
     → Extract parent IDs
     → Send notifications via API
   ```

2. **Trip End Flow:**
   ```
   endTrip()
   → API call to end trip
   → Update trip state
   → Refresh trips list
   → _sendTripNotifications() ← NEW
     → Load students if needed
     → Extract parent IDs
     → Send notifications via API
   ```

## Notification Data Structure

Each notification includes:

```json
{
  "parent_id": 123,
  "trip_id": 456,
  "update_type": "trip_started",
  "message": "Trip TRP_001 has started. Route: Morning Route A",
  "trip_data": {
    "trip_id": "TRP_001",
    "route_name": "Morning Route A",
    "vehicle_name": "BUS-001",
    "driver_name": "John Doe",
    "start_location": "School Main Gate",
    "end_location": "Downtown Terminal",
    "start_time": "2024-01-15T08:00:00Z",
    "status": "TripStatus.inProgress"
  },
  "timestamp": "2024-01-15T08:00:00Z"
}
```

## Error Handling

- Notifications are sent asynchronously and don't block trip operations
- If notification sending fails, it's logged but doesn't affect trip status
- Individual parent notification failures don't stop other notifications
- Success/failure counts are logged for monitoring

## Testing

To test the notification integration:

1. **Start a trip:**
   ```dart
   await ref.read(tripProvider.notifier).startTrip(
     'TRP_TEST_001',
     startLocation: 'Test Location',
     latitude: -1.2921,
     longitude: 36.8219,
   );
   ```
   - Check logs for: `📱 Trip Provider: Sending trip_started notifications`
   - Verify notifications are sent to parents

2. **End a trip:**
   ```dart
   await ref.read(tripProvider.notifier).endTrip(
     endLocation: 'Test End Location',
     latitude: -1.3000,
     longitude: 36.8300,
   );
   ```
   - Check logs for: `📱 Trip Provider: Sending trip_completed notifications`
   - Verify notifications are sent to parents

## Future Enhancements

Potential improvements:
1. Add notification preferences checking before sending
2. Support for bulk notification API for better performance
3. Add retry logic for failed notifications
4. Add notification delivery status tracking
5. Support for scheduled notifications

## Files Modified

1. **lib/core/providers/trip_provider.dart**
   - Added `_sendTripNotifications()` helper method
   - Integrated notifications into `startTrip()` method
   - Integrated notifications into `endTrip()` method

2. **lib/main.dart**
   - ✅ Already has `NotificationService.init()` - No changes needed

## Related Documentation

- `NOTIFICATION_API_README.md` - General notification API documentation
- `BULK_NOTIFICATION_API_README.md` - Bulk notification API
- `PARENT_NOTIFICATION_SERVICE.dart` - Parent notification service implementation
