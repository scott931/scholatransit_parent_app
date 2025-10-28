import '../config/api_endpoints.dart';
import '../models/trip_log_model.dart';
import 'api_service.dart';

/// Trip Logs Service
///
/// Handles all API calls related to trip logs functionality.
/// Provides methods to fetch, filter, and manage trip logs data.
class TripLogsService {
  /// Fetch trip logs with optional filtering and pagination
  ///
  /// [page] - Page number for pagination (default: 1)
  /// [pageSize] - Number of items per page (default: 20)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  /// [driverId] - Filter by driver ID (optional)
  /// [vehicleId] - Filter by vehicle ID (optional)
  /// [routeId] - Filter by route ID (optional)
  /// [dateFrom] - Filter trips from this date (optional)
  /// [dateTo] - Filter trips to this date (optional)
  /// [search] - Search in trip ID, driver name, vehicle name, or route name (optional)
  static Future<ApiResponse<TripLogsResponse>> getTripLogs({
    int page = 1,
    int pageSize = 20,
    TripLogStatus? status,
    TripLogType? tripType,
    int? driverId,
    int? vehicleId,
    int? routeId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      // Add optional filters
      if (status != null) {
        queryParams['status'] = status.apiValue;
      }

      if (tripType != null) {
        queryParams['trip_type'] = tripType.apiValue;
      }

      if (driverId != null) {
        queryParams['driver'] = driverId;
      }

      if (vehicleId != null) {
        queryParams['vehicle'] = vehicleId;
      }

      if (routeId != null) {
        queryParams['route'] = routeId;
      }

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('🔍 TripLogsService: Fetching trip logs with params: $queryParams');

      // Make API call
      final response = await ApiService.get<TripLogsResponse>(
        ApiEndpoints.tripLogs,
        queryParameters: queryParams,
      );

      if (response.success) {
        print(
          '✅ TripLogsService: Successfully fetched ${response.data?.results.length ?? 0} trip logs',
        );
        return response;
      } else {
        print(
          '❌ TripLogsService: Failed to fetch trip logs: ${response.error}',
        );
        return response;
      }
    } catch (e) {
      print('❌ TripLogsService: Exception while fetching trip logs: $e');
      return ApiResponse<TripLogsResponse>.error(
        'Failed to fetch trip logs: $e',
      );
    }
  }

