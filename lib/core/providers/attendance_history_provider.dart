import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_history_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AttendanceHistoryState {
  final bool isLoading;
  final List<AttendanceRecord> records;
  final AttendanceSummary? summary;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, List<AttendanceRecord>> recordsByDate;

  const AttendanceHistoryState({
    this.isLoading = false,
    this.records = const [],
    this.summary,
    this.error,
    this.lastUpdated,
    this.recordsByDate = const {},
  });

  AttendanceHistoryState copyWith({
    bool? isLoading,
    List<AttendanceRecord>? records,
    AttendanceSummary? summary,
    String? error,
    DateTime? lastUpdated,
    Map<String, List<AttendanceRecord>>? recordsByDate,
  }) {
    return AttendanceHistoryState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      summary: summary ?? this.summary,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      recordsByDate: recordsByDate ?? this.recordsByDate,
    );
  }
}

class AttendanceHistoryNotifier extends StateNotifier<AttendanceHistoryState> {
  AttendanceHistoryNotifier() : super(const AttendanceHistoryState()) {
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📊 DEBUG: Loading attendance history...');

      // Get parent ID from storage
      final parentId = StorageService.getInt('parent_id');
      if (parentId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Parent ID not found. Please login again.',
        );
        return;
      }

      // Load attendance history from API
      final response = await ApiService.get<List<dynamic>>(
        '/attendance/history/?parent_id=$parentId',
      );

      if (response.success && response.data != null) {
        final records = (response.data as List)
            .map(
              (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        // Sort records by date (newest first)
        records.sort((a, b) => b.tripDate.compareTo(a.tripDate));

        // Group records by date
        final recordsByDate = <String, List<AttendanceRecord>>{};
        for (final record in records) {
          final dateKey = _formatDateKey(record.tripDate);
          recordsByDate.putIfAbsent(dateKey, () => []).add(record);
        }

        // Calculate summary
        final summary = AttendanceSummary.fromRecords(records);

        state = state.copyWith(
          isLoading: false,
          records: records,
          summary: summary,
          recordsByDate: recordsByDate,
          lastUpdated: DateTime.now(),
          error: null,
        );

        print(
          '📊 DEBUG: Attendance history loaded successfully - ${records.length} records',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load attendance history',
        );
        print('📊 DEBUG: Failed to load attendance history: ${response.error}');
      }
    } catch (e) {
      print('📊 DEBUG: Error loading attendance history: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading attendance history: $e',
      );
    }
  }

  Future<void> refreshAttendanceHistory() async {
    print('📊 DEBUG: Refreshing attendance history...');
    await _loadAttendanceHistory();
  }

  Future<void> loadAttendanceHistoryForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print(
        '📊 DEBUG: Loading attendance history for date range: $startDate to $endDate',
      );

      final parentId = StorageService.getInt('parent_id');
      if (parentId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Parent ID not found. Please login again.',
        );
        return;
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await ApiService.get<List<dynamic>>(
        '/attendance/history/?parent_id=$parentId&start_date=$startDateStr&end_date=$endDateStr',
      );

      if (response.success && response.data != null) {
        final records = (response.data as List)
            .map(
              (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        records.sort((a, b) => b.tripDate.compareTo(a.tripDate));

        final recordsByDate = <String, List<AttendanceRecord>>{};
        for (final record in records) {
          final dateKey = _formatDateKey(record.tripDate);
          recordsByDate.putIfAbsent(dateKey, () => []).add(record);
        }

        final summary = AttendanceSummary.fromRecords(records);

        state = state.copyWith(
          isLoading: false,
          records: records,
          summary: summary,
          recordsByDate: recordsByDate,
          lastUpdated: DateTime.now(),
          error: null,
        );

        print(
          '📊 DEBUG: Attendance history for date range loaded - ${records.length} records',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load attendance history',
        );
      }
    } catch (e) {
      print('📊 DEBUG: Error loading attendance history for date range: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading attendance history: $e',
      );
    }
  }

  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    return state.recordsByDate[dateKey] ?? [];
  }

  List<AttendanceRecord> getRecordsForStatus(AttendanceStatus status) {
    return state.records.where((record) => record.status == status).toList();
  }

  List<AttendanceRecord> searchRecords(String query) {
    if (query.isEmpty) return state.records;

    final lowercaseQuery = query.toLowerCase();
    return state.records.where((record) {
      return record.studentName.toLowerCase().contains(lowercaseQuery) ||
          record.routeName.toLowerCase().contains(lowercaseQuery) ||
          record.driverName.toLowerCase().contains(lowercaseQuery) ||
          record.tripIdString.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final attendanceHistoryProvider =
    StateNotifierProvider<AttendanceHistoryNotifier, AttendanceHistoryState>(
      (ref) => AttendanceHistoryNotifier(),
    );
