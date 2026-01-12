/// Data model for location updates shared via Firestore
class FirestoreLocationUpdate {
  final String driverId;
  final double latitude;
  final double longitude;
  final int timestamp;
  final double? speed;
  final double? heading;
  final double? accuracy;

  FirestoreLocationUpdate({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.heading,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }

  factory FirestoreLocationUpdate.fromMap(Map<String, dynamic> map) {
    return FirestoreLocationUpdate(
      driverId: map['driverId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'FirestoreLocationUpdate(driverId: $driverId, '
        'lat: $latitude, lng: $longitude, '
        'timestamp: $timestamp, speed: $speed, heading: $heading)';
  }
}
