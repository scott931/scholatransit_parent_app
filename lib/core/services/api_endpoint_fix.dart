import 'api_service.dart';
import '../config/api_endpoints.dart';

/// API Endpoint Fix Service
/// Fixes 404 errors and endpoint issues
class ApiEndpointFix {
  /// Test API endpoint availability
  static Future<Map<String, dynamic>> testEndpoint(String endpoint) async {
    print('🧪 TESTING API ENDPOINT: $endpoint');
    print('==================================');

    try {
      final response = await ApiService.get<Map<String, dynamic>>(endpoint);

      print('📡 Endpoint Test Results:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Error: ${response.error}');

      if (response.success) {
        print('✅ Endpoint is working!');
        return {
          'working': true,
          'statusCode': response.statusCode,
          'error': null,
        };
      } else {
        print('❌ Endpoint failed');
        return {
          'working': false,
          'statusCode': response.statusCode,
          'error': response.error,
        };
      }
    } catch (e) {
      print('💥 Endpoint test error: $e');
      return {'working': false, 'statusCode': null, 'error': e.toString()};
    }
  }

  /// Test all critical endpoints
  static Future<Map<String, dynamic>> testAllEndpoints() async {
    print('🧪 TESTING ALL CRITICAL ENDPOINTS');
    print('=================================');

    final results = <String, Map<String, dynamic>>{};

    // Test profile endpoint
    print('\n1. Testing Profile Endpoint...');
    results['profile'] = await testEndpoint(ApiEndpoints.profile);

    // Test parent students endpoint
    print('\n2. Testing Parent Students Endpoint...');
    results['parentStudents'] = await testEndpoint(ApiEndpoints.parentStudents);

    // Test emergency alerts endpoint
    print('\n3. Testing Emergency Alerts Endpoint...');
    results['emergencyAlerts'] = await testEndpoint(
      ApiEndpoints.emergencyAlerts,
    );

    // Test notifications endpoint
    print('\n4. Testing Notifications Endpoint...');
    results['notifications'] = await testEndpoint(ApiEndpoints.notifications);

    // Summary
    print('\n📊 ENDPOINT TEST SUMMARY:');
    print('========================');

    int workingCount = 0;
    int totalCount = results.length;

    for (final entry in results.entries) {
      final endpoint = entry.key;
      final result = entry.value;
      final status = result['working'] ? '✅ Working' : '❌ Failed';
      print('   $endpoint: $status');

      if (result['working']) {
        workingCount++;
      } else {
        print('     Error: ${result['error']}');
        print('     Status: ${result['statusCode']}');
      }
    }

    print('\n📈 Overall: $workingCount/$totalCount endpoints working');

    return {
      'results': results,
      'workingCount': workingCount,
      'totalCount': totalCount,
      'allWorking': workingCount == totalCount,
    };
  }

  /// Fix 404 errors by trying alternative endpoints
  static Future<Map<String, dynamic>> fix404Error(
    String originalEndpoint,
  ) async {
    print('🔧 FIXING 404 ERROR FOR: $originalEndpoint');
    print('==========================================');

    // Try alternative endpoints
    final alternatives = _getAlternativeEndpoints(originalEndpoint);

    for (final alternative in alternatives) {
      print('\n🔄 Trying alternative: $alternative');
      final result = await testEndpoint(alternative);

      if (result['working']) {
        print('✅ Found working alternative: $alternative');
        return {
          'fixed': true,
          'originalEndpoint': originalEndpoint,
          'workingEndpoint': alternative,
          'result': result,
        };
      }
    }

    print('❌ No working alternatives found');
    return {
      'fixed': false,
      'originalEndpoint': originalEndpoint,
      'workingEndpoint': null,
      'result': null,
    };
  }

  /// Get alternative endpoints for common 404 errors
  static List<String> _getAlternativeEndpoints(String endpoint) {
    final alternatives = <String>[];

    // Common endpoint variations
    if (endpoint.contains('/parent/students/')) {
      alternatives.addAll([
        '/api/v1/students/',
        '/api/v1/students/students/',
        '/api/v1/users/students/',
        '/api/v1/students/students/',
      ]);
    }

    if (endpoint.contains('/emergency/alerts/')) {
      alternatives.addAll([
        '/api/v1/alerts/',
        '/api/v1/emergency/',
        '/api/v1/notifications/emergency/',
      ]);
    }

    if (endpoint.contains('/notifications/')) {
      alternatives.addAll([
        '/api/v1/alerts/',
        '/api/v1/messages/',
        '/api/v1/notifications/notifications/',
      ]);
    }

    return alternatives;
  }

  /// Diagnose API base URL issues
  static Future<Map<String, dynamic>> diagnoseBaseUrl() async {
    print('🔍 DIAGNOSING API BASE URL');
    print('==========================');

    final baseUrl = ApiEndpoints.baseUrl;
    print('Base URL: $baseUrl');

    // Test health endpoint
    final healthResult = await testEndpoint('/');
    print('Health endpoint result: ${healthResult['working'] ? '✅' : '❌'}');

    // Test API health endpoint
    final apiHealthResult = await testEndpoint('/api/v1/health/');
    print(
      'API health endpoint result: ${apiHealthResult['working'] ? '✅' : '❌'}',
    );

    return {
      'baseUrl': baseUrl,
      'healthWorking': healthResult['working'],
      'apiHealthWorking': apiHealthResult['working'],
      'overallHealthy': healthResult['working'] || apiHealthResult['working'],
    };
  }

  /// Complete API endpoint diagnosis and fix
  static Future<Map<String, dynamic>> completeEndpointFix() async {
    print('🚀 COMPLETE API ENDPOINT FIX');
    print('============================');

    // Step 1: Diagnose base URL
    final baseUrlDiagnosis = await diagnoseBaseUrl();

    // Step 2: Test all endpoints
    final endpointResults = await testAllEndpoints();

    // Step 3: Try to fix 404 errors
    final fixes = <String, Map<String, dynamic>>{};

    for (final entry in endpointResults['results'].entries) {
      final endpoint = entry.key;
      final result = entry.value;

      if (!result['working'] && result['statusCode'] == 404) {
        print('\n🔧 Attempting to fix 404 for $endpoint...');
        final fix = await fix404Error(
          ApiEndpoints.profile,
        ); // Use profile as example
        if (fix['fixed']) {
          fixes[endpoint] = fix;
        }
      }
    }

    return {
      'baseUrlDiagnosis': baseUrlDiagnosis,
      'endpointResults': endpointResults,
      'fixes': fixes,
      'overallFixed': fixes.isNotEmpty,
    };
  }
}
