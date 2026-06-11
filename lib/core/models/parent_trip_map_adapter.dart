import 'parent_trip_model.dart' as parent;
import 'trip_model.dart';

/// Converts a [parent.ParentTrip] into the shared [Trip] model used by the map
/// layer, without requiring the parent flow to depend on driver [tripProvider].
extension ParentTripMapAdapter on parent.ParentTrip {
  Trip toMapTrip() {
    final validStops = stops
        .where((s) => s.latitude != 0.0 || s.longitude != 0.0)
        .toList();
    final firstStop = validStops.isNotEmpty ? validStops.first : null;
    final lastStop = validStops.length > 1 ? validStops.last : firstStop;

    return Trip(
      id: id,
      tripId: backendTripId.isNotEmpty ? backendTripId : id.toString(),
      driverId: driverId ?? 0,
      driverName: driverName.isNotEmpty ? driverName : null,
      vehicleId: vehicleId,
      vehicleName: busNumber,
      routeId: routeId,
      routeName: routeName.isNotEmpty ? routeName : null,
      status: _mapStatus(status),
      type: TripType.scheduled,
      scheduledStart: scheduledStartTime,
      scheduledEnd: scheduledEndTime,
      actualStart: actualStartTime,
      actualEnd: actualEndTime,
      startLocation: firstStop?.name,
      endLocation: lastStop?.name,
      currentLocation: currentAddress,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      startLatitude: firstStop?.latitude,
      startLongitude: firstStop?.longitude,
      endLatitude: lastStop?.latitude,
      endLongitude: lastStop?.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Ordered stop coordinates for drawing the planned route polyline.
  List<Map<String, double>> get stopCoordinates {
    return stops
        .where((s) => s.latitude != 0.0 || s.longitude != 0.0)
        .map(
          (s) => {'latitude': s.latitude, 'longitude': s.longitude},
        )
        .toList();
  }

  TripStatus _mapStatus(parent.TripStatus status) {
    switch (status) {
      case parent.TripStatus.scheduled:
        return TripStatus.pending;
      case parent.TripStatus.inProgress:
        return TripStatus.inProgress;
      case parent.TripStatus.completed:
        return TripStatus.completed;
      case parent.TripStatus.cancelled:
        return TripStatus.cancelled;
      case parent.TripStatus.delayed:
        return TripStatus.delayed;
    }
  }
}
