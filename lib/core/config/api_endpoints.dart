/// API Endpoints Reference
/// Base URL: https://schooltransit-backend-staging-ixld.onrender.com/
///
/// This file contains all API endpoints used in the SchoolTransit app.
/// All endpoints are relative to the base URL to prevent URL confusion.
library;

class ApiEndpoints {
  // Base Configuration
  static const String baseUrl =
      'https://schooltransit-backend-staging-ixld.onrender.com';

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================

  /// POST /api/v1/users/login/
  /// User login endpoint
  static const String login = '/api/v1/users/login/';

  /// POST /api/v1/users/register/
  /// User registration endpoint
  static const String register = '/api/v1/users/register/';

  /// POST /api/v1/users/otp/register/
  /// OTP registration endpoint
  static const String registerOtp = '/api/v1/users/otp/register/';

  /// POST /api/v1/users/otp/register/complete-email/
  /// Complete email registration endpoint
  static const String registerEmailComplete =
      '/api/v1/users/otp/register/complete-email/';

  /// POST /api/v1/users/password/reset/
  /// Request password reset (forgot password) endpoint
  static const String passwordReset = '/api/v1/users/password/reset/';

  /// POST /api/v1/users/password/reset/confirm/
  /// Confirm password reset endpoint
  static const String passwordResetConfirm = '/api/v1/users/password/reset/confirm/';

  /// POST /api/v1/users/logout/
  /// User logout endpoint
  static const String logout = '/api/v1/users/logout/';

  /// POST /api/v1/users/refresh-token/
  /// Token refresh endpoint
  static const String refreshToken = '/api/v1/users/refresh-token/';

  /// GET /api/v1/users/profile/
  /// User profile endpoint
  static const String profile = '/api/v1/users/profile/';

  /// POST /api/v1/users/verify-otp/login/
  /// OTP login verification endpoint
  static const String verifyOtpLogin = '/api/v1/users/verify-otp/login/';

  /// POST /api/v1/users/verify-otp/register/
  /// OTP registration verification endpoint
  static const String verifyOtpRegister = '/api/v1/users/verify-otp/register/';

  /// POST /api/v1/users/otp/resend/
  /// Resend OTP endpoint
  static const String resendOtp = '/api/v1/users/otp/resend/';

  // ============================================================================
  // TRIP MANAGEMENT ENDPOINTS
  // ============================================================================

  /// GET /api/v1/trips/
  /// Get all trips
  static const String trips = '/api/v1/trips/';

  /// GET /api/v1/tracking/trips/active/
  /// Get active trips
  static const String activeTrips = '/api/v1/tracking/trips/active/';

  /// GET /api/v1/tracking/trips/
  /// Get all tracking trips
  static const String allTrips = '/api/v1/tracking/trips/';

  /// GET /api/v1/tracking/trips/
  /// Get trip logs (same endpoint as allTrips but with different filtering)
  static const String tripLogs = '/api/v1/tracking/trips/';

  /// GET /api/v1/tracking/trips/{id}/
  /// Get trip details
  static String tripDetails(int tripId) => '/api/v1/tracking/trips/$tripId/';

  /// GET /api/v1/tracking/trips/driver/
  /// Get driver trips
  static const String driverTrips = '/api/v1/tracking/trips/driver/';

  /// POST /api/v1/tracking/trips/start/
  /// Start a trip
  static const String startTrip = '/api/v1/tracking/trips/start/';

  /// POST /api/v1/tracking/trips/end/
  /// End a trip
  static const String endTrip = '/api/v1/tracking/trips/end/';

  /// POST /api/v1/tracking/trips/location/
  /// Update trip location
  static const String updateLocation = '/api/v1/tracking/trips/location/';

  // ============================================================================
  // PARENT ENDPOINTS
  // ============================================================================

  /// GET /api/v1/students/students/
  /// Get students (using general students endpoint for parents)
  static const String parentStudents = '/api/v1/students/students/';

  /// GET /api/v1/trips/
  /// Get parent's active trips (using general trips endpoint)
  static const String parentActiveTrips = '/api/v1/trips/';

  /// GET /api/v1/trips/
  /// Get parent's trip history (using general trips endpoint)
  static const String parentTripHistory = '/api/v1/trips/';

  // ============================================================================
  // NOTIFICATION ENDPOINTS
  // ============================================================================

  /// GET /api/v1/notifications/
  /// Get driver notifications
  static const String notifications = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Create notification
  static const String createNotification = '/api/v1/notifications/';

  /// GET /api/v1/notifications/preferences/
  /// Get driver notification preferences
  static const String driverNotificationPreferences =
      '/api/v1/notifications/preferences/';

  /// PUT /api/v1/notifications/preferences/
  /// Update driver notification preferences
  static const String updateDriverNotificationPreferences =
      '/api/v1/notifications/preferences/';

  /// POST /api/v1/notifications/{notificationId}/read/
  /// Mark driver notification as read
  static String markDriverNotificationAsRead(int notificationId) =>
      '/api/v1/notifications/$notificationId/read/';

