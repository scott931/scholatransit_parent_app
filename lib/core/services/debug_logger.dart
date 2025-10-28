/// Centralized debug logger to eliminate duplicate logging patterns
class DebugLogger {
  /// Log authentication debug information
  static void logAuthDebug(String message) {
    print('🔐 DEBUG: $message');
  }

  /// Log API debug information
  static void logApiDebug(String message) {
    print('📡 DEBUG: $message');
  }

  /// Log token debug information
  static void logTokenDebug(String message) {
    print('🔑 DEBUG: $message');
  }

  /// Log trip debug information
  static void logTripDebug(String message) {
    print('🚌 DEBUG: $message');
  }

  /// Log notification debug information
  static void logNotificationDebug(String message) {
    print('📱 DEBUG: $message');
  }

  /// Log student debug information
  static void logStudentDebug(String message) {
    print('👨‍🎓 DEBUG: $message');
  }

  /// Log location debug information
  static void logLocationDebug(String message) {
    print('📍 DEBUG: $message');
  }

  /// Log communication debug information
  static void logCommunicationDebug(String message) {
    print('💬 DEBUG: $message');
  }

  /// Log API response with standard format
  static void logApiResponse(
    String operation,
    bool success,
    String? error,
    dynamic data,
  ) {
    print('📡 DEBUG: $operation response - Success: $success');
    print('📡 DEBUG: $operation response - Error: $error');
    print('📡 DEBUG: $operation response - Data: $data');
  }

  /// Log detailed API response
  static void logDetailedApiResponse(
    String operation,
    bool success,
    int? statusCode,
    String? error,
    dynamic data,
  ) {
    print('📡 DEBUG: $operation response - Success: $success');
    print('📡 DEBUG: $operation response - Status Code: $statusCode');
    print('📡 DEBUG: $operation response - Error: $error');
    if (data != null && data is Map) {
      print('📡 DEBUG: $operation response - Data keys: ${data.keys.toList()}');
    }
  }

  /// Log authentication token information
  static void logTokenInfo(String? token) {
    if (token != null) {
      print('🔑 DEBUG: Token exists: true');
      print('🔑 DEBUG: Token length: ${token.length}');
      print('🔑 DEBUG: Token preview: ${token.substring(0, 20)}...');
      print(
        '🔑 DEBUG: Token format: ${token.startsWith('eyJ') ? 'Valid JWT' : 'Invalid format'}',
      );
    } else {
      print('🔑 DEBUG: Token exists: false');
    }
  }

  /// Log storage service information
  static void logStorageInfo(String operation, bool success, String? error) {
    print('💾 DEBUG: Storage $operation - Success: $success');
    if (error != null) {
      print('💾 DEBUG: Storage $operation - Error: $error');
    }
  }

  /// Log state change information
  static void logStateChange(String provider, String change) {
    print('🔄 DEBUG: $provider state change: $change');
  }

  /// Log error with context
  static void logError(String context, dynamic error) {
    print('❌ DEBUG: $context error: $error');
  }

  /// Log success with context
  static void logSuccess(String context, String message) {
    print('✅ DEBUG: $context success: $message');
  }

  /// Log warning with context
  static void logWarning(String context, String message) {
    print('⚠️ DEBUG: $context warning: $message');
  }
}
