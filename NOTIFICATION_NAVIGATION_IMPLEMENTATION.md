# Notification Navigation Implementation

## Overview
This document describes the notification navigation system that allows users to navigate to relevant screens when they tap on push notifications.

## Implementation Details

### 1. Notification Navigation Service
**File**: `lib/core/services/notification_navigation_service.dart`

A centralized service that handles navigation when notifications are tapped. It supports:
- Emergency alerts → Navigate to emergency alert details
- Trip notifications → Navigate to trip details
- Student notifications → Navigate to student details
- General notifications → Navigate to notifications list
- Notification with ID → Navigate to notifications list with highlight

### 2. Notification Tap Handlers

#### FCM Notification Tap Handler
**Location**: `lib/core/services/notification_service.dart` - `_handleNotificationTap()`

Handles navigation when FCM notifications are tapped:
- Extracts notification type and data from `RemoteMessage`
- Calls `NotificationNavigationService.handleNotificationTap()`
- Works for foreground, background, and terminated app states

#### Local Notification Tap Handler
**Location**: `lib/core/services/notification_service.dart` - `_onNotificationTapped()`

Handles navigation when local notifications are tapped:
- Parses notification payload
- Navigates to appropriate screen based on data

### 3. Router Configuration
**File**: `lib/core/router/app_router.dart`

Added routes:
- `/parent/notifications/emergency/:id` - Emergency alert details
- Updated `/parent/notifications` to accept `highlight_notification_id` parameter

### 4. Notifications Screen
**File**: `lib/features/parent/screens/parent_notifications_screen.dart`

Updated to accept `highlightNotificationId` parameter to highlight a specific notification when navigated from a notification tap.

## Navigation Flow

### Emergency Alert Notification
```
Notification Tap → Extract alert_id → Navigate to /parent/notifications/emergency/{id}
```

### Trip Notification
```
Notification Tap → Extract trip_id → Navigate to /trips/details/{id}
```

### Student Notification
```
Notification Tap → Extract student_id → Navigate to /students/{id}
```

### General Notification
```
Notification Tap → Navigate to /parent/notifications
```

### Notification with ID
```
Notification Tap → Extract notification_id → Navigate to /parent/notifications (with highlight)
```

## Notification Data Format

### Emergency Alert
```json
{
  "type": "emergency",
  "alert_id": 123,
  "title": "Emergency Alert",
  "body": "Emergency message"
}
```

### Trip Notification
```json
{
  "type": "trip",
  "trip_id": 456,
  "title": "Trip Update",
  "body": "Trip status changed"
}
```

### Student Notification
```json
{
  "type": "student",
  "student_id": 789,
  "title": "Student Update",
  "body": "Student status changed"
}
```

### General Notification
```json
{
  "type": "general",
  "notification_id": 101,
  "title": "New Notification",
  "body": "Notification message"
}
```

## Usage

### Sending Notifications from Backend

When sending FCM notifications, include the appropriate data fields:

```javascript
// Emergency Alert
{
  notification: {
    title: "Emergency Alert",
    body: "Emergency message"
  },
  data: {
    type: "emergency",
    alert_id: "123"
  }
}

// Trip Update
{
  notification: {
    title: "Trip Update",
    body: "Trip status changed"
  },
  data: {
    type: "trip",
    trip_id: "456"
  }
}
```

### Testing Navigation

1. **Send a test notification** from Firebase Console or your backend
2. **Tap the notification** when it appears
3. **Verify navigation** to the appropriate screen

### Debugging

Check logs for:
- `🧭 Navigating from notification tap` - Navigation service called
- `📱 FCM Notification tapped` - FCM notification tap detected
- `📱 Local notification tapped` - Local notification tap detected
- `✅ Navigated to: /path` - Successful navigation

## App States

### Foreground
- Notification appears as local notification
- Tap handler navigates immediately

### Background
- Notification appears in system tray
- Tap opens app and navigates to relevant screen

### Terminated
- Notification appears in system tray
- Tap opens app, `getInitialMessage()` handles navigation

## Future Enhancements

1. **Deep Linking**: Support for custom URL schemes
2. **Notification Actions**: Add action buttons to notifications
3. **Rich Notifications**: Support for images and expanded layouts
4. **Notification History**: Track notification interactions
5. **Custom Routes**: Allow backend to specify custom navigation paths