  /// POST /api/v1/notifications/mark-all-read/
  /// Mark all driver notifications as read
  static const String markAllDriverNotificationsAsRead =
      '/api/v1/notifications/mark-all-read/';

  /// POST /api/v1/users/device-token/
  /// Register device for push notifications
  static const String deviceToken = '/api/v1/users/device-token/';

  // ============================================================================
  // PARENT NOTIFICATION ENDPOINTS
  // ============================================================================

  /// GET /api/v1/notifications/
  /// Get parent notifications (using general notifications endpoint)
  static const String parentNotifications = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send child status update notification (using general notifications endpoint)
  static const String childStatusNotification = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send trip update notification (using general notifications endpoint)
  static const String tripUpdateNotification = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send ETA notification (using general notifications endpoint)
  static const String etaNotification = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send delay notification (using general notifications endpoint)
  static const String delayNotification = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send route change notification (using general notifications endpoint)
  static const String routeChangeNotification = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send distance notification (using general notifications endpoint)
  static const String distanceNotification = '/api/v1/notifications/';

  /// POST /api/v1/notifications/
  /// Send arrival notification (using general notifications endpoint)
  static const String arrivalNotification = '/api/v1/notifications/';

  /// GET /api/v1/notifications/preferences/
  /// Get notification preferences (using general notifications endpoint)
  static String notificationPreferences(int parentId) =>
      '/api/v1/notifications/preferences/';

  /// PUT /api/v1/notifications/preferences/
  /// Update notification preferences (using general notifications endpoint)
  static String updateNotificationPreferences(int parentId) =>
      '/api/v1/notifications/preferences/';

  /// POST /api/v1/notifications/{notificationId}/read/
  /// Mark notification as read (using general notifications endpoint)
  static String markNotificationAsRead(int notificationId) =>
      '/api/v1/notifications/$notificationId/read/';

  /// POST /api/v1/notifications/mark-all-read/
  /// Mark all notifications as read (using general notifications endpoint)
  static const String markAllNotificationsAsRead =
      '/api/v1/notifications/mark-all-read/';

  // ============================================================================
  // EMERGENCY ALERT ENDPOINTS
  // ============================================================================

  /// GET /api/v1/emergency/alerts/
  /// Get emergency alerts
  static const String emergencyAlerts = '/api/v1/emergency/alerts/';

  /// POST /api/v1/emergency/alerts/
  /// Create emergency alert
  static const String createEmergencyAlert = '/api/v1/emergency/alerts/';

  /// GET /api/v1/emergency/alerts/{id}/
  /// Get specific emergency alert
  static String emergencyAlertDetails(int alertId) =>
      '/api/v1/emergency/alerts/$alertId/';

  /// PUT /api/v1/emergency/alerts/{id}/
  /// Update emergency alert
  static String updateEmergencyAlert(int alertId) =>
      '/api/v1/emergency/alerts/$alertId/';

  /// DELETE /api/v1/emergency/alerts/{id}/
  /// Delete emergency alert
  static String deleteEmergencyAlert(int alertId) =>
      '/api/v1/emergency/alerts/$alertId/';

  /// POST /api/v1/emergency/alerts/{id}/acknowledge/
  /// Acknowledge emergency alert
  static String acknowledgeEmergencyAlert(int alertId) =>
      '/api/v1/emergency/alerts/$alertId/acknowledge/';

  // ============================================================================
  // GENERAL ALERT/MESSAGE ENDPOINTS
  // ============================================================================

  /// GET /api/v1/alerts/
  /// Get general alerts/messages
  static const String generalAlerts = '/api/v1/alerts/';

  /// POST /api/v1/alerts/
  /// Create general alert/message
  static const String createGeneralAlert = '/api/v1/alerts/';

  /// GET /api/v1/alerts/{id}/
  /// Get specific general alert
  static String generalAlertDetails(int alertId) => '/api/v1/alerts/$alertId/';

  /// PUT /api/v1/alerts/{id}/
  /// Update general alert
  static String updateGeneralAlert(int alertId) => '/api/v1/alerts/$alertId/';

  /// DELETE /api/v1/alerts/{id}/
  /// Delete general alert
  static String deleteGeneralAlert(int alertId) => '/api/v1/alerts/$alertId/';

  /// POST /api/v1/alerts/{id}/acknowledge/
  /// Acknowledge general alert
  static String acknowledgeGeneralAlert(int alertId) =>
      '/api/v1/alerts/$alertId/acknowledge/';

  // ============================================================================
  // ROUTE ENDPOINTS
  // ============================================================================

  /// GET /api/v1/routes/routes/
  /// Get all routes
  static const String routes = '/api/v1/routes/routes/';

  /// GET /api/v1/routes/routes/{id}/
  /// Get specific route details
  static String routeDetails(int routeId) => '/api/v1/routes/routes/$routeId/';

  /// GET /api/v1/routes/routes/{id}/schedules/
  /// Get route schedules
  static String routeSchedules(int routeId) =>
      '/api/v1/routes/routes/$routeId/schedules/';

  // ============================================================================
  // STUDENT ENDPOINTS
  // ============================================================================

