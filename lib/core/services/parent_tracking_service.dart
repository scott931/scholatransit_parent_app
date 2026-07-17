import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/parent_model.dart';
import '../models/parent_trip_model.dart';
import '../models/trip_log_model.dart';
import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/trip_model.dart' show Trip;
import '../utils/coordinate_utils.dart';
import 'api_service.dart';
import 'route_stop_resolver.dart';

class ParentTrackingService {
  static Timer? _tripPollTimer;
  static String? _trackingTripId;
  static ParentTrip? _cachedTripDetails;
  static int _pollTick = 0;
  /// Full trip details are refetched every Nth status poll (status is light,
  /// details are heavy — no need for both every 3 s).
  static const int _detailsEveryNTicks = 5;
  static final StreamController<ParentTrip> _tripController =
      StreamController<ParentTrip>.broadcast();
  static final StreamController<Map<String, dynamic>> _etaController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<ParentTrip> get tripStream => _tripController.stream;
  static Stream<Map<String, dynamic>> get etaStream => _etaController.stream;

  /// Normalize any tracking trips API payload into raw maps for [ParentTrip].
  static List<Map<String, dynamic>> extractTripPayloads(dynamic data) {
    final maps = <Map<String, dynamic>>[];
    if (data == null) return maps;

    if (data is TripLogsResponse) {
      for (final log in data.results) {
        maps.add(log.toParentTripJson());
      }
      if (maps.isEmpty && data.count > 0) {
        print(
          '⚠️ TripLogsResponse count=${data.count} but 0 parsed results — '
          'check TripLog.fromJson field types',
        );
      }
      return maps;
    }

    List<dynamic> items = [];
    if (data is List) {
      items = data;
    } else if (data is Map) {
      final raw = data['trips'] ?? data['results'];
      if (raw is List) items = raw;
    }

    for (final item in items) {
      if (item is Map) {
        maps.add(Map<String, dynamic>.from(item));
      }
    }
    return maps;
  }

  static bool _isRelevantParentTripStatus(dynamic status) {
    final s = status?.toString().toLowerCase().replaceAll(' ', '_') ?? '';
    if (s.contains('complet') || s.contains('cancel')) return false;
    return s == 'scheduled' ||
        s == 'in_progress' ||
        s == 'inprogress' ||
        s == 'delayed' ||
        s.contains('progress') ||
        s.contains('schedul') ||
        s.contains('delay');
  }

  /// Live + scheduled trips for the authenticated parent (backend-scoped).
  /// Uses a single list request to avoid parallel calls that trigger 429 throttling.
  static Future<ApiResponse<dynamic>> getActiveTrips() async {
    final listResponse = await ApiService.get<dynamic>(
      ApiEndpoints.parentActiveTrips,
      queryParameters: {'page_size': 50},
    );

    if (listResponse.success && listResponse.data != null) {
      final all = extractTripPayloads(listResponse.data);
      final relevant = all
          .where((t) => _isRelevantParentTripStatus(t['status']))
          .toList();
      final trips = relevant.isNotEmpty ? relevant : all;

      print(
        '🚌 Parent trips list: total=${all.length}, relevant=${relevant.length}',
      );

      if (trips.isNotEmpty) {
        return ApiResponse.success({'trips': trips}, listResponse.statusCode);
      }
    }

    // Fallback when the list is empty or failed — one lightweight active call.
    final activeResponse = await ApiService.get<dynamic>(
      ApiEndpoints.activeTrips,
    );
    if (activeResponse.success) {
      final activeCount = extractTripPayloads(activeResponse.data).length;
      print('🚌 Active trips fallback: $activeCount');
      return activeResponse;
    }

    return listResponse;
  }

  /// Fetch the ordered stop coordinates for a route, used to draw the route
  /// line on the map. Returns an empty list when unavailable.
  static Future<List<Map<String, double>>> getRouteStopCoordinates(
    int routeId,
  ) async {
    return RouteStopResolver.fetchRouteStopCoordinates(routeId);
  }

  /// Resolve ordered stop coordinates for drawing a route line on the parent map.
  static Future<List<Map<String, double>>> resolveRouteStopCoordinates({
    ParentTrip? parentTrip,
    Trip? mapTrip,
    int? hintRouteId,
  }) async {
    return RouteStopResolver.resolve(
      parentTrip: parentTrip,
      mapTrip: mapTrip,
      hintRouteId: hintRouteId,
    );
  }

