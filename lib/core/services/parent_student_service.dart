import '../models/student_model.dart';
import '../config/api_endpoints.dart';
import 'api_service.dart';

class ParentStudentService {
  /// Get students for the authenticated parent
  static Future<ApiResponse<List<Student>>> getParentStudents({
    int? limit,
    int? offset,
    String? status,
    String? grade,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (status != null) queryParams['status'] = status;
    if (grade != null) queryParams['grade'] = grade;

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.parentStudents,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final results = data['results'] as List<dynamic>? ?? [];

        final students = results
            .map(
              (studentJson) =>
                  Student.fromJson(studentJson as Map<String, dynamic>),
            )
            .toList();

        return ApiResponse<List<Student>>.success(students);
      } else {
        return ApiResponse<List<Student>>.error(
          response.error ?? 'Failed to load students',
        );
      }
    } catch (e) {
      print('❌ Error fetching students: $e');
      return ApiResponse<List<Student>>.error('Failed to load students: $e');
    }
  }

  /// Get a specific student by ID
  static Future<ApiResponse<Student>> getStudentById(int studentId) async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.studentDetails(studentId),
      );

      if (response.success && response.data != null) {
        final student = Student.fromJson(response.data!);
        return ApiResponse<Student>.success(student);
      } else {
        return ApiResponse<Student>.error(
          response.error ?? 'Failed to load student',
        );
      }
    } catch (e) {
      print('❌ Error fetching student: $e');
      return ApiResponse<Student>.error('Failed to load student: $e');
    }
  }

  /// Get student's current trip status
  static Future<ApiResponse<Map<String, dynamic>>> getStudentTripStatus(
    int studentId,
  ) async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.studentTripStatus(studentId),
      );

      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(
          response.error ?? 'Failed to load trip status',
        );
      }
    } catch (e) {
      print('❌ Error fetching trip status: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        'Failed to load trip status: $e',
      );
    }
  }

  /// Get student's route information
  static Future<ApiResponse<Map<String, dynamic>>> getStudentRouteInfo(
    int studentId,
  ) async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.studentRouteInfo(studentId),
      );

      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(
          response.error ?? 'Failed to load route info',
        );
      }
    } catch (e) {
      print('❌ Error fetching route info: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        'Failed to load route info: $e',
      );
    }
  }

  /// Update student's emergency contact information
  static Future<ApiResponse<Map<String, dynamic>>>
  updateStudentEmergencyContact({
    required int studentId,
    required String contactName,
    required String contactPhone,
    String? relationship,
  }) async {
    try {
      final response = await ApiService.put<Map<String, dynamic>>(
        ApiEndpoints.updateStudentEmergencyContact(studentId),
        data: {
          'contact_name': contactName,
          'contact_phone': contactPhone,
          'relationship': relationship,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(
          response.error ?? 'Failed to update emergency contact',
        );
      }
    } catch (e) {
      print('❌ Error updating emergency contact: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        'Failed to update emergency contact: $e',
      );
    }
  }

  /// Get student's attendance history
  static Future<ApiResponse<List<Map<String, dynamic>>>> getStudentAttendance({
    required int studentId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (limit != null) queryParams['limit'] = limit;

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.studentAttendanceHistory(studentId),
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final results = data['results'] as List<dynamic>? ?? [];
        final attendanceList = results
            .map((item) => item as Map<String, dynamic>)
            .toList();
        return ApiResponse<List<Map<String, dynamic>>>.success(attendanceList);
      } else {
        return ApiResponse<List<Map<String, dynamic>>>.error(
          response.error ?? 'Failed to load attendance history',
        );
      }
    } catch (e) {
      print('❌ Error fetching attendance history: $e');
      return ApiResponse<List<Map<String, dynamic>>>.error(
        'Failed to load attendance history: $e',
      );
    }
  }
}
