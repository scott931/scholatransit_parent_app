import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/firestore_driver_location_service.dart';
import '../../core/services/firestore_parent_location_listener.dart';
import '../../core/models/firestore_location_update.dart';

/// ============================================================================
/// COMPLETE EXAMPLE: Real-time Location Sharing Between Driver and Parent Apps
/// ============================================================================
/// 
/// This file demonstrates how to implement real-time location sharing using
/// Cloud Firestore between two Flutter apps:
/// 
/// 1. DriverLocationExample - For the Driver app to share location
/// 2. ParentLocationTrackingExample - For the Parent app to receive location
/// 
/// SETUP REQUIREMENTS:
/// - Firebase project configured with Firestore
/// - Location permissions added to AndroidManifest.xml and Info.plist
/// - cloud_firestore and geolocator packages installed
/// 
/// USAGE:
/// - Driver app: Navigate to DriverLocationExample(driverId: 'your_driver_id')
/// - Parent app: Navigate to ParentLocationTrackingExample(driverId: 'driver_id')
/// 
/// ============================================================================

/// Example widget showing how to use FirestoreDriverLocationService
/// This would be used in the Driver app to share location in real-time
class DriverLocationExample extends StatefulWidget {
  final String driverId;

  const DriverLocationExample({
    super.key,
    required this.driverId,
  });

  @override
  State<DriverLocationExample> createState() => _DriverLocationExampleState();
}

