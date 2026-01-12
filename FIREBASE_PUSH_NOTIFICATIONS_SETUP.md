# Firebase Push Notifications Setup Guide

This document outlines the Firebase Cloud Messaging (FCM) push notification implementation for the GoDrop Parent App.

## ✅ Implementation Complete

Firebase push notifications have been successfully integrated into the application. The following components have been updated:

### 1. Dependencies Added
- `firebase_messaging: ^15.1.3`
- `firebase_core: ^3.6.0`

### 2. Core Service Updates

#### `lib/core/services/notification_service.dart`
- ✅ Integrated Firebase Cloud Messaging
- ✅ Automatic FCM token registration
- ✅ Foreground message handling
- ✅ Background message handling
- ✅ Notification tap handling
- ✅ Topic subscription/unsubscription support
- ✅ Token refresh handling

### 3. Android Configuration

#### `android/app/build.gradle.kts`
- ✅ Added Google Services plugin: `id("com.google.gms.google-services")`

#### `android/build.gradle.kts`
- ✅ Added Google Services classpath dependency

#### `android/app/src/main/AndroidManifest.xml`
- ✅ Added Firebase Messaging Service
- ✅ Added required permissions

### 4. iOS Configuration

#### `ios/Runner/AppDelegate.swift`
- ✅ Imported FirebaseCore and FirebaseMessaging
- ✅ Configured Firebase initialization
- ✅ Set up FCM delegate
- ✅ Configured notification permissions
- ✅ Implemented token refresh handling

### 5. Main App Initialization

#### `lib/main.dart`
- ✅ Added Firebase initialization
- ✅ NotificationService.init() now includes FCM setup

## 📋 Required Setup Steps

### Step 1: Firebase Project Setup

1. **Create/Configure Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing one
   - Enable Cloud Messaging API

2. **Add Android App**
   - In Firebase Console, add Android app
   - Package name: `com.scholatransit.driver.scholatransit_parent_app`
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`

3. **Add iOS App**
   - In Firebase Console, add iOS app
   - Bundle ID: (check your iOS project settings)
   - Download `GoogleService-Info.plist`
   - Place it in: `ios/Runner/GoogleService-Info.plist`
   - Add to Xcode project (drag into Runner folder)

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: iOS Additional Setup

1. **Update Podfile** (if needed)
   - Run `cd ios && pod install`

2. **Enable Push Notifications in Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" → Enable "Remote notifications"

3. **Configure APNs** (for production)
   - Upload APNs Authentication Key or Certificate to Firebase Console
   - Go to Project Settings → Cloud Messaging → Apple app configuration

### Step 4: Android Additional Setup

1. **Verify google-services.json**
   - Ensure `google-services.json` is in `android/app/` directory
   - The build.gradle.kts should automatically apply it

2. **Build and Test**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 🔧 How It Works

### Automatic Token Registration
- FCM token is automatically obtained and registered when the app starts
- Token is sent to your backend via `AppConfig.deviceTokenEndpoint`
- Token refresh is handled automatically

### Message Handling
- **Foreground**: Messages are received and displayed as local notifications
- **Background**: Messages are handled by `firebaseMessagingBackgroundHandler`
- **Terminated**: Messages are handled when app is opened from notification

### Notification Types Supported
- Trip updates
- Emergency alerts
- Student status updates
- ETA notifications
- General notifications

## 📱 Testing Push Notifications

### Using Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter FCM token (check logs for: `📱 FCM Token: ...`)
4. Send test notification

### Using Your Backend API
Send a POST request to your notification endpoint with:
```json
{
  "device_token": "fcm_token_here",
  "title": "Test Notification",
  "body": "This is a test",
  "data": {
    "type": "test"
  }
}
```

## 🔍 Debugging

### Check Logs
Look for these log messages:
- `✅ Firebase initialized successfully`
- `✅ Firebase Messaging initialized successfully`
- `📱 FCM Token: ...`
- `📱 Foreground message received: ...`
- `📱 Background message received: ...`

### Common Issues

1. **Token not generated**
   - Check Firebase initialization logs
   - Verify `google-services.json` / `GoogleService-Info.plist` are correct
   - Check notification permissions are granted

2. **Notifications not received**
   - Verify FCM token is registered with backend
   - Check Firebase Console → Cloud Messaging → Send test message
   - Verify app has notification permissions

3. **iOS notifications not working**
   - Ensure Push Notifications capability is enabled
   - Verify APNs is configured in Firebase Console
   - Check device is registered for remote notifications

## 📚 API Integration

The FCM token is automatically registered with your backend via:
- **Endpoint**: `AppConfig.deviceTokenEndpoint` (`/api/v1/users/device-token/`)
- **Method**: POST
- **Payload**:
  ```json
  {
    "device_token": "fcm_token_here",
    "device_type": "android" | "ios"
  }
  ```

## 🎯 Topic Subscriptions

You can subscribe to topics for targeted notifications:

```dart
await NotificationService.subscribeToTopic('parent_updates');
await NotificationService.unsubscribeFromTopic('parent_updates');
```

## 🔐 Token Management

- Token is automatically refreshed when it changes
- Token is registered on app startup
- Token can be deleted on logout: `NotificationService.deleteToken()`

## 📝 Notes

- Background message handler must be a top-level function
- iOS requires additional setup in Xcode for push notifications
- Android automatically handles notification channels
- Local notifications are still used for displaying FCM messages

## 🚀 Next Steps

1. Add `google-services.json` to `android/app/`
2. Add `GoogleService-Info.plist` to `ios/Runner/`
3. Configure iOS push notifications in Xcode
4. Test with Firebase Console
5. Update backend to send FCM notifications
