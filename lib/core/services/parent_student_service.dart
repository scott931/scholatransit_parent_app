import '../models/student_model.dart';
import '../config/api_endpoints.dart';
import 'api_service.dart';

class ParentStudentService {
  /// Get students linked to the authenticated parent.
  /// Uses students API first; when empty, uses approved link requests as primary source.
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
      // 1. Try parent-linked endpoint first
      var response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.parentLinkedStudents,
        queryParameters: queryParams,
      );

      // 2. Fall back to general endpoint if parent-linked returns 404
      if (!response.success &&
          (response.statusCode == 404 ||
              response.error?.contains('404') == true)) {
        response = await ApiService.get<Map<String, dynamic>>(
          ApiEndpoints.parentStudents,
          queryParameters: queryParams,
        );
      }

      List<Student> students = [];
      if (response.success && response.data != null) {
        final data = response.data!;
        final results = data['results'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            data['students'] as List<dynamic>? ??
            [];

        students = results
            .map(
              (e) => Student.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      // 3. Merge approved link requests (adds missing students)
      students = await _mergeApprovedStudentsFromLinkRequests(students);

      // 4. When API returned empty, use approved link requests as primary source
      if (students.isEmpty) {
        students = await _getStudentsFromApprovedLinkRequests();
        if (students.isNotEmpty) {
          print('✅ Loaded ${students.length} student(s) from approved link requests');
        }
      }

      if (response.success || students.isNotEmpty) {
        return ApiResponse<List<Student>>.success(students);
      }
      return ApiResponse<List<Student>>.error(
        response.error ?? 'Failed to load students',
      );
    } catch (e) {
      // Try approved link requests as fallback on error
      try {
        final fromLinks = await _getStudentsFromApprovedLinkRequests();
        if (fromLinks.isNotEmpty) {
          return ApiResponse<List<Student>>.success(fromLinks);
        }
      } catch (_) {}
      print('❌ Error fetching students: $e');
      return ApiResponse<List<Student>>.error('Failed to load students: $e');
    }
  }

  /// Build student list from approved link requests (primary source when API is empty).
  static Future<List<Student>> _getStudentsFromApprovedLinkRequests() async {
    return _mergeApprovedStudentsFromLinkRequests([]);
  }

  /// Merges approved students from link requests into the list.
  /// Ensures parents see students whose link requests were approved.
  static Future<List<Student>> _mergeApprovedStudentsFromLinkRequests(
    List<Student> students,
  ) async {
    try {
      var linkResp = await getMyLinkRequests(statusFilter: 'approved');
      if (!linkResp.success || linkResp.data == null) {
        return students;
      }
      var requests = linkResp.data!;
      // If filtered empty, try without filter (backend may not support status param)
      if (requests.isEmpty) {
        linkResp = await getMyLinkRequests();
        if (linkResp.success && linkResp.data != null) {
          requests = linkResp.data!;
        }
      }
      final approved = requests
          .where((r) => (r['status'] as String? ?? '').toLowerCase() == 'approved')
          .toList();
      if (approved.isEmpty) return students;
      final existingIds = students.map((s) => s.id).toSet();
      final toAdd = <Student>[];

      for (final req in approved) {
        int? studentId;
        Map<String, dynamic>? studentJson;

        if (req['student'] is int) {
          studentId = req['student'] as int;
        } else if (req['student'] is Map<String, dynamic>) {
          studentJson = req['student'] as Map<String, dynamic>;
          studentId = studentJson['id'] is int
              ? studentJson['id'] as int
              : int.tryParse(studentJson['id']?.toString() ?? '');
        } else if (req['student_id'] != null) {
          studentId = req['student_id'] is int
              ? req['student_id'] as int
              : int.tryParse(req['student_id'].toString());
        } else if (req['studentId'] != null) {
          studentId = req['studentId'] is int
              ? req['studentId'] as int
              : int.tryParse(req['studentId'].toString());
        }
        if (req['student_details'] is Map<String, dynamic>) {
          studentJson = req['student_details'] as Map<String, dynamic>;
        }

        if (studentId == null || existingIds.contains(studentId)) continue;

        if (studentJson != null) {
          try {
            toAdd.add(Student.fromJson(studentJson));
            existingIds.add(studentId);
          } catch (_) {}
        } else {
          final detailResp = await getStudentById(studentId);
          if (detailResp.success && detailResp.data != null) {
            toAdd.add(detailResp.data!);
            existingIds.add(studentId);
          } else {
            // Build minimal student from request (student_name, etc.)
            final name = req['student_name'] as String? ?? req['studentName'] as String? ?? 'Student';
            final parts = name.split(' ');
            final firstName = parts.isNotEmpty ? parts.first : 'Student';
            final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            try {
              toAdd.add(Student.fromJson({
                'id': studentId,
                'student_id': studentId.toString(),
                'first_name': firstName,
                'last_name': lastName,
                'full_name': name,
                'date_of_birth': '',
                'gender': '',
                'grade': '',
                'status': 'active',
                'approval_status': 'approved',
                'age': 0,
                'phone_number': '',
                'email': '',
                'address': '',
                'city': '',
                'state': '',
                'postal_code': '',
                'country': '',
                'school_name': '',
                'school_address': '',
                'has_route_assignment': false,
                'upcoming_trips': [],
                'parents': [],
                'created_at': req['created_at'] ?? DateTime.now().toIso8601String(),
                'updated_at': req['updated_at'] ?? DateTime.now().toIso8601String(),
              }));
              existingIds.add(studentId);
            } catch (_) {}
          }
        }
      }

      if (toAdd.isNotEmpty) {
        print('✅ Merged ${toAdd.length} approved student(s) from link requests');
        return [...students, ...toAdd];
      }
      return students;
    } catch (e) {
      print('⚠️ Could not merge approved link requests: $e');
      return students;
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

  /// Get students available to link (not linked to current parent, from parent's school).
  /// Backend filters by parent's school automatically.
  static Future<ApiResponse<List<Student>>> getAvailableStudents() async {
    try {
      final response = await ApiService.get<dynamic>(
        ApiEndpoints.availableStudents,
      );

      if (response.success && response.data != null) {
        final raw = response.data!;
        List<dynamic> list;
        if (raw is List<dynamic>) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          list = raw['results'] as List<dynamic>? ?? [];
        } else {
          return ApiResponse<List<Student>>.error('Unexpected response format');
        }
        final students = list
            .map(
              (e) => Student.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        return ApiResponse<List<Student>>.success(students);
      }
      return ApiResponse<List<Student>>.error(
        response.error ?? 'Failed to load available students',
      );
    } catch (e) {
      print('❌ Error fetching available students: $e');
      return ApiResponse<List<Student>>.error(
        'Failed to load available students: $e',
      );
    }
  }

  /// Request to link the current parent to an existing student.
  /// School admin will review and approve. Options: is_primary_contact, can_pickup, can_dropoff.
  static Future<ApiResponse<Map<String, dynamic>>> requestStudentLink({
    required int studentId,
    bool isPrimaryContact = false,
    bool canPickup = true,
    bool canDropoff = true,
  }) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.linkRequests,
        data: {
          'student': studentId,
          'is_primary_contact': isPrimaryContact,
          'can_pickup': canPickup,
          'can_dropoff': canDropoff,
        },
      );

      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>.success(response.data!);
      }
      return ApiResponse<Map<String, dynamic>>.error(
        response.error ?? 'Failed to submit link request',
      );
    } catch (e) {
      print('❌ Error requesting student link: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        'Failed to submit link request: $e',
      );
    }
  }

  /// Get the current parent's link requests (pending, approved, rejected).
  /// Optional [statusFilter]: 'pending', 'approved', 'rejected'.
  static Future<ApiResponse<List<Map<String, dynamic>>>> getMyLinkRequests({
    String? statusFilter,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams['status'] = statusFilter;
      }
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.myLinkRequests,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.success && response.data != null) {
        final data = response.data!;
        final list = data['requests'] as List<dynamic>? ??
            data['results'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
        final requests = list
            .map((e) => e as Map<String, dynamic>)
            .toList();
        return ApiResponse<List<Map<String, dynamic>>>.success(requests);
      }
      return ApiResponse<List<Map<String, dynamic>>>.error(
        response.error ?? 'Failed to load your link requests',
      );
    } catch (e) {
      print('❌ Error fetching my link requests: $e');
      return ApiResponse<List<Map<String, dynamic>>>.error(
        'Failed to load your link requests: $e',
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
