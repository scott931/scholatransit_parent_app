import 'api_service.dart';

/// Centralized API response handler to eliminate duplicates
class ApiResponseHandler {
  /// Handle successful API response with data extraction
  static T? handleSuccessResponse<T>(
    ApiResponse<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.success && response.data != null) {
      return fromJson(response.data!);
    }
    return null;
  }

  /// Handle successful API response with list extraction
  static List<T> handleSuccessListResponse<T>(
    ApiResponse<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.success && response.data != null) {
      final data = response.data!;
      final results = data['results'] as List? ?? [];
      return results
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Handle successful API response with direct data return
  static Map<String, dynamic>? handleSuccessDataResponse(
    ApiResponse<Map<String, dynamic>> response,
  ) {
    if (response.success && response.data != null) {
      return response.data!;
    }
    return null;
  }

  /// Handle API response with error logging
  static void logApiResponse(
    String operation,
    ApiResponse<Map<String, dynamic>> response,
  ) {
    print('📡 DEBUG: $operation response - Success: ${response.success}');
    print('📡 DEBUG: $operation response - Error: ${response.error}');
    print('📡 DEBUG: $operation response - Data: ${response.data}');
  }

  /// Handle API response with detailed error logging
  static void logDetailedApiResponse(
    String operation,
    ApiResponse<Map<String, dynamic>> response,
  ) {
    print('📡 DEBUG: $operation response - Success: ${response.success}');
    print(
      '📡 DEBUG: $operation response - Status Code: ${response.statusCode}',
    );
    print('📡 DEBUG: $operation response - Error: ${response.error}');
    if (response.data != null) {
      print(
        '📡 DEBUG: $operation response - Data keys: ${response.data!.keys.toList()}',
      );
    }
  }

  /// Check if response indicates authentication error
  static bool isAuthenticationError(
    ApiResponse<Map<String, dynamic>> response,
  ) {
    return response.error?.contains('401') == true ||
        response.error?.contains('Authentication') == true ||
        response.error?.contains('token') == true ||
        response.error?.contains('credentials') == true;
  }

  /// Check if response indicates network error
  static bool isNetworkError(ApiResponse<Map<String, dynamic>> response) {
    return response.error?.contains('timeout') == true ||
        response.error?.contains('network') == true ||
        response.error?.contains('connection') == true;
  }

  /// Get user-friendly error message
  static String getErrorMessage(ApiResponse<Map<String, dynamic>> response) {
    if (isAuthenticationError(response)) {
      return 'Authentication required. Please log in again.';
    } else if (isNetworkError(response)) {
      return 'Network error. Please check your connection.';
    } else if (response.error != null) {
      return response.error!;
    } else {
      return 'An unexpected error occurred.';
    }
  }
}
