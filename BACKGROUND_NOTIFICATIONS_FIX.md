# Background Notifications Fix

## Issues Fixed

### 1. Background Handler Initialization
**Problem**: The background message handler was trying to use `NotificationService.showLocalNotification()` which wasn't available in the background isolate.

**Solution**: 
- The background handler now initializes the `FlutterLocalNotificationsPlugin` directly in the background isolate
- Creates the notification channel in the background handler
- Handles both notification payloads and data-only messages

### 2. Background Handler Registration
**Problem**: The background handler must be registered BEFORE `Firebase.initializeApp()` is called.

**Solution**:
- Moved `FirebaseMessaging.onBackgroundMessage()` registration to `main.dart` before Firebase initialization
- The handler function is imported from `notification_service.dart`

### 3. Android Configuration
**Problem**: Android needs proper configuration for background notifications.

**Solution**:
- Firebase Messaging Service is already configured in `AndroidManifest.xml`
- Notification channel is created with high importance
- All required permissions are present

## How It Works Now

### Foreground Messages
- Handled by `FirebaseMessaging.onMessage.listen()`
- Displayed as local notifications via `NotificationService.showLocalNotification()`

### Background Messages (App in Background)
- Handled by `firebaseMessagingBackgroundHandler` in a separate isolate
- The handler initializes local notifications plugin
- Creates notification channel
- Displays the notification

### Terminated App Messages
- Handled when app is opened from notification
- `FirebaseMessaging.getInitialMessage()` checks if app was opened from notification

## Testing Background Notifications

### Test with Notification Payload
Send from Firebase Console or your backend:
```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This is a test message"
  },
  "data": {
    "type": "test"
  }
}
```

### Test with Data-Only Message
```json
{
  "data": {
    "title": "Data Only",
    "body": "This is a data-only message",
    "type": "test"
  }
}
```

## Important Notes

1. **Android**: When app is in background and message has `notification` payload, Android automatically displays it. The background handler runs for customization or data-only messages.

2. **iOS**: Background notifications require proper APNs configuration in Firebase Console.

3. **Background Handler**: Runs in a separate isolate, so it needs to initialize everything it uses (Firebase, local notifications plugin, etc.).

4. **Notification Channel**: Must be created in both main app and background handler for Android.

## Debugging

Check logs for:
- `📱 Background message received: ...` - Background handler is working
- `✅ Background notification displayed` - Notification was shown
- `📱 FCM Token: ...` - Token is available
- `✅ Firebase Messaging initialized successfully` - FCM is set up

## Common Issues

1. **Notifications not showing in background**
   - Check if notification channel is created (Android)
   - Verify FCM token is registered
   - Check notification permissions
   - Ensure `google-services.json` is correct

2. **Background handler not running**
   - Verify handler is registered before `Firebase.initializeApp()`
   - Check that handler is a top-level function with `@pragma('vm:entry-point')`
   - Ensure app is actually in background (not just minimized)

3. **iOS notifications not working**
   - Verify APNs is configured in Firebase Console
   - Check Push Notifications capability is enabled in Xcode
   - Ensure Background Modes → Remote notifications is enabled
