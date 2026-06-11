/// Shared helpers for extracting lat/lng from API payloads (WKT, GeoJSON, plain fields).
class CoordinateUtils {
  static int? parseRouteId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return parseRouteId(map['id'] ?? map['route_id'] ?? map['pk']);
    }
    return int.tryParse(value.toString());
  }

  static Map<String, double>? fromStopJson(Map<String, dynamic> json) {
    final direct = fromLatLngFields(
      json['latitude'],
      json['longitude'],
    );
    if (direct != null) return direct;

    return fromLocationValue(
      json['location'] ?? json['coordinates'] ?? json['point'],
    );
  }

  static Map<String, double>? fromLatLngFields(dynamic lat, dynamic lng) {
    final latitude = _toDouble(lat);
    final longitude = _toDouble(lng);
    if (latitude == null || longitude == null) return null;
    if (latitude == 0.0 && longitude == 0.0) return null;
    return {'latitude': latitude, 'longitude': longitude};
  }

  static Map<String, double>? fromLocationValue(dynamic value) {
    if (value == null) return null;

    final geo = _fromGeoJson(value);
    if (geo != null) return geo;

    if (value is String) {
      final wkt = _fromWkt(value);
      if (wkt != null) return wkt;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final nested = fromLatLngFields(map['latitude'], map['longitude']);
      if (nested != null) return nested;
      if (map['coordinates'] != null) {
        return fromLocationValue(map['coordinates']);
      }
    }

    return null;
  }

  static Map<String, double>? _fromGeoJson(dynamic value) {
    if (value is! Map) return null;
    final coords = value['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final longitude = _toDouble(coords[0]);
    final latitude = _toDouble(coords[1]);
    if (latitude == null || longitude == null) return null;
    return {'latitude': latitude, 'longitude': longitude};
  }

  static Map<String, double>? _fromWkt(String wkt) {
    final match = RegExp(
      r'POINT\s*\(([^)]+)\)',
      caseSensitive: false,
    ).firstMatch(wkt);
    if (match == null) return null;
    final parts = match.group(1)?.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.length < 2) return null;
    final longitude = double.tryParse(parts[0]);
    final latitude = double.tryParse(parts[1]);
    if (latitude == null || longitude == null) return null;
    return {'latitude': latitude, 'longitude': longitude};
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
