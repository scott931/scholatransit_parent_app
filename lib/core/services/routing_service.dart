import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class RoutingService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5';
  static const String _profile =
      'driving'; // Use driving profile for road-based routing

  /// Get route coordinates between two points using Mapbox Directions API
  static Future<List<Map<String, double>>?> getRouteCoordinates({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      print(
        '🗺️ Routing Service: Getting route from ($startLat, $startLng) to ($endLat, $endLng)',
      );

      // Construct the API URL
      final coordinates = '$startLng,$startLat;$endLng,$endLat';
      final url =
          '$_baseUrl/mapbox/$_profile/$coordinates?access_token=${AppConfig.mapboxToken}&geometries=polyline&overview=full';

      print('🌐 Routing Service: Making request to: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          if (geometry != null) {
            // Decode the polyline geometry to get coordinate list
            final coordinates = _decodePolyline(geometry);
            print(
              '✅ Routing Service: Route found with ${coordinates.length} points',
            );
            return coordinates;
          }
        }

        print('⚠️ Routing Service: No route found in response');
        return null;
      } else {
        print(
          '❌ Routing Service: API request failed with status ${response.statusCode}',
        );
        print('❌ Routing Service: Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Routing Service: Error getting route: $e');
      return null;
    }
  }

  /// Road-following route through an ordered list of waypoints (e.g. the stops
  /// of a bus route). Returns the decoded polyline plus distance/duration, or
  /// null when routing is unavailable.
  static Future<RouteInfo?> getRouteThroughWaypoints(
    List<Map<String, double>> waypoints,
  ) async {
    if (waypoints.length < 2) return null;
    // Mapbox Directions allows up to 25 coordinates; keep first..last if more.
    final pts = waypoints.length > 25
        ? [...waypoints.sublist(0, 24), waypoints.last]
        : waypoints;
    try {
      final coordinates =
          pts.map((p) => '${p['longitude']},${p['latitude']}').join(';');
      final url =
          '$_baseUrl/mapbox/$_profile/$coordinates'
          '?access_token=${AppConfig.mapboxToken}&geometries=polyline&overview=full';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        print('⚠️ Waypoint routing failed: HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final geometry = route['geometry'];
        if (geometry is String && geometry.isNotEmpty) {
          final coords = _decodePolyline(geometry);
          if (coords.isNotEmpty) {
            return RouteInfo(
              coordinates: coords,
              distance: route['distance']?.toDouble() ?? 0.0,
              duration: route['duration']?.toDouble() ?? 0.0,
            );
          }
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Waypoint routing error: $e');
      return null;
    }
  }

  /// Snap a short sequence of raw GPS points to the road network using the
  /// Mapbox Map Matching API. Returns the matched coordinate list (lat/lng) or
  /// null when matching is unavailable. Used for Uber-style road-following of
  /// the live vehicle marker between consecutive position updates.
  static Future<List<Map<String, double>>?> getSnappedPath(
    List<Map<String, double>> points,
  ) async {
    if (points.length < 2) return null;
    // Map Matching accepts up to 100 coordinates; keep the most recent tail.
    final trimmed = points.length > 25
        ? points.sublist(points.length - 25)
        : points;
    try {
      final coordinates = trimmed
          .map((p) => '${p['longitude']},${p['latitude']}')
          .join(';');
      final url =
          'https://api.mapbox.com/matching/v5/mapbox/driving/$coordinates'
          '?access_token=${AppConfig.mapboxToken}&geometries=polyline&overview=full';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        print('⚠️ Map Matching failed: HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final matchings = data['matchings'];
      if (matchings is List && matchings.isNotEmpty) {
        final geometry = matchings[0]['geometry'];
        if (geometry is String && geometry.isNotEmpty) {
          final decoded = _decodePolyline(geometry);
          if (decoded.length >= 2) return decoded;
        }
      }
      return null;
    } catch (e) {
      print('⚠️ Map Matching error: $e');
      return null;
    }
  }

  /// Decode Mapbox polyline geometry to coordinate list.
  static List<Map<String, double>> decodePolyline(String encoded) {
    return _decodePolyline(encoded);
  }

  /// Decode Mapbox polyline geometry to coordinate list
  static List<Map<String, double>> _decodePolyline(String encoded) {
    final List<Map<String, double>> coordinates = [];

    try {
      int index = 0;
      int lat = 0;
      int lng = 0;

      while (index < encoded.length) {
        int b, shift = 0, result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        coordinates.add({'latitude': lat / 1e5, 'longitude': lng / 1e5});
      }
    } catch (e) {
      print('❌ Routing Service: Error decoding polyline: $e');
    }

    return coordinates;
  }

  /// Get route with additional information (distance, duration, etc.)
  static Future<RouteInfo?> getRouteInfo({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      print(
        '🗺️ Routing Service: Getting detailed route info from ($startLat, $startLng) to ($endLat, $endLng)',
      );

      final coordinates = '$startLng,$startLat;$endLng,$endLat';
      final url =
          '$_baseUrl/mapbox/$_profile/$coordinates?access_token=${AppConfig.mapboxToken}&geometries=polyline&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          if (geometry != null) {
            final coordinates = _decodePolyline(geometry);
            final distance = route['distance']?.toDouble() ?? 0.0; // in meters
            final duration = route['duration']?.toDouble() ?? 0.0; // in seconds

            print(
              '✅ Routing Service: Route info - Distance: ${(distance / 1000).toStringAsFixed(2)}km, Duration: ${(duration / 60).toStringAsFixed(1)}min',
            );

            return RouteInfo(
              coordinates: coordinates,
              distance: distance,
              duration: duration,
            );
          }
        }

        print('⚠️ Routing Service: No route found in response');
        return null;
      } else {
        print(
          '❌ Routing Service: API request failed with status ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Routing Service: Error getting route info: $e');
      return null;
    }
  }
}

class RouteInfo {
  final List<Map<String, double>> coordinates;
  final double distance; // in meters
  final double duration; // in seconds

  RouteInfo({
    required this.coordinates,
    required this.distance,
    required this.duration,
  });
}
