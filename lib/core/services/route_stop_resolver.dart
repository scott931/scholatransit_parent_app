import 'package:geocoding/geocoding.dart' as geocoding;
import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/parent_trip_model.dart';
import '../models/trip_model.dart';
import '../utils/coordinate_utils.dart';
import 'api_service.dart';
import 'routing_service.dart';

/// Resolves ordered lat/lng points for drawing a route polyline on the parent map.
class RouteStopResolver {
  static Future<List<Map<String, double>>> resolve({
    ParentTrip? parentTrip,
    Trip? mapTrip,
    int? hintRouteId,
  }) async {
    if (parentTrip != null) {
      final embedded = _stopsToCoordinates(parentTrip.stops);
      if (embedded.length >= 2) {
        print('🗺️ Route stops: ${embedded.length} from parent trip embed');
        return embedded;
      }
    }

    final routeIds = <int>{};
    void addRouteId(int? id) {
      if (id != null && id > 0) routeIds.add(id);
    }

    addRouteId(parentTrip?.routeId);
    addRouteId(mapTrip?.routeId);
    addRouteId(hintRouteId);

    for (final routeId in routeIds) {
      final routeStops = await fetchRouteStopCoordinates(routeId);
      if (routeStops.length >= 2) {
        print('🗺️ Route stops: ${routeStops.length} from route $routeId');
        return routeStops;
      }
    }

    final backendTripId = parentTrip?.backendTripId ?? mapTrip?.tripId;
    if (backendTripId != null && backendTripId.isNotEmpty) {
      final details = await _fetchTripDetails(backendTripId);
      if (details != null) {
        final detailStops = _stopsToCoordinates(details.stops);
        if (detailStops.length >= 2) {
          print('🗺️ Route stops: ${detailStops.length} from trip details');
          return detailStops;
        }
        addRouteId(details.routeId);
        for (final routeId in routeIds) {
          final routeStops = await fetchRouteStopCoordinates(routeId);
          if (routeStops.length >= 2) {
            print(
              '🗺️ Route stops: ${routeStops.length} from trip-detail route $routeId',
            );
            return routeStops;
          }
        }
      }

      // Parent-accessible final source: the trip route endpoint exposes ordered
      // stop addresses (but not coordinates) even when /routes/ is forbidden.
      // Geocode those addresses so the route line can still be drawn.
      final geocoded = await _resolveFromTripRouteAddresses(backendTripId);
      if (geocoded.length >= 2) {
        print(
          '🗺️ Route stops: ${geocoded.length} from geocoded trip route addresses',
        );
        return geocoded;
      }
    }

    if (mapTrip != null &&
        mapTrip.startLatitude != null &&
        mapTrip.startLongitude != null &&
        mapTrip.endLatitude != null &&
        mapTrip.endLongitude != null) {
      print('🗺️ Route stops: 2 from trip start/end fallback');
      return [
        {
          'latitude': mapTrip.startLatitude!,
          'longitude': mapTrip.startLongitude!,
        },
        {
          'latitude': mapTrip.endLatitude!,
          'longitude': mapTrip.endLongitude!,
        },
      ];
    }

    print('⚠️ Route stops: none resolved');
    return [];
  }

  /// Full stop records from `/routes/{id}/stops/` (id, coordinates, stop_type).
  static Future<List<Map<String, dynamic>>> fetchRouteStopDetails(
    int routeId,
  ) async {
    try {
      final response = await ApiService.get<dynamic>(
        ApiEndpoints.routeStops(routeId),
      );
      if (!response.success || response.data == null) return [];

      final raw = response.data;
      if (raw is! List) return [];

      final stops = raw
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList()
        ..sort(
          (a, b) => ((a['order'] as num?)?.toInt() ?? 0)
              .compareTo((b['order'] as num?)?.toInt() ?? 0),
        );
      return stops;
    } catch (e) {
      print('⚠️ Route stop details fetch failed for route $routeId: $e');
      return [];
    }
  }

  static Future<List<Map<String, double>>> fetchRouteStopCoordinates(
    int routeId,
  ) async {
    // `/routes/{id}/stops/` is parent-accessible and returns lat/lng directly.
    final paths = <String>[
      ApiEndpoints.routeStops(routeId),
      ApiEndpoints.routeDetails(routeId),
      '${AppConfig.routesListEndpoint}$routeId/',
      '${ApiEndpoints.routes}$routeId/',
    ];

    for (final path in paths) {
      final coords = await _fetchStopsFromEndpoint(path);
      if (coords.length >= 2) return coords;
    }
    return [];
  }

