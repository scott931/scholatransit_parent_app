import 'package:geolocator/geolocator.dart';
import 'consolidated_location_service.dart';

/// Legacy LocationService - now uses ConsolidatedLocationService internally
/// Maintains backward compatibility while using the improved implementation
class LocationService {
  static Stream<Position> get locationStream =>
      ConsolidatedLocationService.locationStream;
  static Position? get currentPosition =>
      ConsolidatedLocationService.currentPosition;

  static Future<void> init() async {
    await ConsolidatedLocationService.init();
  }

  static Future<Position?> getCurrentPosition() async {
    return await ConsolidatedLocationService.getCurrentPosition();
  }

  static Future<void> startLocationTracking() async {
    await ConsolidatedLocationService.startLocationTracking();
  }

  static Future<void> stopLocationTracking() async {
    await ConsolidatedLocationService.stopLocationTracking();
  }

  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    return await ConsolidatedLocationService.getAddressFromCoordinates(
      latitude,
      longitude,
    );
  }

  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    return await ConsolidatedLocationService.getCoordinatesFromAddress(address);
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return ConsolidatedLocationService.calculateDistance(
      lat1,
      lon1,
      lat2,
      lon2,
    );
  }

  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return ConsolidatedLocationService.calculateBearing(lat1, lon1, lat2, lon2);
  }

  static bool isLocationAccurate(Position position) {
    return ConsolidatedLocationService.isLocationAccurate(position);
  }

  static Future<void> dispose() async {
    await ConsolidatedLocationService.dispose();
  }
}
