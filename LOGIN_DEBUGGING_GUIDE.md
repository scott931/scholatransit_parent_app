# Login Issues Debugging Guide

## 🎯 Common Login Problems & Solutions

### **Problem 1: API Endpoint Issues**

#### Symptoms:
- Login fails with network errors
- "Connection timeout" messages
- 404 or 500 server errors

#### Debug Steps:
1. **Check API Base URL**:
   ```dart
   // Current configuration in api_endpoints.dart
   static const String baseUrl = 'https://schooltransit-backend-staging-ixld.onrender.com';
   static const String login = '/api/v1/users/login/';
   ```

2. **Test API Connectivity**:
   ```bash
   # Test if the API server is reachable
   curl -X GET https://schooltransit-backend-staging-ixld.onrender.com/
   ```

3. **Check Login Endpoint**:
   ```bash
   # Test login endpoint directly
   curl -X POST https://schooltransit-backend-staging-ixld.onrender.com/api/v1/users/login/ \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test123","source":"mobile"}'
   ```

#### Solutions:
- Verify the API server is running
- Check if the base URL is correct
- Ensure network connectivity

### **Problem 2: Authentication Token Issues**

#### Symptoms:
- Login succeeds but subsequent API calls fail
- "Invalid credentials" errors after successful login
- "Given token not valid for any token type" errors

#### Debug Steps:
1. **Check Token Storage**:
   Look for these debug logs:
   ```
   🔐 DEBUG: Saving authentication tokens...
   🔐 Access token: Present (123 chars)
   🔐 Refresh token: Present (45 chars)
   ```

2. **Verify Token Format**:
   Look for these logs:
   ```
   ✅ API: Valid JWT token format detected
   🔐 Token length: 123
   🔐 Token preview: eyJhbGciOiJIUzI1NiIs...
   ```

3. **Check Token Usage**:
   Look for these logs:
   ```
   🔐 API: Using authentication token for GET /api/v1/emergency/alerts/
   ```

#### Solutions:
- Clear all stored tokens and try login again
- Check if tokens are being saved correctly
- Verify JWT token format

### **Problem 3: OTP Verification Issues**

#### Symptoms:
- Login redirects to OTP screen but OTP verification fails
- "Invalid OTP" errors
- OTP screen shows but doesn't work

#### Debug Steps:
1. **Check OTP ID Storage**:
   Look for these logs:
   ```
   🔐 DEBUG: OTP required for parent login
   🔐 DEBUG: Found otp_id in delivery_methods: 12345
   ```

2. **Verify OTP Endpoint**:
   ```dart
   // Check if OTP verification endpoint is correct
   static const String verifyOtpLogin = '/api/v1/users/verify-otp/login/';
   ```

#### Solutions:
- Ensure OTP ID is being captured correctly
- Check OTP verification endpoint
- Verify OTP code format

### **Problem 4: Network Connectivity Issues**

#### Symptoms:
- "Connection timeout" errors
- "No internet connection" messages
- Login button doesn't respond

#### Debug Steps:
1. **Check Network Status**:
   ```dart
   // The app checks connectivity using connectivity_plus
   final connectivityResult = await Connectivity().checkConnectivity();
   ```

2. **Test API Timeout**:
   ```dart
   // Current timeout settings
   static const Duration apiTimeout = Duration(seconds: 30);
   static const Duration connectionTimeout = Duration(seconds: 15);
   ```

#### Solutions:
- Check internet connection
- Try different network (WiFi vs Mobile data)
- Increase timeout values if needed

### **Problem 5: Form Validation Issues**

#### Symptoms:
- Login button doesn't work
- Form validation errors
- Email/password format issues

#### Debug Steps:
1. **Check Form Validation**:
   ```dart
   // Email validation regex
   if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
     return 'Please enter a valid email';
   }
   ```

2. **Check Required Fields**:
   - Email field must not be empty
   - Password field must not be empty
   - Email must be valid format

#### Solutions:
- Ensure all required fields are filled
- Check email format is correct
- Verify password is not empty

## 🔧 **Step-by-Step Debugging Process**

### **Step 1: Check Console Logs**
Look for these specific debug messages:

1. **Login Start**:
   ```
   🔐 DEBUG: Starting parent login for email: user@example.com
   🔐 DEBUG: Login endpoint: /api/v1/users/login/
   ```

2. **API Response**:
   ```
   🔐 DEBUG: Parent login response - Success: true/false
   🔐 DEBUG: Parent login response - Error: null/error_message
   🔐 DEBUG: Parent login response - Data: {response_data}
   ```

3. **Token Storage**:
   ```
   🔐 DEBUG: Saving authentication tokens...
   🔐 Access token: Present (123 chars)
   🔐 Refresh token: Present (45 chars)
   ```

### **Step 2: Test API Endpoints**
Use these commands to test the API:

```bash
# Test server health
curl -X GET https://schooltransit-backend-staging-ixld.onrender.com/

# Test login endpoint
curl -X POST https://schooltransit-backend-staging-ixld.onrender.com/api/v1/users/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password",
    "source": "mobile"
  }'
```

### **Step 3: Check Network Configuration**
Verify these settings in your app:

```dart
// In app_config.dart
static const Duration apiTimeout = Duration(seconds: 30);
static const Duration connectionTimeout = Duration(seconds: 15);
static const String baseUrl = 'https://schooltransit-backend-staging-ixld.onrender.com';
```

### **Step 4: Clear App Data**
If tokens are corrupted:

```dart
// Clear all stored data
await StorageService.clearAllData();
await StorageService.forceRefreshAllData();
```

## 🚨 **Quick Fixes**

### **Fix 1: Reset Authentication**
```dart
// Clear all auth data and try login again
await StorageService.clearAuthTokens();
await StorageService.clearUserProfile();
await StorageService.clearDriverId();
```

### **Fix 2: Check Network Connection**
```dart
// Add network check before login
final connectivityResult = await Connectivity().checkConnectivity();
if (connectivityResult.contains(ConnectivityResult.none)) {
  // Show "No internet connection" message
  return;
}
```

### **Fix 3: Increase Timeout**
```dart
// Temporarily increase timeout for testing
static const Duration apiTimeout = Duration(seconds: 60);
static const Duration connectionTimeout = Duration(seconds: 30);
```

## 📱 **Testing Checklist**

- [ ] Check internet connection
- [ ] Verify API server is running
- [ ] Test with valid email/password
- [ ] Check console logs for debug messages
- [ ] Clear app data and try again
- [ ] Test on different network
- [ ] Check if OTP is required
- [ ] Verify token storage

## 🔍 **Common Error Messages & Solutions**

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "Connection timeout" | Network/server issues | Check internet, try different network |
| "Invalid credentials" | Wrong email/password | Verify credentials, check user exists |
| "Token not valid" | Corrupted/expired token | Clear tokens, login again |
| "OTP required" | Two-factor authentication | Complete OTP verification |
| "Server error" | API server issues | Check server status, try later |

## 📞 **Next Steps**

1. **Run the debugging steps above**
2. **Check the console logs** for specific error messages
3. **Test the API endpoints** directly
4. **Clear app data** and try login again
5. **Check network connectivity**

If you're still having issues after following these steps, please share:
- The specific error message you're seeing
- Console logs from the login attempt
- Whether the API server is responding
- Your network connection status