  static Future<List<Map<String, double>>> _fetchStopsFromEndpoint(
    String path,
  ) async {
    try {
      final response = await ApiService.get<dynamic>(path);
      if (!response.success || response.data == null) return [];

      final raw = response.data;
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        final polyline = data['polyline'] ?? data['geometry'] ?? data['route_geometry'];
        if (polyline is String && polyline.isNotEmpty) {
          final decoded = RoutingService.decodePolyline(polyline);
          if (decoded.length >= 2) return decoded;
        }

        for (final key in ['stops', 'route_stops', 'stop_list', 'results']) {
          final list = data[key];
          if (list is List) {
            final coords = _parseStopPayloadList(list);
            if (coords.length >= 2) return coords;
          }
        }
      } else if (raw is List) {
        return _parseStopPayloadList(raw);
      }
    } catch (e) {
      print('⚠️ Route stop fetch failed for $path: $e');
    }
    return [];
  }

  static List<Map<String, double>> _parseStopPayloadList(List list) {
    final maps = list
        .whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList()
      ..sort(
        (a, b) => ((a['order'] as num?)?.toInt() ??
                (a['stop_order'] as num?)?.toInt() ??
                (a['sequence'] as num?)?.toInt() ??
                0)
            .compareTo(
              (b['order'] as num?)?.toInt() ??
                  (b['stop_order'] as num?)?.toInt() ??
                  (b['sequence'] as num?)?.toInt() ??
                  0,
            ),
      );

    final coords = <Map<String, double>>[];
    for (final stop in maps) {
      final point = CoordinateUtils.fromStopJson(stop);
      if (point != null) coords.add(point);
    }
    return coords;
  }

  static List<Map<String, double>> _stopsToCoordinates(List<TripStop> stops) {
    return stops
        .map(
          (s) => CoordinateUtils.fromLatLngFields(s.latitude, s.longitude),
        )
        .whereType<Map<String, double>>()
        .toList();
  }

  /// Fetches the parent-accessible `/trips/{id}/route/` waypoints and resolves
  /// each to coordinates: using embedded lat/lng when present, otherwise
  /// geocoding the stop address. This is the only coordinate source available
  /// to parents when the `/routes/` endpoints are permission-restricted.
  static Future<List<Map<String, double>>> _resolveFromTripRouteAddresses(
    String backendTripId,
  ) async {
    try {
      final response = await ApiService.get<dynamic>(
        ApiEndpoints.tripRouteDetail(backendTripId),
      );
      if (!response.success || response.data is! Map) return [];

      final data = Map<String, dynamic>.from(response.data as Map);
      final waypoints = data['waypoints'];
      if (waypoints is! List) return [];

      final ordered = waypoints
          .whereType<Map>()
          .map((w) => Map<String, dynamic>.from(w))
          .toList()
        ..sort(
          (a, b) => ((a['order'] as num?)?.toInt() ?? 0)
              .compareTo((b['order'] as num?)?.toInt() ?? 0),
        );

      final coords = <Map<String, double>>[];
      for (final wp in ordered) {
        // Prefer explicit coordinates if the backend ever includes them.
        final direct = CoordinateUtils.fromStopJson(wp);
        if (direct != null) {
          coords.add(direct);
          continue;
        }
        final address = wp['address']?.toString();
        if (address == null || address.trim().isEmpty) continue;
        try {
          final results = await geocoding.locationFromAddress(address);
          if (results.isNotEmpty) {
            coords.add({
              'latitude': results.first.latitude,
              'longitude': results.first.longitude,
            });
          }
        } catch (_) {
          // Skip addresses that cannot be geocoded.
        }
      }
      return coords;
    } catch (e) {
      print('⚠️ Trip route address geocoding failed: $e');
      return [];
    }
  }

  static Future<ParentTrip?> _fetchTripDetails(String backendTripId) async {
    try {
      final response = await ApiService.get<dynamic>(
        ApiEndpoints.tripDetailsByBackendId(backendTripId),
      );
      if (!response.success || response.data is! Map) return null;
      return ParentTrip.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e) {
      print('⚠️ Trip details fetch failed: $e');
      return null;
    }
  }
}