  /// GET /api/v1/students/students/
  /// Get all students
  static const String students = '/api/v1/students/students/';

  /// GET /api/v1/students/students/{id}/
  /// Get specific student
  static String studentDetails(int studentId) =>
      '/api/v1/students/students/$studentId/';

  /// POST /api/v1/students/students/
  /// Create student
  static const String createStudent = '/api/v1/students/students/';

  /// PUT /api/v1/students/students/{id}/
  /// Update student
  static String updateStudent(int studentId) =>
      '/api/v1/students/students/$studentId/';

  /// DELETE /api/v1/students/students/{id}/
  /// Delete student
  static String deleteStudent(int studentId) =>
      '/api/v1/students/students/$studentId/';

  /// GET /api/v1/students/status/
  /// Get student status
  static const String studentStatus = '/api/v1/students/status/';

  /// POST /api/v1/tracking/student-status/update/
  /// Update student status
  static const String trackingStudentStatusUpdate =
      '/api/v1/tracking/student-status/update/';

  /// GET /api/v1/attendance/student/{studentId}/
  /// Get student attendance
  static String studentAttendance(int studentId) =>
      '/api/v1/attendance/student/$studentId/';

  /// GET /api/v1/students/{studentId}/trip-status/
  /// Get student's current trip status
  static String studentTripStatus(int studentId) =>
      '/api/v1/students/$studentId/trip-status/';

  /// GET /api/v1/students/{studentId}/route-info/
  /// Get student's route information
  static String studentRouteInfo(int studentId) =>
      '/api/v1/students/$studentId/route-info/';

  /// PUT /api/v1/students/{studentId}/emergency-contact/
  /// Update student's emergency contact information
  static String updateStudentEmergencyContact(int studentId) =>
      '/api/v1/students/$studentId/emergency-contact/';

  /// GET /api/v1/students/{studentId}/attendance/
  /// Get student's attendance history
  static String studentAttendanceHistory(int studentId) =>
      '/api/v1/students/$studentId/attendance/';

  // ============================================================================
  // ATTENDANCE ENDPOINTS
  // ============================================================================

  /// GET /api/v1/attendance/
  /// Get attendance records
  static const String attendance = '/api/v1/attendance/';

  /// POST /api/v1/attendance/mark/
  /// Mark attendance
  static const String markAttendance = '/api/v1/attendance/mark/';

  // ============================================================================
  // COMMUNICATION ENDPOINTS
  // ============================================================================

  /// GET /api/v1/communication/chats/
  /// Get all chats
  static const String chats = '/api/v1/communication/chats/';

  /// POST /api/v1/communication/chats/
  /// Create chat
  static const String createChat = '/api/v1/communication/chats/';

  /// GET /api/v1/communication/chats/{id}/messages/
  /// Get chat messages
  static String chatMessages(int chatId) =>
      '/api/v1/communication/chats/$chatId/messages/';

  /// POST /api/v1/communication/chats/{id}/messages/
  /// Send message
  static String sendMessage(int chatId) =>
      '/api/v1/communication/chats/$chatId/messages/';

  // ============================================================================
  // LOCATION ENDPOINTS
  // ============================================================================

  /// GET /api/v1/location/current/
  /// Get current location
  static const String currentLocation = '/api/v1/location/current/';

  /// POST /api/v1/location/update/
  /// Update location
  static const String updateLocationData = '/api/v1/location/update/';

  // ============================================================================
  // DEVICE ENDPOINTS
  // ============================================================================

  /// POST /api/v1/device/register/
  /// Register device for push notifications
  static const String registerDevice = '/api/v1/device/register/';

  /// POST /api/v1/device/token/
  /// Update device token
  static const String updateDeviceToken = '/api/v1/device/token/';

  // ============================================================================
  // HEALTH CHECK ENDPOINTS
  // ============================================================================

  /// GET /
  /// Health check endpoint
  static const String healthCheck = '/';

  /// GET /api/v1/health/
  /// API health check
  static const String apiHealthCheck = '/api/v1/health/';

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get full URL for an endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Check if endpoint requires authentication
  static bool requiresAuth(String endpoint) {
    final authEndpoints = [
      login,
      register,
      registerOtp,
      registerEmailComplete,
      passwordReset,
      passwordResetConfirm,
      refreshToken,
    ];
    return !authEndpoints.contains(endpoint);
  }

  /// Get endpoint documentation URL
  static String get documentationUrl => '${baseUrl}docs/';

  /// Get Swagger documentation URL
  static String get swaggerUrl => '${baseUrl}swagger/';

  /// Get ReDoc documentation URL
  static String get redocUrl => '${baseUrl}redoc/';
}

/// API Response Status Codes
class ApiStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
}

/// API Error Messages
class ApiErrorMessages {
  static const String networkError = 'Network connection error';
  static const String timeoutError = 'Request timeout';
  static const String serverError = 'Server error';
  static const String unauthorizedError = 'Authentication required';
  static const String forbiddenError = 'Access denied';
  static const String notFoundError = 'Resource not found';
  static const String validationError = 'Validation error';
  static const String unknownError = 'Unknown error occurred';
}
