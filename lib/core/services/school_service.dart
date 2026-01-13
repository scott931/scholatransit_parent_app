import '../config/api_endpoints.dart';
import 'api_service.dart';

class School {
  final int? id;
  final String name;
  final String? code;
  final bool? isActive;
  final String? status;

  School({
    this.id,
    required this.name,
    this.code,
    this.isActive,
    this.status,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    // Determine isActive from multiple possible fields
    bool? isActiveValue;
    if (json['is_active'] != null) {
      isActiveValue = json['is_active'] as bool?;
    } else if (json['isActive'] != null) {
      isActiveValue = json['isActive'] as bool?;
    } else if (json['status'] != null) {
      final statusStr = json['status'] as String?;
      isActiveValue = statusStr?.toLowerCase() == 'active';
    }
    
    return School(
      id: json['id'] as int?,
      name: json['name'] as String? ?? json['school_name'] as String? ?? '',
      code: json['code'] as String? ?? json['school_code'] as String?,
      isActive: isActiveValue,
      status: json['status'] as String?,
    );
  }
  
  /// Check if school is active
  bool get active {
    if (isActive != null) return isActive!;
    if (status != null) return status!.toLowerCase() == 'active';
    return true; // Default to active if not specified
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (code != null) 'code': code,
    };
  }
}

class SchoolService {
  /// Get all active schools from the API (equivalent to getAllSchools)
  /// This method fetches only active schools and is used on page load
  static Future<ApiResponse<List<School>>> getAllSchools({
    String? search,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{
      'is_active': true, // Only fetch active schools
      'status': 'active', // Alternative filter
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    try {
      final response = await ApiService.get<dynamic>(
        ApiEndpoints.schools,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        
        // Handle different response formats
        List<dynamic> schoolsList;
        if (data is Map<String, dynamic>) {
          if (data['results'] != null) {
            // Paginated response
            schoolsList = data['results'] as List<dynamic>;
          } else {
            schoolsList = [];
          }
        } else if (data is List) {
          // Direct list response
          schoolsList = data;
        } else {
          schoolsList = [];
        }

        // Parse schools and filter for active ones
        final allSchools = schoolsList
            .map((schoolJson) => School.fromJson(
                schoolJson as Map<String, dynamic>))
            .toList();
        
        // Filter to only include active schools (double-check on client side)
        final activeSchools = allSchools.where((school) => school.active).toList();

        return ApiResponse<List<School>>.success(activeSchools);
      } else {
        // Return empty list if API fails (allows free text input)
        return ApiResponse<List<School>>.success([]);
      }
    } catch (e) {
      print('⚠️ Error fetching schools: $e');
      // Return empty list on error (allows free text input)
      return ApiResponse<List<School>>.success([]);
    }
  }

  /// Get all schools from the API (with optional filtering)
  /// Use getAllSchools() for registration form to get only active schools
  static Future<ApiResponse<List<School>>> getSchools({
    String? search,
    int? limit,
    int? offset,
    bool? activeOnly,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (activeOnly == true) {
      queryParams['is_active'] = true;
      queryParams['status'] = 'active';
    }

    try {
      final response = await ApiService.get<dynamic>(
        ApiEndpoints.schools,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        
        // Handle different response formats
        List<dynamic> schoolsList;
        if (data is Map<String, dynamic>) {
          if (data['results'] != null) {
            // Paginated response
            schoolsList = data['results'] as List<dynamic>;
          } else {
            schoolsList = [];
          }
        } else if (data is List) {
          // Direct list response
          schoolsList = data;
        } else {
          schoolsList = [];
        }

        final schools = schoolsList
            .map((schoolJson) => School.fromJson(
                schoolJson as Map<String, dynamic>))
            .toList();
        
        // Filter for active schools if requested
        final filteredSchools = activeOnly == true
            ? schools.where((school) => school.active).toList()
            : schools;

        return ApiResponse<List<School>>.success(filteredSchools);
      } else {
        // Return empty list if API fails (allows free text input)
        return ApiResponse<List<School>>.success([]);
      }
    } catch (e) {
      print('⚠️ Error fetching schools: $e');
      // Return empty list on error (allows free text input)
      return ApiResponse<List<School>>.success([]);
    }
  }
}
