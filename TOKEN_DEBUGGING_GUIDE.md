# Token Storage and Refresh Debugging Guide

## 🎯 Issues Identified

### **1. Token Not Stored Properly**
- **Problem**: Login process might not be saving tokens correctly
- **Evidence**: Server rejects tokens with "Given token not valid for any token type"

### **2. Token Expired/Invalid**
- **Problem**: Tokens are either expired or not being refreshed properly
- **Evidence**:
  - Refresh token test returns `400 Bad Request: "Token is invalid"`
  - Emergency alerts returns `401 Unauthorized: "Given token not valid for any token type"`

## 🔧 Enhanced Debugging Added

### **1. Token Storage Debugging**
Added to `parent_auth_provider.dart` in `verifyOtp` method:
- ✅ Token presence validation
- ✅ Token length logging
- ✅ Token saving confirmation
- ✅ Response data structure validation

### **2. Token Refresh Debugging**
Enhanced `refreshToken` method:
- ✅ Refresh token validation
- ✅ Refresh request logging
- ✅ Response status and error logging
- ✅ New token saving confirmation

### **3. API Service Token Validation**
Enhanced `_authInterceptor` in `api_service.dart`:
- ✅ JWT format validation
- ✅ Authorization header logging
- ✅ Token format warnings
- ✅ Clear error messages

## 🧪 How to Debug

### **Step 1: Check Token Storage During Login**
1. **Login with OTP** and check console logs for:
```
🔐 DEBUG: Saving authentication tokens...
🔐 Access token: Present (123 chars)
🔐 Refresh token: Present (45 chars)
🔐 DEBUG: Access token saved successfully
🔐 DEBUG: Refresh token saved successfully
```

**If you see:**
```
⚠️ DEBUG: No access token in response!
⚠️ DEBUG: No refresh token in response!
⚠️ DEBUG: No tokens object in response!
```
**Then**: The login API is not returning tokens properly.

### **Step 2: Check Token Format**
Look for these logs when making API calls:
```
✅ API: Valid JWT token format detected
🔐 Token length: 123
🔐 Token preview: eyJhbGciOiJIUzI1NiIs...
```

**If you see:**
```
⚠️ API: Token does not have JWT format: abc123...
```
**Then**: The token is not in the correct JWT format.

### **Step 3: Check Token Refresh**
Look for these logs when token refresh is attempted:
```
🔄 DEBUG: Attempting token refresh...
🔄 DEBUG: Refresh token length: 45
🔄 DEBUG: Refresh token preview: refresh_token_123...
🔄 DEBUG: Token refresh response - Success: true/false
```

**If you see:**
```
🔄 DEBUG: No refresh token available
```
**Then**: The refresh token was not saved during login.

### **Step 4: Check Emergency Alerts API**
Look for these logs when calling emergency alerts:
```
🔐 API: Using authentication token for GET /api/v1/emergency/alerts/
✅ API: Valid JWT token format detected
🔐 Full Authorization header: Bearer eyJhbGciOiJIUzI1NiIs...
```

**If you see:**
```
⚠️ API: No authentication token found for GET /api/v1/emergency/alerts/
⚠️ This will likely result in 401 Unauthorized
```
**Then**: No token is stored or token retrieval is failing.

## 🔍 Common Issues & Solutions

### **Issue 1: No Tokens in Login Response**
**Symptoms:**
```
⚠️ DEBUG: No tokens object in response!
🔐 DEBUG: Response data keys: [parent, user, success]
```

**Solution:**
- Check if the login API endpoint is correct
- Verify the API is returning tokens in the response
- Check if the response structure has changed

### **Issue 2: Invalid Token Format**
**Symptoms:**
```
⚠️ API: Token does not have JWT format: abc123...
```

**Solution:**
- Check if the token is being corrupted during storage
- Verify the token is being saved as a string, not an object
- Check if there are any encoding issues

### **Issue 3: Token Not Being Sent**
**Symptoms:**
```
⚠️ API: No authentication token found for GET /api/v1/emergency/alerts/
```

**Solution:**
- Check if `StorageService.getAuthToken()` is returning null
- Verify the token key is correct in `AppConfig.authTokenKey`
- Check if the token is being cleared somewhere

### **Issue 4: Token Expired**
**Symptoms:**
```
🚨 Emergency Alerts API Response:
  - Success: false
  - Status Code: 401
  - Error: Given token not valid for any token type
```

**Solution:**
- Check if automatic token refresh is working
- Verify the refresh token is valid
- Check if the token expiration time is too short

## 🚀 Testing Steps

### **1. Test Login Process**
1. **Login with OTP** and check console logs
2. **Look for token saving logs** - should see "saved successfully"
3. **Check token format** - should be JWT format starting with "eyJ"

### **2. Test Token Retrieval**
1. **Go to notifications screen** and tap test button
2. **Check token status logs** - should show token exists
3. **Check token format** - should be valid JWT

### **3. Test API Calls**
1. **Make emergency alerts call** and check API service logs
2. **Look for Authorization header** - should show "Bearer eyJ..."
3. **Check response** - should be 200 success or clear error message

### **4. Test Token Refresh**
1. **If token is expired**, check if automatic refresh works
2. **Look for refresh logs** - should show refresh attempt
3. **Check new token** - should be saved successfully

## 📊 Expected Log Output

### **Successful Token Storage:**
```
🔐 DEBUG: Saving authentication tokens...
🔐 Access token: Present (123 chars)
🔐 Refresh token: Present (45 chars)
🔐 DEBUG: Access token saved successfully
🔐 DEBUG: Refresh token saved successfully
```

### **Successful API Call:**
```
🔐 API: Using authentication token for GET /api/v1/emergency/alerts/
✅ API: Valid JWT token format detected
🔐 Token length: 123
🔐 Token preview: eyJhbGciOiJIUzI1NiIs...
🔐 Full Authorization header: Bearer eyJhbGciOiJIUzI1NiIs...
```

### **Failed Token Storage:**
```
⚠️ DEBUG: No tokens object in response!
🔐 DEBUG: Response data keys: [parent, user, success]
```

### **Failed API Call:**
```
⚠️ API: No authentication token found for GET /api/v1/emergency/alerts/
⚠️ This will likely result in 401 Unauthorized
⚠️ User may need to log in again
```

## 🎯 Next Steps

1. **Run the app** and go through the login process
2. **Check the console logs** for token storage debugging
3. **Go to notifications screen** and test emergency alerts
4. **Look for the specific issue** from the enhanced debugging
5. **Apply the appropriate solution** based on the logs

The enhanced debugging will show you exactly where the token storage or refresh is failing! 🔍✨
