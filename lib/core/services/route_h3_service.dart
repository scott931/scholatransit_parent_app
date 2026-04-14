import 'package:h3_flutter_plus/h3_flutter_plus.dart';

/// H3 geospatial indexing service for route tracking.
/// Converts GPS coordinates to H3 cells for efficient spatial indexing and visualization.
class RouteH3Service {
  static H3? _h3;
  static const int routeResolution = 8;

  /// Resolution for vehicle/bus tracking (~0.02 km² per cell).
  /// Finer than route resolution for "bus near stop" queries.
  static const int vehicleResolution = 9;

  /// Initialize H3 (call once at app startup).
  static void initialize() {
    try {
      _h3 ??= const H3Factory().load();
    } catch (e) {
      print('❌ RouteH3Service: Failed to initialize H3: $e');
    }
  }

  /// Convert position to H3 cell index.
  static BigInt? positionToH3(double lat, double lng) {
    try {
      final h3 = _h3 ?? const H3Factory().load();
      _h3 ??= h3;
      return h3.latLngToCell(LatLng(lat: lat, lng: lng), routeResolution);
    } catch (e) {
      print('❌ RouteH3Service: Failed to convert position to H3: $e');
      return null;
    }
  }

  /// Convert position to H3 index as hex string (for backend/API).
  static String? positionToH3String(double lat, double lng) {
    final cell = positionToH3(lat, lng);
    if (cell == null) return null;
    try {
      return _h3!.h3ToString(cell);
    } catch (e) {
      return cell.toRadixString(16);
    }
  }

  /// Compact a list of cells for efficient transmission.
  static List<BigInt> compactCells(List<BigInt> cells) {
    if (cells.isEmpty) return [];
    try {
      return _h3?.compactCells(cells) ?? cells;
    } catch (e) {
      return cells;
    }
  }

  /// Get nearby cells (k-ring) for proximity queries.
  static List<BigInt> getNearbyCells(BigInt h3Index, int k) {
    try {
      return _h3?.gridDisk(h3Index, k) ?? [h3Index];
    } catch (e) {
      return [h3Index];
    }
  }

  // --- Vehicle / Bus tracking (H3 geospatial indexing) ---

  /// Convert vehicle/bus position to H3 cell for tracking.
  /// Uses [vehicleResolution] for finer granularity (~0.02 km²).
  static BigInt? positionToH3ForVehicle(double lat, double lng) {
    try {
      final h3 = _h3 ?? const H3Factory().load();
      _h3 ??= h3;
      return h3.latLngToCell(LatLng(lat: lat, lng: lng), vehicleResolution);
    } catch (e) {
      print('❌ RouteH3Service: Failed to convert vehicle position to H3: $e');
      return null;
    }
  }

  /// Convert vehicle position to H3 hex string (for backend/API storage).
  static String? positionToH3StringForVehicle(double lat, double lng) {
    final cell = positionToH3ForVehicle(lat, lng);
    if (cell == null) return null;
    try {
      return _h3!.h3ToString(cell);
    } catch (e) {
      return cell.toRadixString(16);
    }
  }

  /// Check if a position is within or adjacent to an H3 cell (proximity).
  static bool isNearH3Cell(double lat, double lng, BigInt h3Cell, {int k = 1}) {
    try {
      final posCell = positionToH3ForVehicle(lat, lng);
      if (posCell == null) return false;
      final nearby = getNearbyCells(h3Cell, k);
      return nearby.contains(posCell);
    } catch (e) {
      return false;
    }
  }
}
