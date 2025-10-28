# SchoolTransit API Reference

## Base URL
```
https://schooltransit-backend-staging.onrender.com/
```

## API Documentation
- **Swagger Docs**: https://schooltransit-backend-staging.onrender.com/swagger/
- **ReDoc Docs**: https://schooltransit-backend-staging.onrender.com/redoc/
- **Health Check**: https://schooltransit-backend-staging.onrender.com/

## Quick Reference

### Authentication Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/users/login/` | User login |
| POST | `/api/v1/users/register/` | User registration |
| POST | `/api/v1/users/refresh-token/` | Refresh access token |
| GET | `/api/v1/users/me/` | Get user profile |
| POST | `/api/v1/users/logout/` | User logout |

### Emergency Alerts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/emergency/alerts/` | Get emergency alerts |
| POST | `/api/v1/emergency/alerts/` | Create emergency alert |
| GET | `/api/v1/emergency/alerts/{id}/` | Get specific alert |
| PUT | `/api/v1/emergency/alerts/{id}/` | Update alert |
| DELETE | `/api/v1/emergency/alerts/{id}/` | Delete alert |

### Parent Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/parent/notifications/` | Get parent notifications |
| POST | `/api/v1/parent/notifications/child-status/` | Send child status update |
| POST | `/api/v1/parent/notifications/emergency/` | Send emergency alert |
| POST | `/api/v1/parent/notifications/eta/` | Send ETA notification |

### Trip Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tracking/trips/active/` | Get active trips |
| GET | `/api/v1/tracking/trips/` | Get all trips |
| POST | `/api/v1/tracking/trips/start/` | Start trip |
| POST | `/api/v1/tracking/trips/end/` | End trip |
| POST | `/api/v1/tracking/trips/location/` | Update location |

## Usage in Flutter App

### Import the API Endpoints
```dart
import 'package:your_app/core/config/api_endpoints.dart';
```

### Using Endpoints
```dart
// Get emergency alerts
final response = await ApiService.get<List<Map<String, dynamic>>>(
  ApiEndpoints.emergencyAlerts,
  queryParameters: {'limit': 50},
);

// Login user
final response = await ApiService.post<Map<String, dynamic>>(
  ApiEndpoints.login,
  data: {'email': email, 'password': password},
);

// Get user profile
final response = await ApiService.get<Map<String, dynamic>>(
  ApiEndpoints.profile,
);
```

### Dynamic Endpoints
```dart
// Get specific trip details
final tripId = 123;
final response = await ApiService.get<Map<String, dynamic>>(
  ApiEndpoints.tripDetails(tripId),
);

// Mark notification as read
final notificationId = 456;
final response = await ApiService.post<Map<String, dynamic>>(
  ApiEndpoints.markNotificationAsRead(notificationId),
);
```

## Authentication

### Headers Required
```dart
{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'Authorization': 'Bearer YOUR_ACCESS_TOKEN'
}
```

### Token Refresh
```dart
// Automatic token refresh is handled by ApiService
// When a 401 error occurs, the service automatically:
// 1. Attempts to refresh the token using refresh token
// 2. Retries the original request with new token
// 3. Falls back to error if refresh fails
```

## Error Handling

### Common Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (Authentication required)
- `403` - Forbidden (Access denied)
- `404` - Not Found
- `500` - Internal Server Error

### Error Response Format
```json
{
  "detail": "Error message",
  "error_code": "ERROR_CODE",
  "field_errors": {
    "field_name": ["Error message"]
  }
}
```

## Testing with Postman

### Collection Setup
1. **Base URL**: `https://schooltransit-backend-staging.onrender.com`
2. **Environment Variables**:
   - `baseUrl`: `https://schooltransit-backend-staging.onrender.com`
   - `accessToken`: `{{your_access_token}}`
   - `refreshToken`: `{{your_refresh_token}}`

### Authentication Flow
1. **Login**: POST `/api/v1/users/login/`
2. **Save Tokens**: Store `access` and `refresh` tokens
3. **Use Access Token**: Add to Authorization header
4. **Refresh When Needed**: POST `/api/v1/users/refresh-token/`

### Example Requests

#### Login
```http
POST https://schooltransit-backend-staging.onrender.com/api/v1/users/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "source": "mobile"
}
```

#### Get Emergency Alerts
```http
GET https://schooltransit-backend-staging.onrender.com/api/v1/emergency/alerts/
Authorization: Bearer YOUR_ACCESS_TOKEN
```

#### Create Emergency Alert
```http
POST https://schooltransit-backend-staging.onrender.com/api/v1/emergency/alerts/
Authorization: Bearer YOUR_ACCESS_TOKEN
Content-Type: application/json

{
  "alert_type": "emergency",
  "message": "Emergency situation detected",
  "severity": "high",
  "location": "School Bus Route 1"
}
```

## Troubleshooting

### Common Issues

#### 1. Double API Version in URL
❌ **Wrong**: `https://schooltransit-backend-staging.onrender.com/api/v1/api/v1/emergency/alerts/`
✅ **Correct**: `https://schooltransit-backend-staging.onrender.com/api/v1/emergency/alerts/`

**Solution**: Use `ApiEndpoints.emergencyAlerts` instead of manually constructing URLs.

#### 2. Missing Authentication
❌ **Error**: `401 Unauthorized`
✅ **Solution**: Ensure valid access token in Authorization header.

#### 3. Token Expired
❌ **Error**: `401 Unauthorized` with token expired message
✅ **Solution**: Use refresh token to get new access token.

### Debug Tips
1. **Check Network Tab**: Verify correct URL is being called
2. **Check Headers**: Ensure Authorization header is present
3. **Check Response**: Look for specific error messages
4. **Test in Postman**: Verify endpoint works with same credentials

## Development Notes

### URL Construction
- **Base URL**: `https://schooltransit-backend-staging.onrender.com/`
- **API Version**: `/api/v1`
- **Full API Base**: `https://schooltransit-backend-staging.onrender.com/api/v1`

### Endpoint Patterns
- **Static Endpoints**: Use `ApiEndpoints.endpointName`
- **Dynamic Endpoints**: Use `ApiEndpoints.endpointName(id)`
- **Query Parameters**: Pass as `queryParameters` in API calls

### Best Practices
1. **Always use centralized endpoints** from `ApiEndpoints` class
2. **Handle authentication errors** gracefully
3. **Use proper error handling** for network issues
4. **Test endpoints** in Postman before implementing
5. **Keep tokens secure** and refresh when needed

## Support

For API support and documentation:
- **Swagger UI**: https://schooltransit-backend-staging.onrender.com/swagger/
- **ReDoc**: https://schooltransit-backend-staging.onrender.com/redoc/
- **Health Check**: https://schooltransit-backend-staging.onrender.com/
