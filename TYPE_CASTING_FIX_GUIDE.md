# Type Casting Fix Guide

## Problem
The app is showing this error:
```
type '_Map<String, dynamic>' is not a subtype of type 'int'
```

This is a **type casting error** in the API response handling, not an authentication issue.

## Root Cause
The ApiService.get method has automatic type conversion logic that tries to cast API responses to specific types, but when it encounters unexpected data structures, it fails with type casting errors.

## Solutions

### Option 1: Use the Emergency Alerts Fix (Recommended)
Replace the problematic API call with the safe version:

```dart
// Instead of:
final response = await ParentNotificationService.getEmergencyAlerts(limit: 50);

// Use:
final response = await EmergencyAlertsFix.getEmergencyAlertsSafe(limit: 50);
```

### Option 2: Use the API Response Fix
For other API calls with similar issues:

```dart
// Instead of:
final response = await ApiService.get<Map<String, dynamic>>(endpoint);

// Use:
final response = await ApiResponseFix.safeGet(endpoint);
```

### Option 3: Test the Fix
```dart
// Test the emergency alerts API
await EmergencyAlertsFix.testEmergencyAlertsAPI();
```

## Files Created

1. **`lib/core/services/emergency_alerts_fix.dart`** - Safe emergency alerts API calls
2. **`lib/core/services/api_response_fix.dart`** - General API response fixes
3. **Modified `lib/core/services/api_service.dart`** - Added better error handling

## Quick Fix for Emergency Alerts

Replace this in your code:
```dart
// OLD (causing type casting error):
final response = await ParentNotificationService.getEmergencyAlerts(limit: 50);

// NEW (safe version):
final response = await EmergencyAlertsFix.getEmergencyAlertsSafe(limit: 50);
```

## Debug Information

The fix services will show:
- ✅/❌ API call success
- 📊 Response data structure
- 🔍 Detailed debugging information
- 💡 Error diagnosis and solutions

## Prevention

1. **Always use safe API calls** for complex responses
2. **Test API responses** before implementing
3. **Handle type casting errors** gracefully
4. **Use the debug services** to understand response structure

## Common Solutions

| Error | Solution |
|-------|----------|
| `type '_Map<String, dynamic>' is not a subtype of type 'int'` | Use `EmergencyAlertsFix.getEmergencyAlertsSafe()` |
| Type casting errors in other APIs | Use `ApiResponseFix.safeGet()` |
| Unexpected response types | Check response structure with debug services |

The type casting issue is now fixed with safe API call methods that handle response data properly.
