import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_log_model.dart';
import '../services/trip_logs_service.dart';

/// Trip Logs State
///
/// Manages the state of trip logs including loading, data, filters, and pagination.
class TripLogsState {
  final bool isLoading;
  final bool isRefreshing;
  final List<TripLog> tripLogs;
  final String? error;
  final int currentPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int totalCount;
  final TripLogStatus? statusFilter;
  final TripLogType? typeFilter;
  final int? driverFilter;
  final int? vehicleFilter;
  final int? routeFilter;
  final DateTime? dateFromFilter;
  final DateTime? dateToFilter;
  final String? searchQuery;
  final TripLog? selectedTripLog;
  final Map<String, dynamic>? statistics;

  const TripLogsState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.tripLogs = const [],
    this.error,
    this.currentPage = 1,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.totalCount = 0,
    this.statusFilter,
    this.typeFilter,
    this.driverFilter,
    this.vehicleFilter,
    this.routeFilter,
    this.dateFromFilter,
    this.dateToFilter,
    this.searchQuery,
    this.selectedTripLog,
    this.statistics,
  });

  TripLogsState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<TripLog>? tripLogs,
    String? error,
    int? currentPage,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? totalCount,
    TripLogStatus? statusFilter,
    TripLogType? typeFilter,
    int? driverFilter,
    int? vehicleFilter,
    int? routeFilter,
    DateTime? dateFromFilter,
    DateTime? dateToFilter,
    String? searchQuery,
    TripLog? selectedTripLog,
    Map<String, dynamic>? statistics,
    bool clearError = false,
    bool clearFilters = false,
  }) {
    return TripLogsState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      tripLogs: tripLogs ?? this.tripLogs,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      totalCount: totalCount ?? this.totalCount,
      statusFilter: clearFilters ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearFilters ? null : (typeFilter ?? this.typeFilter),
      driverFilter: clearFilters ? null : (driverFilter ?? this.driverFilter),
      vehicleFilter: clearFilters
          ? null
          : (vehicleFilter ?? this.vehicleFilter),
      routeFilter: clearFilters ? null : (routeFilter ?? this.routeFilter),
      dateFromFilter: clearFilters
          ? null
          : (dateFromFilter ?? this.dateFromFilter),
      dateToFilter: clearFilters ? null : (dateToFilter ?? this.dateToFilter),
      searchQuery: clearFilters ? null : (searchQuery ?? this.searchQuery),
      selectedTripLog: selectedTripLog ?? this.selectedTripLog,
      statistics: statistics ?? this.statistics,
    );
  }

  /// Check if there are any active filters
  bool get hasActiveFilters {
    return statusFilter != null ||
        typeFilter != null ||
        driverFilter != null ||
        vehicleFilter != null ||
        routeFilter != null ||
        dateFromFilter != null ||
        dateToFilter != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Get filtered trip logs count
  int get filteredCount => tripLogs.length;

  /// Check if there are more pages to load
  bool get canLoadMore => hasNextPage && !isLoading;

  /// Check if there are previous pages
  bool get canGoBack => hasPreviousPage && !isLoading;
}

/// Trip Logs Notifier
///
/// Manages trip logs state and provides methods to interact with the API.
class TripLogsNotifier extends StateNotifier<TripLogsState> {
  TripLogsNotifier() : super(const TripLogsState());

