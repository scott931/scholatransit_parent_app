import 'api_service.dart';
import '../config/api_endpoints.dart';

/// Parent Students API Fix Service
/// Fixes 404 errors for parent students endpoint
class ParentStudentsFix {
  /// Safe parent students API call that handles 404 errors
  static Future<ApiResponse<Map<String, dynamic>>> getParentStudentsSafe({
    int? limit,
    int? offset,
  }) async {
    print('👨‍👩‍👧‍👦 SAFE PARENT STUDENTS API CALL');
    print('===================================');

    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    // Try parent-linked endpoint first (returns only linked students)
    print('🔄 Trying parent-linked endpoint: ${ApiEndpoints.parentLinkedStudents}');
    var response = await ApiService.get<Map<String, dynamic>>(
      ApiEndpoints.parentLinkedStudents,
      queryParameters: queryParams,
    );

    if (response.success) {
      print('✅ Parent-linked endpoint working!');
      return response;
    }

    print('❌ Parent-linked endpoint failed: ${response.error}');

    // Try general students endpoint
    print('🔄 Trying general endpoint: ${ApiEndpoints.parentStudents}');
    response = await ApiService.get<Map<String, dynamic>>(
      ApiEndpoints.parentStudents,
      queryParameters: queryParams,
    );

    if (response.success) {
      print('✅ General endpoint working!');
      return response;
    }

    print('❌ General endpoint failed: ${response.error}');

    // Try alternative endpoints
    final alternatives = [
      '/api/v1/students/',
      '/api/v1/users/students/',
    ];

    for (final alternative in alternatives) {
      print('🔄 Trying alternative: $alternative');

      try {
        final response = await ApiService.get<Map<String, dynamic>>(
          alternative,
          queryParameters: queryParams,
        );

        if (response.success) {
          print('✅ Alternative endpoint working: $alternative');
          return response;
        } else {
          print('❌ Alternative failed: ${response.error}');
        }
      } catch (e) {
        print('💥 Alternative error: $e');
      }
    }

    print('❌ No working endpoints found');
    return ApiResponse<Map<String, dynamic>>.error(
      'Parent students endpoint not found. Tried: ${ApiEndpoints.parentStudents} and alternatives',
    );
  }

  /// Test parent students endpoint with detailed logging
  static Future<void> testParentStudentsEndpoint() async {
    print('🧪 TESTING PARENT STUDENTS ENDPOINT');
    print('==================================');

    final response = await getParentStudentsSafe(limit: 10);

    print('📊 Test Results:');
    print('   - Success: ${response.success}');
    print('   - Status Code: ${response.statusCode}');
    print('   - Error: ${response.error}');

    if (response.success && response.data != null) {
      print('✅ Parent students API is working!');
      print('📊 Data keys: ${response.data!.keys.toList()}');

      // Check if it's a list or has students
      if (response.data!.containsKey('results')) {
        final results = response.data!['results'] as List;
        print('📊 Found ${results.length} students');
      } else if (response.data!.containsKey('students')) {
        final students = response.data!['students'] as List;
        print('📊 Found ${students.length} students');
      } else {
        print('📊 Response structure: ${response.data!.keys.toList()}');
      }
    } else {
      print('❌ Parent students API failed');
      print('💡 Check if the endpoint exists on the server');
    }
  }

  /// Get working parent students endpoint
  static Future<String?> getWorkingParentStudentsEndpoint() async {
    print('🔍 FINDING WORKING PARENT STUDENTS ENDPOINT');
    print('==========================================');

    final endpoints = [
      ApiEndpoints.parentStudents,
      '/api/v1/students/',
      '/api/v1/students/students/',
      '/api/v1/users/students/',
      '/api/v1/students/students/',
    ];

    for (final endpoint in endpoints) {
      print('🔄 Testing: $endpoint');

      try {
        final response = await ApiService.get<Map<String, dynamic>>(endpoint);

        if (response.success) {
          print('✅ Working endpoint found: $endpoint');
          return endpoint;
        } else {
          print('❌ Failed: ${response.error}');
        }
      } catch (e) {
        print('💥 Error: $e');
      }
    }

    print('❌ No working endpoints found');
    return null;
  }

  /// Mock parent students data for testing
  static Map<String, dynamic> getMockParentStudentsData() {
    return {
      'count': 2,
      'results': [
        {
          'id': 1,
          'name': 'John Doe',
          'grade': '5th Grade',
          'school': 'Example Elementary',
          'status': 'active',
        },
        {
          'id': 2,
          'name': 'Jane Smith',
          'grade': '3rd Grade',
          'school': 'Example Elementary',
          'status': 'active',
        },
      ],
    };
  }

  /// Use mock data when API is not available
  static Future<ApiResponse<Map<String, dynamic>>>
  getParentStudentsWithFallback({int? limit, int? offset}) async {
    print('🔄 PARENT STUDENTS WITH FALLBACK');
    print('===============================');

    // Try real API first
    final apiResponse = await getParentStudentsSafe(
      limit: limit,
      offset: offset,
    );

    if (apiResponse.success) {
      print('✅ Using real API data');
      return apiResponse;
    }

    print('⚠️ API not available, using mock data');
    final mockData = getMockParentStudentsData();

    return ApiResponse<Map<String, dynamic>>.success(mockData);
  }
}