  /// Get the latest GPS position for a trip (lightweight real-time feed).
  /// Returns lat/lng plus device-reported speed, heading and `last_update`.
  static Future<ApiResponse<Map<String, dynamic>>> getTripRealtimeStatus(
    String backendTripId,
  ) async {
    final response = await ApiService.get<dynamic>(
      ApiEndpoints.tripRealtimeStatus(backendTripId),
    );
    if (!response.success || response.data == null) {
      return ApiResponse<Map<String, dynamic>>.error(
        response.error ?? 'Failed to load trip status',
      );
    }
    final raw = response.data;
    if (raw is Map) {
      return ApiResponse<Map<String, dynamic>>.success(
        Map<String, dynamic>.from(raw),
        response.statusCode,
      );
    }
    return ApiResponse<Map<String, dynamic>>.error(
      'Unexpected trip status payload',
    );
  }

  /// Get trip details with real-time location (`backendTripId` = API `trip_id` string).
  static Future<ApiResponse<ParentTrip>> getTripDetails(
    String backendTripId,
  ) async {
    final response = await ApiService.get<dynamic>(
      ApiEndpoints.tripDetailsByBackendId(backendTripId),
    );
    if (!response.success || response.data == null) {
      return ApiResponse<ParentTrip>.error(
        response.error ?? 'Failed to load trip details',
      );
    }

    final raw = response.data;
    if (raw is Map) {
      try {
        final trip = ParentTrip.fromJson(Map<String, dynamic>.from(raw));
        return ApiResponse<ParentTrip>.success(trip, response.statusCode);
      } catch (e) {
        return ApiResponse<ParentTrip>.error('Invalid trip details format: $e');
      }
    }

    return ApiResponse<ParentTrip>.error('Unexpected trip details payload');
  }

  /// Start read-only live tracking — polls backend `/status/` (driver posts GPS).
  static Future<bool> startTripTracking(String backendTripId) async {
    try {
      await stopTripTracking();
      _trackingTripId = backendTripId;
      _tripPollTimer = Timer.periodic(
        Duration(seconds: AppConfig.parentLiveTrackingPollSeconds),
        (_) => _pollTripLocation(backendTripId),
      );
      await _pollTripLocation(backendTripId);
      return true;
    } catch (e) {
      print('❌ Failed to start trip tracking: $e');
      return false;
    }
  }

  /// Stop polling the backend for live trip updates.
  static Future<void> stopTripTracking() async {
    _tripPollTimer?.cancel();
    _tripPollTimer = null;
    _trackingTripId = null;
    _cachedTripDetails = null;
    _pollTick = 0;
  }