  /// Fetch trip logs for a specific driver
  ///
  /// [driverId] - The driver ID to filter by
  /// [page] - Page number for pagination (default: 1)
  /// [pageSize] - Number of items per page (default: 20)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  static Future<ApiResponse<TripLogsResponse>> getDriverTripLogs({
    required int driverId,
    int page = 1,
    int pageSize = 20,
    TripLogStatus? status,
    TripLogType? tripType,
  }) async {
    return getTripLogs(
      page: page,
      pageSize: pageSize,
      driverId: driverId,
      status: status,
      tripType: tripType,
    );
  }

  /// Fetch trip logs for a specific vehicle
  ///
  /// [vehicleId] - The vehicle ID to filter by
  /// [page] - Page number for pagination (default: 1)
  /// [pageSize] - Number of items per page (default: 20)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  static Future<ApiResponse<TripLogsResponse>> getVehicleTripLogs({
    required int vehicleId,
    int page = 1,
    int pageSize = 20,
    TripLogStatus? status,
    TripLogType? tripType,
  }) async {
    return getTripLogs(
      page: page,
      pageSize: pageSize,
      vehicleId: vehicleId,
      status: status,
      tripType: tripType,
    );
  }

  /// Fetch trip logs for a specific route
  ///
  /// [routeId] - The route ID to filter by
  /// [page] - Page number for pagination (default: 1)
  /// [pageSize] - Number of items per page (default: 20)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  static Future<ApiResponse<TripLogsResponse>> getRouteTripLogs({
    required int routeId,
    int page = 1,
    int pageSize = 20,
    TripLogStatus? status,
    TripLogType? tripType,
  }) async {
    return getTripLogs(
      page: page,
      pageSize: pageSize,
      routeId: routeId,
      status: status,
      tripType: tripType,
    );
  }

  /// Fetch trip logs for a specific date range
  ///
  /// [dateFrom] - Start date for filtering
  /// [dateTo] - End date for filtering
  /// [page] - Page number for pagination (default: 1)
  /// [pageSize] - Number of items per page (default: 20)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  static Future<ApiResponse<TripLogsResponse>> getTripLogsByDateRange({
    required DateTime dateFrom,
    required DateTime dateTo,
    int page = 1,
    int pageSize = 20,
    TripLogStatus? status,
    TripLogType? tripType,
  }) async {
    return getTripLogs(
      page: page,
      pageSize: pageSize,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
      tripType: tripType,
    );
  }

  /// Search trip logs by text
  ///
  /// [search] - Search term
  /// [page] - Page number for pagination (default: 1)
  /// [pageSize] - Number of items per page (default: 20)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  static Future<ApiResponse<TripLogsResponse>> searchTripLogs({
    required String search,
    int page = 1,
    int pageSize = 20,
    TripLogStatus? status,
    TripLogType? tripType,
  }) async {
    return getTripLogs(
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      tripType: tripType,
    );
  }

  /// Get trip log statistics
  ///
  /// [driverId] - Filter by driver ID (optional)
  /// [vehicleId] - Filter by vehicle ID (optional)
  /// [routeId] - Filter by route ID (optional)
  /// [dateFrom] - Filter from this date (optional)
  /// [dateTo] - Filter to this date (optional)
  static Future<ApiResponse<Map<String, dynamic>>> getTripLogStatistics({
    int? driverId,
    int? vehicleId,
    int? routeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{'statistics': true};

      // Add optional filters
      if (driverId != null) {
        queryParams['driver'] = driverId;
      }

      if (vehicleId != null) {
        queryParams['vehicle'] = vehicleId;
      }

      if (routeId != null) {
        queryParams['route'] = routeId;
      }

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      print(
        '📊 TripLogsService: Fetching trip log statistics with params: $queryParams',
      );

      // Make API call
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.tripLogs,
        queryParameters: queryParams,
      );

      if (response.success) {
        print('✅ TripLogsService: Successfully fetched trip log statistics');
        return response;
      } else {
        print(
          '❌ TripLogsService: Failed to fetch trip log statistics: ${response.error}',
        );
        return response;
      }
    } catch (e) {
      print(
        '❌ TripLogsService: Exception while fetching trip log statistics: $e',
      );
      return ApiResponse<Map<String, dynamic>>.error(
        'Failed to fetch trip log statistics: $e',
      );
    }
  }

  /// Export trip logs to CSV format
  ///
  /// [driverId] - Filter by driver ID (optional)
  /// [vehicleId] - Filter by vehicle ID (optional)
  /// [routeId] - Filter by route ID (optional)
  /// [dateFrom] - Filter from this date (optional)
  /// [dateTo] - Filter to this date (optional)
  /// [status] - Filter by trip status (optional)
  /// [tripType] - Filter by trip type (optional)
  static Future<ApiResponse<String>> exportTripLogs({
    int? driverId,
    int? vehicleId,
    int? routeId,
    DateTime? dateFrom,
    DateTime? dateTo,
    TripLogStatus? status,
    TripLogType? tripType,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{'export': 'csv'};

      // Add optional filters
      if (driverId != null) {
        queryParams['driver'] = driverId;
      }

      if (vehicleId != null) {
        queryParams['vehicle'] = vehicleId;
      }

      if (routeId != null) {
        queryParams['route'] = routeId;
      }

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      if (status != null) {
        queryParams['status'] = status.apiValue;
      }

      if (tripType != null) {
        queryParams['trip_type'] = tripType.apiValue;
      }

      print(
        '📤 TripLogsService: Exporting trip logs with params: $queryParams',
      );

      // Make API call
      final response = await ApiService.get<String>(
        ApiEndpoints.tripLogs,
        queryParameters: queryParams,
      );

      if (response.success) {
        print('✅ TripLogsService: Successfully exported trip logs');
        return response;
      } else {
        print(
          '❌ TripLogsService: Failed to export trip logs: ${response.error}',
        );
        return response;
      }
    } catch (e) {
      print('❌ TripLogsService: Exception while exporting trip logs: $e');
      return ApiResponse<String>.error('Failed to export trip logs: $e');
    }
  }
}
