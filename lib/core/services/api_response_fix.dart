import 'api_service.dart';
import '../config/api_endpoints.dart';

/// API Response Fix Service
/// Fixes type casting issues in API responses
class ApiResponseFix {
  /// Safe API call that handles type casting issues
  static Future<ApiResponse<Map<String, dynamic>>> safeGet(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      print('🔧 SAFE API CALL: $endpoint');

      // Use ApiService.get() instead of accessing _dio directly
      final response = await ApiService.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );

      if (!response.success) {
        return response;
      }

      print('📡 Response Status: Success');

      // Handle the response data safely
      Map<String, dynamic> responseData;

      if (response.data != null) {
        if (response.data is Map<String, dynamic>) {
          responseData = response.data!;
          print('✅ Response is Map<String, dynamic>');
        } else if (response.data is Map) {
          // Handle generic Map case
          responseData = Map<String, dynamic>.from(response.data as Map);
          print('✅ Response is generic Map, converted to Map<String, dynamic>');
        } else {
          print('❌ Unexpected response type: ${response.data.runtimeType}');
          return ApiResponse<Map<String, dynamic>>.error(
            'Unexpected response type: ${response.data.runtimeType}',
          );
        }

        print('📊 Response Data Keys: ${responseData.keys.toList()}');
        return ApiResponse<Map<String, dynamic>>.success(responseData);
      } else {
        return ApiResponse<Map<String, dynamic>>.error('Response data is null');
      }
    } catch (e) {
      print('💥 Safe API call error: $e');
      return ApiResponse<Map<String, dynamic>>.error('API call failed: $e');
    }
  }

  /// Safe emergency alerts call
  static Future<ApiResponse<Map<String, dynamic>>> safeGetEmergencyAlerts({
    int? limit,
    int? offset,
    String? status,
    String? severity,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (status != null) queryParams['status'] = status;
    if (severity != null) queryParams['severity'] = severity;

    return safeGet(ApiEndpoints.emergencyAlerts, queryParameters: queryParams);
  }

  /// Debug API response structure
  static void debugResponseStructure(dynamic data) {
    print('🔍 RESPONSE STRUCTURE DEBUG:');
    print('============================');
    print('Data Type: ${data.runtimeType}');

    if (data is Map) {
      print('Map Keys: ${data.keys.toList()}');
      for (final key in data.keys) {
        final value = data[key];
        print('  $key: ${value.runtimeType} = $value');
      }
    } else if (data is List) {
      print('List Length: ${data.length}');
      if (data.isNotEmpty) {
        print('First Item Type: ${data.first.runtimeType}');
        if (data.first is Map) {
          print('First Item Keys: ${(data.first as Map).keys.toList()}');
        }
      }
    } else {
      print('Value: $data');
    }
  }
}
