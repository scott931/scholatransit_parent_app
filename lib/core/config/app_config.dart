class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://your-api-url.com';
  static const String apiVersion = '/api/v1';
  static const String fullApiUrl = '$baseUrl$apiVersion';

  // App Information
  static const String appName = 'ScholaTransit Parent App';
  static const String appVersion = '1.0.0';

  // Authentication
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // API Endpoints
  static const String loginEndpoint = '/auth/login/';
  static const String logoutEndpoint = '/auth/logout/';
  static const String refreshEndpoint = '/auth/refresh/';
  static const String profileEndpoint = '/auth/profile/';

  // Trip Management
  static const String tripsEndpoint = '/trips/';
  static const String activeTripsEndpoint = '/trips/active/';
  static const String startTripEndpoint = '/trips/start/';
  static const String endTripEndpoint = '/trips/end/';
  static const String locationEndpoint = '/trips/location/';

  // Student Management
  static const String studentsEndpoint = '/students/';
  static const String studentStatusEndpoint = '/students/status/';
  static const String attendanceEndpoint = '/students/attendance/';

  // Notifications
  static const String notificationsEndpoint = '/notifications/';
  static const String notificationPreferencesEndpoint =
      '/notifications/preferences/';

  // Communication
  static const String chatsEndpoint = '/communication/chats/';
  static const String messagesEndpoint = '/communication/messages/';

  // Emergency
  static const String emergencyAlertsEndpoint = '/emergency/alerts/';
  static const String acknowledgeEmergencyEndpoint = '/emergency/acknowledge/';

  // Debug Settings
  static const bool enableLogging = true;
  static const bool enableDebugMode = true;

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
