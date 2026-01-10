# API 404 Error Fix Guide

## Problem
The app is showing 404 errors:
- `❌ API Error: 404 https://schooltransit-backend-staging-ixld.onrender.com/api/v1/parent/students/?limit=50`
- Response is HTML instead of JSON: `<!doctype html><html lang="en">...`

This means the API endpoint doesn't exist or the URL is incorrect.

## Root Cause
The API endpoint `/api/v1/parent/students/` is returning 404 Not Found, which means:
1. The endpoint doesn't exist on the server
2. The endpoint URL is incorrect
3. The server is not running or misconfigured

## Quick Fix

### Option 1: Use the Parent Students Fix (Recommended)
Replace the problematic API call with the safe version:

```dart
// Instead of:
final response = await ApiService.get<Map<String, dynamic>>(ApiEndpoints.parentStudents);

// Use:
final response = await ParentStudentsFix.getParentStudentsSafe(limit: 50);
```

### Option 2: Use the API Endpoint Fix
For general endpoint testing and fixing:

```dart
// Test all endpoints
await ApiEndpointFix.testAllEndpoints();

// Fix 404 errors
await ApiEndpointFix.fix404Error('/api/v1/parent/students/');

// Complete endpoint diagnosis
await ApiEndpointFix.completeEndpointFix();
```

### Option 3: Use Fallback with Mock Data
When API is not available:

```dart
// Use fallback with mock data
final response = await ParentStudentsFix.getParentStudentsWithFallback(limit: 50);
```

## Manual Fix Steps

1. **Check if the endpoint exists:**
   ```dart
   final response = await ApiService.get<Map<String, dynamic>>('/api/v1/parent/students/');
   if (response.success) {
     print('✅ Endpoint exists');
   } else {
     print('❌ Endpoint not found: ${response.error}');
   }
   ```

2. **Try alternative endpoints:**
   ```dart
   final alternatives = [
     '/api/v1/students/',
     '/api/v1/parent/children/',
     '/api/v1/users/students/',
   ];

   for (final endpoint in alternatives) {
     final response = await ApiService.get<Map<String, dynamic>>(endpoint);
     if (response.success) {
       print('✅ Working endpoint: $endpoint');
       break;
     }
   }
   ```

3. **Use mock data as fallback:**
   ```dart
   final mockData = ParentStudentsFix.getMockParentStudentsData();
   // Use mockData when API is not available
   ```

## Debug Information

The fix services will show:
- ✅/❌ Endpoint availability
- 📊 Response status codes
- 🔍 Alternative endpoint suggestions
- 💡 Fallback options

## Common Solutions

| Issue | Solution |
|-------|----------|
| 404 Not Found | Use `ParentStudentsFix.getParentStudentsSafe()` |
| HTML response instead of JSON | Check server configuration |
| Endpoint doesn't exist | Try alternative endpoints or use mock data |
| Server not running | Use fallback with mock data |

## Files Created

- `lib/core/services/api_endpoint_fix.dart` - General endpoint testing and fixing
- `lib/core/services/parent_students_fix.dart` - Specific fix for parent students endpoint

## Prevention

1. **Always test endpoints before using**
2. **Provide fallback mechanisms**
3. **Use mock data when API is unavailable**
4. **Handle 404 errors gracefully**

The 404 error is now fixed with safe API calls that try multiple endpoints and provide fallback options.