  static Future<void> _pollTripLocation(String backendTripId) async {
    if (_trackingTripId != backendTripId) return;

    try {
      final statusResponse = await getTripRealtimeStatus(backendTripId);

      // Full details are heavier — refresh them on the first tick and then
      // every Nth poll; the light /status/ payload carries GPS + next stop.
      if (_cachedTripDetails == null || _pollTick % _detailsEveryNTicks == 0) {
        final detailsResponse = await getTripDetails(backendTripId);
        if (detailsResponse.success && detailsResponse.data != null) {
          _cachedTripDetails = detailsResponse.data!;
        }
      }
      _pollTick++;
      if (_cachedTripDetails == null) return;

      var trip = _cachedTripDetails!;
      if (statusResponse.success && statusResponse.data != null) {
        final data = statusResponse.data!;
        final coords =
            CoordinateUtils.fromLatLngFields(
              data['latitude'] ?? data['current_latitude'],
              data['longitude'] ?? data['current_longitude'],
            ) ??
            CoordinateUtils.fromLocationValue(data['current_location']);
        final lat = coords?['latitude'];
        final lng = coords?['longitude'];
        final isActive = data['is_active'] is bool
            ? data['is_active'] as bool
            : data['is_active']?.toString().toLowerCase() == 'true';

        // Backend now reports the stop the driver is heading to, with
        // distance and a speed-aware ETA — prefer it over local guesses.
        final nextStop = data['next_stop'] is Map
            ? Map<String, dynamic>.from(data['next_stop'] as Map)
            : null;
        final backendEtaSeconds = (nextStop?['eta_seconds'] as num?)?.toInt();

        // Road geometry the bus is actually driving to reach that stop. The
        // server owns it, so the line here matches the driver's and the
        // backoffice's exactly, and re-routes when the driver goes off-road.
        final navigation = data['navigation'] is Map
            ? Map<String, dynamic>.from(data['navigation'] as Map)
            : null;

        if (lat != null && lng != null) {
          final eta = backendEtaSeconds != null
              ? (backendEtaSeconds / 60).ceil()
              : await _calculateETAFromCoords(lat, lng, trip);
          trip = trip.copyWith(
            currentLatitude: lat,
            currentLongitude: lng,
            lastLocationUpdate:
                DateTime.tryParse(data['last_update']?.toString() ?? '') ??
                DateTime.now(),
            estimatedArrivalMinutes: eta,
            isActiveFromApi: isActive,
          );

          _etaController.add({
            'trip_id': backendTripId,
            'eta_minutes': eta,
            'current_location': {'latitude': lat, 'longitude': lng},
            'speed': data['speed'],
            'heading': data['heading'],
            if (nextStop != null) 'next_stop': nextStop,
            if (navigation != null) 'navigation': navigation,
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else if (isActive) {
          trip = trip.copyWith(isActiveFromApi: isActive);
        }
      }

      _tripController.add(trip);
    } catch (e) {
      print('❌ Failed to poll trip location: $e');
    }
  }

  static Future<int> _calculateETAFromCoords(
    double lat,
    double lng,
    ParentTrip trip,
  ) async {
    try {
      if (trip.stops.isEmpty) return 0;

      final nextStop = trip.stops.firstWhere(
        (stop) => !stop.isCompleted,
        orElse: () => trip.stops.last,
      );

      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        nextStop.latitude,
        nextStop.longitude,
      );

      return (distance / 500).round().clamp(0, 120);
    } catch (e) {
      print('❌ Failed to calculate ETA: $e');
      return 0;
    }
  }

  /// Get trip history for parent's children.
  /// Backend filters by `status` and DRF `page_size` — not by date range.
  static Future<ApiResponse<dynamic>> getTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      'status': 'completed',
      if (limit != null) 'page_size': limit,
    };

    final response = await ApiService.get<dynamic>(
      ApiEndpoints.parentTripHistory,
      queryParameters: queryParams,
    );

    if (!response.success ||
        response.data == null ||
        startDate == null && endDate == null) {
      return response;
    }

    // Client-side date filter — backend does not support start_date/end_date.
    final trips = extractTripPayloads(response.data);
    final filtered = trips.where((trip) {
      final raw =
          trip['actual_end'] ??
          trip['actual_end_time'] ??
          trip['scheduled_end'] ??
          trip['scheduled_end_time'];
      final end = DateTime.tryParse(raw?.toString() ?? '');
      if (end == null) return true;
      if (startDate != null && end.isBefore(startDate)) return false;
      if (endDate != null && end.isAfter(endDate)) return false;
      return true;
    }).toList();

    return ApiResponse.success({
      'results': filtered,
      'count': filtered.length,
    }, response.statusCode);
  }

  /// Get child's profile (includes current_trip from backend).
  static Future<ApiResponse<Map<String, dynamic>>> getChildStatus(
    int childId,
  ) async {
    return ApiService.get<Map<String, dynamic>>(
      ApiEndpoints.studentDetails(childId),
    );
  }

  /// Parents cannot list route detail — return stops with coordinates instead.
  static Future<ApiResponse<Map<String, dynamic>>> getRouteInfo(
    int routeId,
  ) async {
    final response = await ApiService.get<dynamic>(
      ApiEndpoints.routeStops(routeId),
    );
    if (!response.success) {
      return ApiResponse<Map<String, dynamic>>.error(
        response.error ?? 'Failed to load route stops',
      );
    }
    return ApiResponse<Map<String, dynamic>>.success({
      'id': routeId,
      'stops': response.data,
    }, response.statusCode);
  }

  /// Get driver information
  static Future<ApiResponse<Map<String, dynamic>>> getDriverInfo(
    int driverId,
  ) async {
    return ApiService.get<Map<String, dynamic>>(ApiEndpoints.profile);
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await stopTripTracking();
    await _tripController.close();
    await _etaController.close();
  }
}

// Extension to add copyWith method to ParentTrip
extension ParentTripCopyWith on ParentTrip {
  ParentTrip copyWith({
    int? id,
    String? backendTripId,
    String? tripName,
    String? routeName,
    int? routeId,
    int? driverId,
    int? vehicleId,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    TripStatus? status,
    List<Child>? children,
    String? busNumber,
    String? busColor,
    double? currentLatitude,
    double? currentLongitude,
    String? currentAddress,
    DateTime? lastLocationUpdate,
    int? estimatedArrivalMinutes,
    List<TripStop>? stops,
    bool? isActiveFromApi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentTrip(
      id: id ?? this.id,
      backendTripId: backendTripId ?? this.backendTripId,
      tripName: tripName ?? this.tripName,
      routeName: routeName ?? this.routeName,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      children: children ?? this.children,
      busNumber: busNumber ?? this.busNumber,
      busColor: busColor ?? this.busColor,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentAddress: currentAddress ?? this.currentAddress,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      stops: stops ?? this.stops,
      isActiveFromApi: isActiveFromApi ?? this.isActiveFromApi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
