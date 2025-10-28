# Emergency Alerts Debug Guide

## 🎯 Issue
Emergency alerts API `/api/v1/emergency/alerts/` returns 401 Unauthorized even when user is logged in.

## 🔍 Enhanced Debugging Added

### 1. **Parent Provider Debugging**
Added detailed logging to `parent_provider.dart`:
- ✅ Token existence check
- ✅ Token length and preview
- ✅ Detailed error response logging
- ✅ Status code logging

### 2. **API Service Debugging**
Enhanced `api_service.dart` with:
- ✅ Token validation logging
- ✅ Authorization header logging
- ✅ Token preview for debugging
- ✅ Clear warnings for missing tokens

### 3. **Notifications Screen Debugging**
Enhanced test button in `parent_notifications_screen.dart`:
- ✅ Authentication state check
- ✅ Token status verification
- ✅ Direct API call testing
- ✅ Comprehensive response logging

## 🧪 How to Debug

### **Step 1: Check Authentication Status**
Run the app and go to the notifications screen. Look for these debug messages:

```
🔐 Auth State:
  - Is authenticated: true/false
  - Parent: true/false
  - Loading: true/false
  - Error: null/error_message

🔐 Token Status:
  - Token exists: true/false
  - Token length: 123
  - Token preview: eyJhbGciOiJIUzI1NiIs...
```

### **Step 2: Check API Service Logs**
Look for these messages when making API calls:

```
🔐 API: Using authentication token for GET /api/v1/emergency/alerts/
🔐 Token length: 123
🔐 Token preview: eyJhbGciOiJIUzI1NiIs...
```

OR

```
⚠️ API: No authentication token found for GET /api/v1/emergency/alerts/
⚠️ This will likely result in 401 Unauthorized
```

### **Step 3: Check Emergency Alerts Response**
Look for these detailed logs:

```
🚨 Emergency Alerts API Response:
  - Success: true/false
  - Status Code: 200/401/500
  - Data: [list of alerts or null]
  - Error: null/error_message
```

## 🔧 Possible Issues & Solutions

### **Issue 1: No Token Stored**
**Symptoms:**
- `Token exists: false`
- `⚠️ API: No authentication token found`

**Solution:**
- Check if login process properly saves token
- Verify `StorageService.saveAuthToken()` is called after OTP verification

### **Issue 2: Token Expired**
**Symptoms:**
- `Token exists: true`
- `Success: false`
- `Status Code: 401`
- `Error: Authentication credentials were not provided`

**Solution:**
- Check if token refresh is working
- Verify token format is correct

### **Issue 3: Wrong Token Format**
**Symptoms:**
- `Token exists: true`
- `Success: false`
- `Status Code: 401`

**Solution:**
- Check token format in logs
- Verify it starts with proper JWT format

### **Issue 4: API Endpoint Issue**
**Symptoms:**
- `Token exists: true`
- `Success: false`
- `Status Code: 404`

**Solution:**
- Verify endpoint URL is correct
- Check if API endpoint exists

## 🚀 Testing Steps

### **1. Test Authentication**
1. Go to notifications screen
2. Tap the purple "Test Emergency Alerts" button
3. Check console logs for authentication status

### **2. Test API Call**
1. Look for API service logs
2. Check if Authorization header is being sent
3. Verify response status and data

### **3. Test Token Refresh**
1. If token is expired, check if automatic refresh works
2. Look for refresh token logs
3. Verify new token is saved

## 📊 Expected Log Output

### **Successful Authentication:**
```
🔐 Auth State:
  - Is authenticated: true
  - Parent: true
  - Loading: false
  - Error: null

🔐 Token Status:
  - Token exists: true
  - Token length: 123
  - Token preview: eyJhbGciOiJIUzI1NiIs...

🔐 API: Using authentication token for GET /api/v1/emergency/alerts/
🔐 Token length: 123
🔐 Token preview: eyJhbGciOiJIUzI1NiIs...

🚨 Emergency Alerts API Response:
  - Success: true
  - Status Code: 200
  - Data: [list of alerts]
  - Error: null

✅ Emergency alerts loaded successfully!
📊 Data count: 5
```

### **Failed Authentication:**
```
🔐 Auth State:
  - Is authenticated: false
  - Parent: false
  - Loading: false
  - Error: null

🔐 Token Status:
  - Token exists: false

⚠️ API: No authentication token found for GET /api/v1/emergency/alerts/
⚠️ This will likely result in 401 Unauthorized

🚨 Emergency Alerts API Response:
  - Success: false
  - Status Code: 401
  - Data: null
  - Error: Authentication credentials were not provided

❌ Emergency alerts failed to load
```

## 🎯 Next Steps

1. **Run the app** and go to notifications screen
2. **Tap the test button** and check console logs
3. **Identify the issue** based on the log output
4. **Apply the appropriate solution** from the issues above

The enhanced debugging will show exactly where the authentication is failing! 🔍✨