  /// Load trip logs with current filters
  Future<void> loadTripLogs({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isRefreshing: true,
        currentPage: 1,
        clearError: true,
      );
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final response = await TripLogsService.getTripLogs(
        page: state.currentPage,
        pageSize: 20,
        status: state.statusFilter,
        tripType: state.typeFilter,
        driverId: state.driverFilter,
        vehicleId: state.vehicleFilter,
        routeId: state.routeFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchQuery,
      );

      if (response.success && response.data != null) {
        final tripLogsResponse = response.data!;

        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          tripLogs: refresh
              ? tripLogsResponse.results
              : [...state.tripLogs, ...tripLogsResponse.results],
          currentPage: state.currentPage,
          hasNextPage: tripLogsResponse.hasNext,
          hasPreviousPage: tripLogsResponse.hasPrevious,
          totalCount: tripLogsResponse.count,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: response.error ?? 'Failed to load trip logs',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Error loading trip logs: $e',
      );
    }
  }

  /// Load more trip logs (pagination)
  Future<void> loadMoreTripLogs() async {
    if (!state.canLoadMore) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await TripLogsService.getTripLogs(
        page: state.currentPage + 1,
        pageSize: 20,
        status: state.statusFilter,
        tripType: state.typeFilter,
        driverId: state.driverFilter,
        vehicleId: state.vehicleFilter,
        routeId: state.routeFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        search: state.searchQuery,
      );

      if (response.success && response.data != null) {
        final tripLogsResponse = response.data!;

        state = state.copyWith(
          isLoading: false,
          tripLogs: [...state.tripLogs, ...tripLogsResponse.results],
          currentPage: state.currentPage + 1,
          hasNextPage: tripLogsResponse.hasNext,
          hasPreviousPage: tripLogsResponse.hasPrevious,
          totalCount: tripLogsResponse.count,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load more trip logs',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading more trip logs: $e',
      );
    }
  }

  /// Refresh trip logs
  Future<void> refreshTripLogs() async {
    await loadTripLogs(refresh: true);
  }

  /// Set status filter
  void setStatusFilter(TripLogStatus? status) {
    state = state.copyWith(
      statusFilter: status,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Set type filter
  void setTypeFilter(TripLogType? type) {
    state = state.copyWith(typeFilter: type, currentPage: 1, clearError: true);
    loadTripLogs(refresh: true);
  }

  /// Set driver filter
  void setDriverFilter(int? driverId) {
    state = state.copyWith(
      driverFilter: driverId,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Set vehicle filter
  void setVehicleFilter(int? vehicleId) {
    state = state.copyWith(
      vehicleFilter: vehicleId,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Set route filter
  void setRouteFilter(int? routeId) {
    state = state.copyWith(
      routeFilter: routeId,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Set date range filter
  void setDateRangeFilter(DateTime? dateFrom, DateTime? dateTo) {
    state = state.copyWith(
      dateFromFilter: dateFrom,
      dateToFilter: dateTo,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Set search query
  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      clearFilters: true,
      currentPage: 1,
      clearError: true,
    );
    loadTripLogs(refresh: true);
  }

  /// Select a trip log
  void selectTripLog(TripLog? tripLog) {
    state = state.copyWith(selectedTripLog: tripLog);
  }

  /// Load trip log statistics
  Future<void> loadStatistics() async {
    try {
      final response = await TripLogsService.getTripLogStatistics(
        driverId: state.driverFilter,
        vehicleId: state.vehicleFilter,
        routeId: state.routeFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(statistics: response.data);
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  /// Export trip logs
  Future<String?> exportTripLogs() async {
    try {
      final response = await TripLogsService.exportTripLogs(
        driverId: state.driverFilter,
        vehicleId: state.vehicleFilter,
        routeId: state.routeFilter,
        dateFrom: state.dateFromFilter,
        dateTo: state.dateToFilter,
        status: state.statusFilter,
        tripType: state.typeFilter,
      );

      if (response.success && response.data != null) {
        return response.data;
      } else {
        state = state.copyWith(
          error: response.error ?? 'Failed to export trip logs',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error exporting trip logs: $e');
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Trip Logs Provider
///
/// Provides access to the trip logs state and notifier.
final tripLogsProvider = StateNotifierProvider<TripLogsNotifier, TripLogsState>(
  (ref) => TripLogsNotifier(),
);

/// Selected Trip Log Provider
///
/// Provides access to the currently selected trip log.
final selectedTripLogProvider = Provider<TripLog?>((ref) {
  return ref.watch(tripLogsProvider).selectedTripLog;
});

/// Trip Logs Statistics Provider
///
/// Provides access to trip logs statistics.
final tripLogsStatisticsProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(tripLogsProvider).statistics;
});

/// Trip Logs Filters Provider
///
/// Provides access to current filters.
final tripLogsFiltersProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(tripLogsProvider);
  return {
    'status': state.statusFilter,
    'type': state.typeFilter,
    'driver': state.driverFilter,
    'vehicle': state.vehicleFilter,
    'route': state.routeFilter,
    'dateFrom': state.dateFromFilter,
    'dateTo': state.dateToFilter,
    'search': state.searchQuery,
  };
});
