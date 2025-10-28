# Authentication Fix Guide

## Problem
The app is showing authentication errors:
- `Authentication credentials were not provided`
- `Current auth token status: Missing`
- `No refresh token available for refresh`
- All API calls returning 401 Unauthorized

## Root Cause
The user is not properly authenticated. This happens when:
1. User hasn't completed the full login flow
2. Tokens are missing or expired
3. Authentication data was cleared

## Quick Fix

### Option 1: Use the Debug Widget (Recommended)
Add this to any screen to diagnose and fix auth issues:

```dart
import 'package:your_app/core/widgets/auth_debug_widget.dart';

// Add this widget to any screen
AuthDebugWidget()
```

### Option 2: Use the Debug Service
```dart
import 'package:your_app/core/services/auth_debug_service.dart';

// Check auth status
AuthDebugService.printAuthStatus();

// Test API authentication
await AuthDebugService.testApiAuthentication();

// Clear all auth data (forces re-login)
await AuthDebugService.clearAllAuthData();
```

### Option 3: Use the Fix Script
```dart
import 'package:your_app/core/scripts/fix_auth_issue.dart';

// Run comprehensive auth fix
await fixAuthIssue();

// Quick status check
await checkAuthStatus();
```

## Manual Fix Steps

1. **Check if user is logged in:**
   ```dart
   final authToken = StorageService.getAuthToken();
   if (authToken == null || authToken.isEmpty) {
     // User needs to login
     context.go('/login');
   }
   ```

2. **Force user to login:**
   ```dart
   // Clear all auth data
   await StorageService.clearAuthTokens();
   await StorageService.clearUserProfile();

   // Redirect to login
   context.go('/login');
   ```

3. **Complete the login flow:**
   - Go to login screen
   - Enter email and password
   - Complete OTP verification
   - Tokens will be saved automatically

## Prevention

1. **Always check auth status before API calls:**
   ```dart
   final isAuthenticated = AuthenticationService.isAuthenticated();
   if (!isAuthenticated) {
     // Redirect to login or show login prompt
     return;
   }
   ```

2. **Handle token refresh automatically:**
   ```dart
   final response = await ApiService.get('/some-endpoint');
   if (response.error?.contains('401') == true) {
     // Token expired, try refresh or redirect to login
   }
   ```

3. **Use the authentication service:**
   ```dart
   final isValid = await AuthenticationService.validateAndRefreshAuth(ref);
   if (!isValid) {
     // User needs to login
   }
   ```

## Debug Information

The debug tools will show:
- ✅/❌ Auth Token status
- ✅/❌ Refresh Token status
- ✅/❌ User Profile status
- ✅/❌ API authentication test
- Token previews for debugging

## Common Solutions

| Issue | Solution |
|-------|----------|
| No auth token | User needs to complete login flow |
| No refresh token | User needs to login again |
| API calls failing | Tokens may be expired, try refresh or re-login |
| 401 errors | Check if user is properly authenticated |

## Files Created

- `lib/core/services/auth_debug_service.dart` - Debug service
- `lib/core/widgets/auth_debug_widget.dart` - Debug widget
- `lib/core/scripts/fix_auth_issue.dart` - Fix script

These tools help diagnose and fix authentication issues quickly.