class _DriverLocationExampleState extends State<DriverLocationExample> {
  late FirestoreDriverLocationService _locationService;
  FirestoreLocationUpdate? _currentLocation;
  bool _isTracking = false;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
  }

  void _initializeLocationService() {
    _locationService = FirestoreDriverLocationService(driverId: widget.driverId);
    
    // Callback when location is successfully updated to Firestore
    _locationService.onLocationUpdated = (location) {
      setState(() {
        _currentLocation = location;
        _updateMapMarker(location);
      });
    };
    
    // Callback when an error occurs
    _locationService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  void _updateMapMarker(FirestoreLocationUpdate location) {
    final marker = Marker(
      markerId: MarkerId(widget.driverId),
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(
        title: 'Your Location',
        snippet: 'Lat: ${location.latitude.toStringAsFixed(6)}, '
            'Lng: ${location.longitude.toStringAsFixed(6)}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });

    // Animate camera to new location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15.0,
      ),
    );
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopLocationUpdates();
      setState(() {
        _isTracking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location tracking stopped'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _locationService.startLocationUpdates();
      setState(() {
        _isTracking = _locationService.isTracking;
      });
      if (mounted && _isTracking) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location tracking started'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateLocationManually() async {
    // Example: Update to a test location (San Francisco)
    await _locationService.updateLocationManually(
      latitude: 37.7749,
      longitude: -122.4194,
      speed: 15.0,
      heading: 90.0,
      accuracy: 10.0,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual location update sent'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Location Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 2,
            child: _currentLocation != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                      ),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Waiting for location...'),
                      ],
                    ),
                  ),
          ),
          
          // Status and Controls
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isTracking ? Icons.location_on : Icons.location_off,
                                color: _isTracking ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Driver ID: ${widget.driverId}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isTracking ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${_isTracking ? "Tracking Active" : "Stopped"}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _isTracking ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location Details Card
                  if (_currentLocation != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Divider(),
                            _buildLocationDetail(
                              'Latitude',
                              _currentLocation!.latitude.toStringAsFixed(6),
                            ),
                            _buildLocationDetail(
                              'Longitude',
                              _currentLocation!.longitude.toStringAsFixed(6),
                            ),
                            if (_currentLocation!.speed != null)
                              _buildLocationDetail(
                                'Speed',
                                '${_currentLocation!.speed!.toStringAsFixed(2)} m/s',
                              ),
                            if (_currentLocation!.heading != null)
                              _buildLocationDetail(
                                'Heading',
                                '${_currentLocation!.heading!.toStringAsFixed(2)}°',
                              ),
                            if (_currentLocation!.accuracy != null)
                              _buildLocationDetail(
                                'Accuracy',
                                '${_currentLocation!.accuracy!.toStringAsFixed(2)} m',
                              ),
                            const Divider(),
                            Text(
                              'Updated: ${_formatTimestamp(_currentLocation!.timestamp)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('No location data yet'),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Control Buttons
                  ElevatedButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _updateLocationManually,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Update Location Manually (Test)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

/// Example widget showing how to use FirestoreParentLocationListener
/// This would be used in the Parent app to receive real-time driver location
class ParentLocationTrackingExample extends StatefulWidget {
  final String driverId;

  const ParentLocationTrackingExample({
    super.key,
    required this.driverId,
  });

  @override
  State<ParentLocationTrackingExample> createState() =>
      _ParentLocationTrackingExampleState();
}

class _ParentLocationTrackingExampleState
    extends State<ParentLocationTrackingExample> {
  late FirestoreParentLocationListener _locationListener;
  FirestoreLocationUpdate? _driverLocation;
  bool _isListening = false;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocationListener();
  }

  void _initializeLocationListener() {
    _locationListener = FirestoreParentLocationListener();
    
    // Callback when a location update is received from Firestore
    _locationListener.onLocationReceived = (location) {
      setState(() {
        _driverLocation = location;
        _updateMapMarker(location);
      });
    };
    
    // Callback when a driver's location is removed
    _locationListener.onLocationRemoved = (driverId) {
      setState(() {
        _driverLocation = null;
        _markers.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver $driverId location no longer available'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
    
    // Callback when an error occurs
    _locationListener.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  void _updateMapMarker(FirestoreLocationUpdate location) {
    final marker = Marker(
      markerId: MarkerId(widget.driverId),
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(
        title: 'Driver Location',
        snippet: 'Lat: ${location.latitude.toStringAsFixed(6)}, '
            'Lng: ${location.longitude.toStringAsFixed(6)}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });

    // Animate camera to driver location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15.0,
      ),
    );
  }

  void _startListening() {
    _locationListener.listenToDriverLocation(widget.driverId);
    setState(() {
      _isListening = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Started listening to driver location'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _stopListening() {
    _locationListener.stopListening();
    setState(() {
      _isListening = false;
      _driverLocation = null;
      _markers.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stopped listening to driver location'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = await _locationListener.getDriverLocation(widget.driverId);
    if (location != null) {
      setState(() {
        _driverLocation = location;
        _updateMapMarker(location);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver location retrieved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver location not available'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationListener.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Driver Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map View
          Expanded(
            flex: 2,
            child: _driverLocation != null
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _driverLocation!.latitude,
                        _driverLocation!.longitude,
                      ),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No driver location available'),
                        SizedBox(height: 8),
                        Text(
                          'Start listening to receive updates',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Status and Controls
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isListening ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: _isListening ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tracking Driver: ${widget.driverId}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${_isListening ? "Listening" : "Stopped"}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _isListening ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location Details Card
                  if (_driverLocation != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver Location',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Divider(),
                            _buildLocationDetail(
                              'Latitude',
                              _driverLocation!.latitude.toStringAsFixed(6),
                            ),
                            _buildLocationDetail(
                              'Longitude',
                              _driverLocation!.longitude.toStringAsFixed(6),
                            ),
                            if (_driverLocation!.speed != null)
                              _buildLocationDetail(
                                'Speed',
                                '${_driverLocation!.speed!.toStringAsFixed(2)} m/s',
                              ),
                            if (_driverLocation!.heading != null)
                              _buildLocationDetail(
                                'Heading',
                                '${_driverLocation!.heading!.toStringAsFixed(2)}°',
                              ),
                            if (_driverLocation!.accuracy != null)
                              _buildLocationDetail(
                                'Accuracy',
                                '${_driverLocation!.accuracy!.toStringAsFixed(2)} m',
                              ),
                            const Divider(),
                            Text(
                              'Updated: ${_formatTimestamp(_driverLocation!.timestamp)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('No location data available'),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Control Buttons
                  ElevatedButton.icon(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
                    label: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Get Current Location (One-time)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

/// Example showing how to track multiple drivers
class MultiDriverTrackingExample extends StatefulWidget {
  final List<String> driverIds;

  const MultiDriverTrackingExample({
    super.key,
    required this.driverIds,
  });

  @override
  State<MultiDriverTrackingExample> createState() =>
      _MultiDriverTrackingExampleState();
}

class _MultiDriverTrackingExampleState
    extends State<MultiDriverTrackingExample> {
  late FirestoreParentLocationListener _locationListener;
  final Map<String, FirestoreLocationUpdate> _driverLocations = {};
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _locationListener = FirestoreParentLocationListener();
    _locationListener.onLocationReceived = (location) {
      setState(() {
        _driverLocations[location.driverId] = location;
      });
    };
    _locationListener.onLocationRemoved = (driverId) {
      setState(() {
        _driverLocations.remove(driverId);
      });
    };
    _locationListener.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    };
  }

  void _startListening() {
    _locationListener.listenToMultipleDrivers(widget.driverIds);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() {
    _locationListener.stopListening();
    setState(() {
      _isListening = false;
      _driverLocations.clear();
    });
  }

  @override
  void dispose() {
    _locationListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Multiple Drivers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _driverLocations.length,
              itemBuilder: (context, index) {
                final location = _driverLocations.values.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Driver: ${location.driverId}'),
                    subtitle: Text(
                      'Lat: ${location.latitude.toStringAsFixed(6)}, '
                      'Lng: ${location.longitude.toStringAsFixed(6)}',
                    ),
                    trailing: Icon(Icons.location_on, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
