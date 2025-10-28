import 'api_service.dart';
import '../config/api_endpoints.dart';

/// Emergency Alerts Fix Service
/// Handles the type casting issue in emergency alerts API
class EmergencyAlertsFix {
  /// Safe emergency alerts API call that avoids type casting issues
  static Future<ApiResponse<Map<String, dynamic>>> getEmergencyAlertsSafe({
    int? limit,
    int? offset,
    String? status,
    String? severity,
  }) async {
    try {
      print('🚨 SAFE EMERGENCY ALERTS API CALL');
      print('=================================');

      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (status != null) queryParams['status'] = status;
      if (severity != null) queryParams['severity'] = severity;

      print('📡 Query Parameters: $queryParams');

      // Use the standard API service but with better error handling
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.emergencyAlerts,
        queryParameters: queryParams,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Success: ${response.success}');
      print('📡 Response Error: ${response.error}');

      if (response.success && response.data != null) {
        print('✅ API call successful');
        print('📊 Response Data Keys: ${response.data!.keys.toList()}');

        // Log the structure for debugging
        _debugResponseStructure(response.data!);

        return response;
      } else {
        print('❌ API call failed: ${response.error}');
        return response;
      }
    } catch (e) {
      print('💥 Emergency alerts API error: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        'Emergency alerts API failed: $e',
      );
    }
  }

  /// Debug the response structure to understand the data format
  static void _debugResponseStructure(Map<String, dynamic> data) {
    print('🔍 EMERGENCY ALERTS RESPONSE STRUCTURE:');
    print('======================================');

    for (final key in data.keys) {
      final value = data[key];
      print('$key: ${value.runtimeType}');

      if (value is List) {
        print('  List length: ${value.length}');
        if (value.isNotEmpty) {
          print('  First item type: ${value.first.runtimeType}');
          if (value.first is Map) {
            print('  First item keys: ${(value.first as Map).keys.toList()}');
          }
        }
      } else if (value is Map) {
        print('  Map keys: ${value.keys.toList()}');
      } else {
        print('  Value: $value');
      }
    }
  }

  /// Test the emergency alerts API with detailed logging
  static Future<void> testEmergencyAlertsAPI() async {
    print('🧪 TESTING EMERGENCY ALERTS API');
    print('===============================');

    final response = await getEmergencyAlertsSafe(limit: 10);

    print('📊 Test Results:');
    print('  - Success: ${response.success}');
    print('  - Status Code: ${response.statusCode}');
    print('  - Error: ${response.error}');

    if (response.success && response.data != null) {
      print('✅ Emergency alerts API is working!');
      print('📊 Data keys: ${response.data!.keys.toList()}');
    } else {
      print('❌ Emergency alerts API failed');
      print('💡 Check authentication and API endpoint');
    }
  }
}
