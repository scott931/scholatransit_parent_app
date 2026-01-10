# Emergency Alerts URL Fix

## 🎯 **Issue Identified and Fixed**

### **The Problem:**
The emergency alerts API was failing with a 404 error due to **double `/api/v1` in the URL**:

```
❌ WRONG URL: https://schooltransit-backend-staging-ixld.onrender.com/api/v1/api/v1/emergency/alerts/
✅ CORRECT URL: https://schooltransit-backend-staging-ixld.onrender.com/api/v1/emergency/alerts/
```

### **Root Cause:**
The `ApiEndpoints.emergencyAlerts` was defined as `/api/v1/emergency/alerts/` but should be `/emergency/alerts/` because the `ApiService` already adds the base URL with `/api/v1`.

### **🔧 Fix Applied:**

Updated the following endpoints in `api_endpoints.dart`:

```dart
// BEFORE (causing double /api/v1)
static const String emergencyAlerts = '/api/v1/emergency/alerts/';
static const String createEmergencyAlert = '/api/v1/emergency/alerts/';
static String emergencyAlertDetails(int alertId) => '/api/v1/emergency/alerts/$alertId/';
static String updateEmergencyAlert(int alertId) => '/api/v1/emergency/alerts/$alertId/';
static String deleteEmergencyAlert(int alertId) => '/api/v1/emergency/alerts/$alertId/';

// AFTER (correct)
static const String emergencyAlerts = '/emergency/alerts/';
static const String createEmergencyAlert = '/emergency/alerts/';
static String emergencyAlertDetails(int alertId) => '/emergency/alerts/$alertId/';
static String updateEmergencyAlert(int alertId) => '/emergency/alerts/$alertId/';
static String deleteEmergencyAlert(int alertId) => '/emergency/alerts/$alertId/';
```

### **✅ Expected Result:**

Now when you test the emergency alerts API, you should see:

```
🚀 API Request: GET https://schooltransit-backend-staging-ixld.onrender.com/api/v1/emergency/alerts/?limit=10
📤 Headers: {Authorization: Bearer eyJhbGciOiJIUzI1NiIs...}
📥 Response: 200 OK
🚨 Emergency Alerts API Response:
  - Success: true
  - Status Code: 200
  - Data: [list of emergency alerts]
```

### **🧪 Test the Fix:**

1. **Hot reload** your app (or restart if needed)
2. **Go to notifications screen**
3. **Tap the purple "Test API" button**
4. **Check the console logs** - you should now see a 200 success response!

### **📊 What Changed:**

- **Before**: URL had double `/api/v1` → 404 Not Found
- **After**: URL has single `/api/v1` → 200 Success with emergency alerts data

The emergency alerts should now load successfully! 🎉✨
