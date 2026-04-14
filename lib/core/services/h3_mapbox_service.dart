import 'package:h3_flutter_plus/h3_flutter_plus.dart';

/// Converts H3 cells to GeoJSON for Mapbox FillLayer visualization.
class H3MapboxService {
  static final H3 _h3 = const H3Factory().load();

  /// Convert a list of H3 cells to GeoJSON FeatureCollection.
  /// Returns a Map suitable for jsonEncode.
  static Map<String, dynamic> cellsToGeoJson(List<BigInt> cells) {
    if (cells.isEmpty) {
      return {
        'type': 'FeatureCollection',
        'features': <Map<String, dynamic>>[],
      };
    }

    final features = <Map<String, dynamic>>[];

    for (final cell in cells) {
      try {
        final boundary = _h3.cellToBoundary(cell);
        if (boundary.isEmpty) continue;

        // GeoJSON uses [lng, lat] order; H3 LatLng has lat, lng
        final coordinates = boundary
            .map((p) => [p.lng, p.lat])
            .toList();

        // Close the polygon (first point = last point)
        final first = coordinates.first;
        final last = coordinates.last;
        if (first[0] != last[0] || first[1] != last[1]) {
          coordinates.add([first[0], first[1]]);
        }

        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [coordinates],
          },
          'properties': {},
        });
      } catch (e) {
        // Skip invalid cells
        continue;
      }
    }

    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }
}
