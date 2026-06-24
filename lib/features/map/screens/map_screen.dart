import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/parent_trip_model.dart' show ParentTrip;
import '../../../core/models/parent_trip_map_adapter.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/route_stop_resolver.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/utils/name_abbreviation.dart';
import '../../../core/services/realtime_distance_tracker.dart';
import '../../../core/services/location_service_resolver.dart';
import '../../../core/services/communication_service.dart';
import '../../../core/services/parent_tracking_service.dart';
import '../../communication/screens/chat_list_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.pollActiveTrips = false});

  /// When true (e.g. parent live tracking), periodically refetch active trips so the bus position updates.
  final bool pollActiveTrips;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  MapboxMap? _mapboxMap;
  Point? _currentLocation;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _currentLocationAnnotation;
  PointAnnotation? _vehicleLocationAnnotation;
  PointAnnotation? _startLocationAnnotation;
  PointAnnotation? _endLocationAnnotation;
  final List<PointAnnotation> _studentPickupAnnotations = [];
  PolylineAnnotationManager? _polylineAnnotationManager;

  /// Separate manager so [setLineDasharray] does not affect the solid route line.
  PolylineAnnotationManager? _parentToStartPolylineManager;
  PolylineAnnotation? _routePolyline;
  PolylineAnnotation? _parentToStartPolyline;
  // Trip id whose planned (stop-based) route line is currently drawn, so the
  // static route is fetched/rendered once per trip instead of on every poll.
  String? _plannedRouteTripId;

  /// Cached route stop coordinates for the active trip (pickup polyline + dashed line).
  List<Map<String, double>>? _cachedRouteStops;
  ProviderSubscription<TripState>? _tripStateSubscription;
  ProviderSubscription<ParentState>? _parentStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _vehicleCoordinateSubscription;
  Timer? _vehicleAnimationTimer;
  Point? _lastVehiclePoint;
  double? _lastAcceptedVehicleLat;
  double? _lastAcceptedVehicleLng;
  double? _lastRenderedVehicleLat;
  double? _lastRenderedVehicleLng;
  bool _followVehicle = true;
  bool _isVehicleMarkerReady = false;
  bool _isCreatingVehicleMarker = false;
  bool _vehicleAnimationInProgress = false;
  static const double _vehicleCoordinateEpsilon = 1e-6;

  // ── Real-time vehicle feed (parent live tracking) ─────────────────────────
  Timer? _vehicleStatusPollTimer;
  Timer? _staleTicker;
  bool _isFetchingVehicleStatus = false;
  DateTime? _lastVehicleUpdateAt; // backend-reported last_update
  double? _lastVehicleHeading; // backend-reported heading (degrees)
  double? _lastVehicleSpeed; // backend-reported speed
  bool _isVehiclePositionStale = false;
  // Raw accepted GPS points used for map-matching / breadcrumb trail.
  final List<Map<String, double>> _rawVehicleTrack = [];
  final List<Point> _vehicleTrailPoints = [];
  PolylineAnnotation? _vehicleTrailPolyline;
  // Ignore GPS noise below this distance between consecutive fixes (meters).
  static const double _minVehicleMoveMeters = 5.0;
  // Position is considered stale if no fresh fix within this window.
  static const Duration _vehicleStaleThreshold = Duration(seconds: 20);

  // Map style
  final String _currentMapStyle = MapboxStyles.MAPBOX_STREETS;

  // Distance tracking variables
  double? _remainingDistance;
  double? _distanceTraveled;
  double? _totalTripDistance;
  double _progressPercentage = 0.0;
  Duration? _remainingTime;
  String? _currentStreetName;
  String? _destinationStreetName;
  final Map<String, String> _geocodeCache = {};

  // Route update throttling
  DateTime? _lastRouteUpdate;
  static const Duration _minRouteUpdateInterval = Duration(seconds: 3);

  // Location guidance
  String? _locationGuidance;
  bool _showLocationGuidance = false;

  // Message driver chat
  bool _isCreatingDriverChat = false;

  Timer? _activeTripPollTimer;

  /// Parent live map: prefer live/active trips; fall back to first listed trip.
  ParentTrip? _getParentTrackingTrip() {
    final trips = ref.read(parentProvider).activeTrips;
    if (trips.isEmpty) return null;

    final live = trips.where((t) => t.isActive).toList();
    if (live.isNotEmpty) return live.first;

    final trackable = trips.where((t) => t.isTrackable).toList();
    if (trackable.isNotEmpty) return trackable.first;

    return trips.first;
  }

  Trip? _getCurrentMapTrip() {
    if (widget.pollActiveTrips) {
      final parentTrip = _getParentTrackingTrip();
      final fallbackTrip = ref.read(tripProvider).currentTrip;
      if (parentTrip != null) {
        final mapped = parentTrip.toMapTrip();
        if (fallbackTrip == null) return mapped;
        // Merge sparse parent payloads with the active-trips endpoint fields.
        return mapped.copyWith(
          routeId: mapped.routeId ?? fallbackTrip.routeId,
          routeName: mapped.routeName ?? fallbackTrip.routeName,
          startLatitude: mapped.startLatitude ?? fallbackTrip.startLatitude,
          startLongitude: mapped.startLongitude ?? fallbackTrip.startLongitude,
          endLatitude: mapped.endLatitude ?? fallbackTrip.endLatitude,
          endLongitude: mapped.endLongitude ?? fallbackTrip.endLongitude,
          currentLatitude:
              mapped.currentLatitude ?? fallbackTrip.currentLatitude,
          currentLongitude:
              mapped.currentLongitude ?? fallbackTrip.currentLongitude,
        );
      }
      return fallbackTrip;
    }
    return ref.read(tripProvider).currentTrip;
  }

  TripState _getDisplayTripState() {
    if (!widget.pollActiveTrips) {
      return ref.watch(tripProvider);
    }
    ref.watch(parentProvider);
    ref.watch(tripProvider);
    final trip = _getCurrentMapTrip();
    if (trip == null) return const TripState();
    return TripState(currentTrip: trip, trips: [trip]);
  }

  Future<void> _loadTrackingTrips({bool force = false}) async {
    if (widget.pollActiveTrips) {
      // Students must load before trips so bootstrap from current/upcoming works.
      if (ref.read(parentProvider).students.isEmpty) {
        await ref.read(parentProvider.notifier).loadStudents();
      }
      await ref.read(parentProvider.notifier).loadActiveTrips(force: force);
      if (mounted && _routePolyline == null) {
        _loadTripRoute();
      }
    } else {
      await ref.read(tripProvider.notifier).loadActiveTrips();
    }
  }

  int? _hintRouteIdFromStudents() {
    for (final student in ref.read(parentProvider).students) {
      final routeId = student.assignedRoute;
      if (routeId != null && routeId > 0) return routeId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tripStateSubscription = ref.listenManual<TripState>(
      tripProvider,
      _onTripStateChanged,
    );
    if (widget.pollActiveTrips) {
      _parentStateSubscription = ref.listenManual<ParentState>(
        parentProvider,
        _onParentStateChanged,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // First paint: load immediately so the bus marker appears before the poll interval.
        _loadTrackingTrips(force: true);
      });
      _startParentTrackingTimers();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  /// Starts (or restarts) the trip-metadata poll, the lightweight real-time
  /// vehicle-status poll, and the staleness ticker for parent live tracking.
  void _startParentTrackingTimers() {
    if (!widget.pollActiveTrips) return;
    _stopParentTrackingTimers();

    final gpsPollInterval = Duration(
      seconds: AppConfig.parentLiveTrackingPollSeconds,
    );
    final tripPollInterval = Duration(
      seconds: AppConfig.parentTripMetadataPollSeconds,
    );

    // Trip metadata (route, status) — infrequent to avoid API throttling.
    _activeTripPollTimer = Timer.periodic(tripPollInterval, (_) {
      if (!mounted) return;
      _loadTrackingTrips();
    });

    // Real-time vehicle position feed (drives the moving marker).
    _vehicleStatusPollTimer = Timer.periodic(gpsPollInterval, (_) {
      if (!mounted) return;
      _pollVehicleRealtimeStatus();
    });
    // Kick off an immediate fetch so movement starts without waiting a cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pollVehicleRealtimeStatus();
    });

    // Re-evaluate "last updated" freshness once per second for the indicator.
    _staleTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _recomputeVehicleStaleness();
    });
  }

  void _stopParentTrackingTimers() {
    _activeTripPollTimer?.cancel();
    _activeTripPollTimer = null;
    _vehicleStatusPollTimer?.cancel();
    _vehicleStatusPollTimer = null;
    _staleTicker?.cancel();
    _staleTicker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.pollActiveTrips) return;

    if (state == AppLifecycleState.resumed) {
      // Resume polling and immediately refresh so the marker catches up.
      _startParentTrackingTimers();
      if (mounted) {
        _loadTrackingTrips();
        _pollVehicleRealtimeStatus();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Stop network + animation work while the map is not visible.
      _stopParentTrackingTimers();
      _vehicleAnimationTimer?.cancel();
      _vehicleAnimationTimer = null;
      _vehicleAnimationInProgress = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopParentTrackingTimers();
    _vehicleAnimationTimer?.cancel();
    _vehicleCoordinateSubscription?.cancel();
    _tripStateSubscription?.close();
    _parentStateSubscription?.close();
    super.dispose();
  }

  void _initializeMap() async {
    print('🗺️ DEBUG: Starting map initialization...');
    final t = AppConfig.mapboxToken;
    print(
      '🗺️ DEBUG: Mapbox token: ${t.length >= 8 ? '${t.substring(0, t.length.clamp(0, 20))}...' : '(not set)'}',
    );

    // Always set a default location first
    _currentLocation = Point(
      coordinates: Position(
        AppConfig.defaultLongitude,
        AppConfig.defaultLatitude,
      ),
    );

    print('🗺️ DEBUG: Default location set: ${_currentLocation?.coordinates}');

    // Trigger a rebuild to show the map
    if (mounted) {
      print('🗺️ DEBUG: Triggering setState to show map...');
      setState(() {});
    }

    // Try to get current location, but don't block map display
    try {
      final position = await LocationServiceResolver.getCurrentPosition();
      if (position != null) {
        _currentLocation = Point(
          coordinates: Position(position.longitude, position.latitude),
        );
        if (mounted) {
          setState(() {});
        }
        print('✅ Map initialized with current location');
        // Fly camera to the exact acquired GPS position
        if (_mapboxMap != null) {
          _mapboxMap!.flyTo(
            CameraOptions(center: _currentLocation!, zoom: 16.0),
            MapAnimationOptions(duration: 1200),
          );
        }
      } else {
        print('⚠️ Using default location - current position not available');
      }
    } catch (e) {
      print('❌ Failed to get current location: $e');
      print('🗺️ Map will show with default location');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = _getDisplayTripState();

    print(
      '🗺️ DEBUG: Building MapScreen - _currentLocation: $_currentLocation',
    );
    print('🗺️ DEBUG: MapboxMap: $_mapboxMap');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // Debug overlay to confirm MapScreen is rendering
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'MapScreen Active',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // Map - Always show the map
          _currentLocation == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing map...'),
                    ],
                  ),
                )
              : MapWidget(
                  key: const ValueKey("mapWidget"),
                  cameraOptions: CameraOptions(
                    center:
                        _currentLocation ??
                        Point(
                          coordinates: Position(
                            AppConfig.defaultLongitude,
                            AppConfig.defaultLatitude,
                          ),
                        ),
                    zoom: 15.0,
                  ),
                  styleUri: _currentMapStyle,
                  onMapCreated: (MapboxMap mapboxMap) async {
                    try {
                      print('🗺️ DEBUG: Map created successfully');
                      print('🗺️ DEBUG: MapboxMap instance: $mapboxMap');
                      _mapboxMap = mapboxMap;

                      // Create annotation managers
                      _pointAnnotationManager = await mapboxMap.annotations
                          .createPointAnnotationManager();
                      _polylineAnnotationManager = await mapboxMap.annotations
                          .createPolylineAnnotationManager();
                      _parentToStartPolylineManager = await mapboxMap
                          .annotations
                          .createPolylineAnnotationManager();
                      // Dash pattern applies to the whole manager — keep it isolated.
                      await _parentToStartPolylineManager!.setLineDasharray(
                        const [2.0, 2.5],
                      );
                      print('🗺️ DEBUG: Point annotation manager created');
                      print('🗺️ DEBUG: Polyline annotation manager created');

                      // Add markers
                      _addCurrentLocationMarker();

                      // Force load active trips and then add markers
                      print('🗺️ DEBUG: Loading active trips...');
                      await _loadTrackingTrips();

                      print('🗺️ DEBUG: Calling _loadTripRoute()...');
                      _loadTripRoute();

                      print('🗺️ DEBUG: Calling _addTripMarkers()...');
                      _addTripMarkers();

                      // Map style is already set via styleUri in MapWidget

                      print('✅ Map initialization completed successfully');
                    } catch (e) {
                      print('❌ Error in onMapCreated: $e');
                      print('❌ Stack trace: ${StackTrace.current}');
                      // Show error to user
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Map failed to load: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),

          // Live position freshness indicator (parent live tracking only)
          if (widget.pollActiveTrips && tripState.currentTrip != null)
            Positioned(
              bottom: 24.h,
              left: 0,
              right: 0,
              child: Center(child: _buildVehicleFreshnessChip()),
            ),

          // Map key for parent live tracking
          if (widget.pollActiveTrips && tripState.currentTrip != null)
            Positioned(top: 200.h, left: 16.w, child: _buildParentMapLegend()),

          // Trip Details Card - Show only when there's an active trip
          if (tripState.currentTrip != null)
            Positioned(
              top: 50.h,
              left: 16.w,
              right: 16.w,
              child: _TripDetailsCard(
                tripState: tripState,
                currentLocation: _currentLocation,
                remainingDistance: _remainingDistance,
                distanceTraveled: _distanceTraveled,
                totalTripDistance: _totalTripDistance,
                progressPercentage: _progressPercentage,
                remainingTime: _remainingTime,
                currentStreetName: _currentStreetName,
                destinationStreetName: _destinationStreetName,
                onMessageDriver: _messageDriver,
                isCreatingDriverChat: _isCreatingDriverChat,
              ),
            ),

          // No Active Trip Message
          if (tripState.currentTrip == null)
            Positioned(
              top: 50.h,
              left: 16.w,
              right: 16.w,
              child: _NoActiveTripCard(),
            ),

          // Current Location Button
          Positioned(
            bottom: 30.h,
            right: 16.w,
            child: Tooltip(
              message: 'Center map on your current location',
              child: _CurrentLocationButton(
                onPressed: _centerMapOnCurrentLocation,
              ),
            ),
          ),

          Positioned(
            bottom: 30.h,
            left: 16.w,
            child: Tooltip(
              message: _followVehicle
                  ? 'Disable auto-follow vehicle'
                  : 'Enable auto-follow vehicle',
              child: _FollowVehicleButton(
                isEnabled: _followVehicle,
                onPressed: () {
                  setState(() {
                    _followVehicle = !_followVehicle;
                  });
                },
              ),
            ),
          ),

          // Debug Distance Button (only show when trip is active)
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 90.h,
              right: 16.w,
              child: Tooltip(
                message: 'Debug distance tracking for current trip',
                child: _DebugDistanceButton(onPressed: _debugDistanceTracking),
              ),
            ),

          // Force Distance Update Button (only show when trip is active)
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 150.h,
              right: 16.w,
              child: Tooltip(
                message: 'Force update distance calculations',
                child: _ForceDistanceUpdateButton(
                  onPressed: _forceDistanceUpdate,
                ),
              ),
            ),

          // Check Conflicts Button
          Positioned(
            bottom: 210.h,
            right: 16.w,
            child: Tooltip(
              message: 'Check for location service conflicts',
              child: _CheckConflictsButton(onPressed: _checkLocationConflicts),
            ),
          ),

          // Force Accept Location Button
          Positioned(
            bottom: 270.h,
            right: 16.w,
            child: Tooltip(
              message: 'Force accept current location',
              child: _ForceAcceptLocationButton(
                onPressed: _forceAcceptLocation,
              ),
            ),
          ),

          // Force Restart Location Service Button
          Positioned(
            bottom: 330.h,
            right: 16.w,
            child: Tooltip(
              message: 'Restart location service',
              child: _ForceRestartLocationButton(
                onPressed: _forceRestartLocationService,
              ),
            ),
          ),

          // Refresh Button
          Positioned(
            bottom: 90.h,
            right: 16.w,
            child: Tooltip(
              message: 'Refresh map data and location',
              child: _RefreshButton(onPressed: _refreshMapData),
            ),
          ),

          // Test Green Marker Button
          Positioned(
            bottom: 150.h,
            right: 16.w,
            child: Tooltip(
              message: 'Add test green marker for debugging',
              child: _TestGreenMarkerButton(onPressed: _addTestGreenMarker),
            ),
          ),

          // Zoom to Trip Route Button
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 210.h,
              right: 16.w,
              child: Tooltip(
                message: 'Zoom to show trip route',
                child: _ZoomToStartButton(
                  onPressed: () => _zoomToTripRoute(tripState.currentTrip!),
                ),
              ),
            ),

          // Toggle Route Visibility Button
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 270.h,
              right: 16.w,
              child: Tooltip(
                message: 'Toggle route visibility on/off',
                child: _ToggleRouteButton(onPressed: _toggleRouteVisibility),
              ),
            ),

          // Location Guidance Banner
          if (_showLocationGuidance && _locationGuidance != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _LocationGuidanceBanner(
                message: _locationGuidance!,
                onDismiss: () {
                  setState(() {
                    _showLocationGuidance = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  void _addCurrentLocationMarker() async {
    if (_mapboxMap == null ||
        _currentLocation == null ||
        _pointAnnotationManager == null) {
      print('❌ Cannot add current location marker - missing dependencies');
      return;
    }

    try {
      print(
        '🔍 DEBUG: Adding current location marker at: ${_currentLocation!.coordinates.lat}, ${_currentLocation!.coordinates.lng}',
      );

      // Remove existing current location marker
      if (_currentLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_currentLocationAnnotation!);
      }

      // Create current location marker with dark green color
      final currentLocationMarker = PointAnnotationOptions(
        geometry: _currentLocation!,
        image: await _createMarkerImage(Colors.green.shade800, '📍'),
      );

      _currentLocationAnnotation = await _pointAnnotationManager!.create(
        currentLocationMarker,
      );
      print(
        '✅ Current location marker added to map at: ${_currentLocation!.coordinates.lat}, ${_currentLocation!.coordinates.lng}',
      );

      if (widget.pollActiveTrips) {
        final trip = _getCurrentMapTrip();
        if (trip != null) {
          await _drawParentToTripStartLine(trip);
        }
      }
    } catch (e) {
      print('❌ Error adding current location marker: $e');
    }
  }

  void _loadTripRoute() async {
    if (!mounted) return;

    print('🚀 DEBUG: _loadTripRoute() called');

    if (_mapboxMap == null ||
        _pointAnnotationManager == null ||
        _polylineAnnotationManager == null) {
      print('❌ Map or annotation managers not ready for trip route');
      print('❌ Map ready: ${_mapboxMap != null}');
      print('❌ Point manager ready: ${_pointAnnotationManager != null}');
      print('❌ Polyline manager ready: ${_polylineAnnotationManager != null}');
      return;
    }

    final currentTrip = _getCurrentMapTrip();
    final tripState = widget.pollActiveTrips
        ? _getDisplayTripState()
        : ref.read(tripProvider);

    print('🔍 DEBUG: Current trip: ${currentTrip?.tripId}');
    print('🔍 DEBUG: Current trip status: ${currentTrip?.status.name}');
    print('🔍 DEBUG: Current trip isActive: ${currentTrip?.isActive}');
    print(
      '🔍 DEBUG: Current trip start coords: ${currentTrip?.startLatitude}, ${currentTrip?.startLongitude}',
    );
    print(
      '🔍 DEBUG: Current trip end coords: ${currentTrip?.endLatitude}, ${currentTrip?.endLongitude}',
    );
    print('🔍 DEBUG: Total trips in state: ${tripState.trips.length}');
    print(
      '🔍 DEBUG: Active trips: ${tripState.trips.where((t) => t.isActive).length}',
    );

    if (currentTrip == null) {
      print('ℹ️ No active trip to display route for');
      return;
    }

    // The planned route + endpoint markers are static for a trip; once drawn
    // for the active trip, skip re-fetching/redrawing on every poll.
    if (_plannedRouteTripId == currentTrip.tripId && _routePolyline != null) {
      if (widget.pollActiveTrips) {
        await _refreshStudentPickupMarkers(currentTrip);
        await _drawParentToTripStartLine(
          currentTrip,
          routeStops: _cachedRouteStops,
        );
      }
      return;
    }

    try {
      // Remove existing trip markers
      if (_startLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_startLocationAnnotation!);
        _startLocationAnnotation = null;
      }
      if (_endLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_endLocationAnnotation!);
        _endLocationAnnotation = null;
      }

      // Add start location marker
      if (currentTrip.startLatitude != null &&
          currentTrip.startLongitude != null) {
        print('🟢 DEBUG: Creating GREEN start marker...');
        print(
          '🟢 DEBUG: Start location: ${_getLocationName(currentTrip.startLatitude, currentTrip.startLongitude, currentTrip.startLocation)}',
        );

        final startPoint = Point(
          coordinates: Position(
            currentTrip.startLongitude!,
            currentTrip.startLatitude!,
          ),
        );

        final startMarker = PointAnnotationOptions(
          geometry: startPoint,
          image: await _createMarkerImage(Colors.green, '🚀'),
        );

        _startLocationAnnotation = await _pointAnnotationManager!.create(
          startMarker,
        );
        print(
          '✅ GREEN Start location marker added: ${_getLocationName(currentTrip.startLatitude, currentTrip.startLongitude, currentTrip.startLocation)}',
        );

        // Auto-zoom to trip route only if current location is available
        // This ensures we show the relevant area (current location + trip points)
        if (_currentLocation != null) {
          _zoomToTripRoute(currentTrip);
        } else {
          // If no current location, just center on trip start
          _mapboxMap?.flyTo(
            CameraOptions(center: startPoint, zoom: 15.0),
            MapAnimationOptions(duration: 1200),
          );
        }
      } else {
        print('❌ DEBUG: Cannot create start marker - missing coordinates');
        print('❌ DEBUG: startLatitude: ${currentTrip.startLatitude}');
        print('❌ DEBUG: startLongitude: ${currentTrip.startLongitude}');
      }

      // Add end location marker
      if (currentTrip.endLatitude != null && currentTrip.endLongitude != null) {
        final endPoint = Point(
          coordinates: Position(
            currentTrip.endLongitude!,
            currentTrip.endLatitude!,
          ),
        );

        final endMarker = PointAnnotationOptions(
          geometry: endPoint,
          image: await _createMarkerImage(Colors.red, '🏁'),
        );

        _endLocationAnnotation = await _pointAnnotationManager!.create(
          endMarker,
        );
        print(
          '✅ End location marker added: ${_getLocationName(currentTrip.endLatitude, currentTrip.endLongitude, currentTrip.endLocation)}',
        );
      }

      // Resolve route stops from embedded data, route API, or trip details.
      final resolvedStops =
          await ParentTrackingService.resolveRouteStopCoordinates(
            parentTrip: widget.pollActiveTrips
                ? _getParentTrackingTrip()
                : null,
            mapTrip: currentTrip,
            hintRouteId: widget.pollActiveTrips
                ? _hintRouteIdFromStudents()
                : null,
          );
      print('🗺️ Resolved ${resolvedStops.length} route stop(s) for polyline');
      _cachedRouteStops = resolvedStops.isNotEmpty ? resolvedStops : null;
      final drewPlanned = await _drawPlannedRoute(
        currentTrip,
        embeddedStops: resolvedStops.length >= 2 ? resolvedStops : null,
      );
      if (drewPlanned) {
        _plannedRouteTripId = currentTrip.tripId;
        print('🗺️ DEBUG: Planned route drawn from route stops');
      } else {
        print(
          '🗺️ DEBUG: No route stops — drawing route from current location',
        );
        await _drawRouteFromCurrentLocation(currentTrip);
      }

      if (widget.pollActiveTrips) {
        await _refreshStudentPickupMarkers(currentTrip);
        await _drawParentToTripStartLine(
          currentTrip,
          routeStops: resolvedStops.length >= 1 ? resolvedStops : null,
        );
      }

      print(
        '✅ Trip route markers added to map for trip: ${currentTrip.tripId}',
      );
    } catch (e) {
      print('❌ Error adding trip route markers: $e');
    }
  }

  Future<void> _refreshStudentPickupMarkers(Trip trip) async {
    if (!widget.pollActiveTrips ||
        !mounted ||
        _pointAnnotationManager == null) {
      return;
    }

    await _clearStudentPickupMarkers();

    final routeId = trip.routeId ?? _hintRouteIdFromStudents();
    if (routeId == null || routeId <= 0) {
      print('ℹ️ No route id — skipping student pickup markers');
      return;
    }

    final students = ref.read(parentProvider).students;
    if (students.isEmpty) {
      print('ℹ️ No linked students — skipping pickup markers');
      return;
    }

    final routeStops = await RouteStopResolver.fetchRouteStopDetails(routeId);
    if (!mounted || routeStops.isEmpty) return;

    final pickupStops = routeStops.where(_isPickupStop).toList();
    if (pickupStops.isEmpty) return;

    final markersByStopId = <int, List<Student>>{};
    for (final student in students) {
      final stopId = student.pickupStop;
      if (stopId == null || stopId <= 0) continue;
      markersByStopId.putIfAbsent(stopId, () => []).add(student);
    }

    if (markersByStopId.isEmpty) {
      print('ℹ️ Linked students have no pickup_stop assigned');
      return;
    }

    try {
      for (final stop in pickupStops) {
        final stopId = (stop['id'] as num?)?.toInt();
        if (stopId == null) continue;

        final studentsAtStop = markersByStopId[stopId];
        if (studentsAtStop == null || studentsAtStop.isEmpty) continue;

        final coords = CoordinateUtils.fromStopJson(stop);
        if (coords == null) continue;

        final label = combinedStudentAbbreviations(
          studentsAtStop.map(studentAbbreviation),
        );

        final marker = PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(coords['longitude']!, coords['latitude']!),
          ),
          image: await _createAbbreviationMarkerImage(
            AppTheme.primaryColor,
            label,
          ),
        );

        final annotation = await _pointAnnotationManager!.create(marker);
        _studentPickupAnnotations.add(annotation);
      }

      print(
        '✅ Added ${_studentPickupAnnotations.length} student pickup marker(s)',
      );
    } catch (e) {
      print('❌ Error adding student pickup markers: $e');
    }
  }

  bool _isPickupStop(Map<String, dynamic> stop) {
    final type = (stop['stop_type'] ?? stop['type'] ?? '')
        .toString()
        .toLowerCase();
    return type == 'pickup' || type == 'both';
  }

  /// Road-following line from the parent's device location to the trip start.
  Future<void> _drawParentToTripStartLine(
    Trip trip, {
    List<Map<String, double>>? routeStops,
  }) async {
    if (!widget.pollActiveTrips || _parentToStartPolylineManager == null) {
      return;
    }

    var stops = routeStops ?? _cachedRouteStops;
    if (stops == null || stops.isEmpty) {
      stops = await ParentTrackingService.resolveRouteStopCoordinates(
        parentTrip: _getParentTrackingTrip(),
        mapTrip: trip,
        hintRouteId: _hintRouteIdFromStudents(),
      );
      if (!mounted) return;
      if (stops.isNotEmpty) {
        _cachedRouteStops = stops;
      }
    }

    double? parentLat = _currentLocation?.coordinates.lat.toDouble();
    double? parentLng = _currentLocation?.coordinates.lng.toDouble();
    if (parentLat == null || parentLng == null) {
      final position = await LocationServiceResolver.getCurrentPosition();
      if (position == null) {
        print('ℹ️ No parent location — skipping line to trip start');
        return;
      }
      parentLat = position.latitude;
      parentLng = position.longitude;
    }

    double? startLat = trip.startLatitude;
    double? startLng = trip.startLongitude;
    if ((startLat == null || startLng == null) && stops.isNotEmpty) {
      startLat = stops.first['latitude'];
      startLng = stops.first['longitude'];
    }
    if (startLat == null || startLng == null) {
      print('ℹ️ No trip start coordinates — skipping parent-to-start line');
      return;
    }

    // Avoid drawing a zero-length segment when parent is already at the start.
    final separation = _haversineMeters(
      parentLat,
      parentLng,
      startLat,
      startLng,
    );
    if (separation < 15) {
      await _clearParentToStartPolyline();
      return;
    }

    try {
      await _clearParentToStartPolyline();

      final routeInfo = await RoutingService.getRouteInfo(
        startLat: parentLat,
        startLng: parentLng,
        endLat: startLat,
        endLng: startLng,
      );

      final List<Position> positions;
      if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
        positions = routeInfo.coordinates
            .map((c) => Position(c['longitude']!, c['latitude']!))
            .toList();
      } else {
        positions = [
          Position(parentLng, parentLat),
          Position(startLng, startLat),
        ];
      }

      _parentToStartPolyline = await _parentToStartPolylineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: AppTheme.secondaryColor.value,
          lineWidth: 4.0,
          lineOpacity: 0.9,
        ),
      );
      print(
        '✅ Dashed parent-to-trip-start line drawn '
        '(${positions.length} points, ${separation.round()}m apart)',
      );
    } catch (e) {
      print('❌ Error drawing parent-to-trip-start line: $e');
    }
  }

  Future<void> _clearParentToStartPolyline() async {
    if (_parentToStartPolylineManager == null ||
        _parentToStartPolyline == null) {
      return;
    }
    try {
      await _parentToStartPolylineManager!.delete(_parentToStartPolyline!);
      _parentToStartPolyline = null;
    } catch (_) {
      _parentToStartPolyline = null;
    }
  }

  Future<void> _clearStudentPickupMarkers() async {
    if (_pointAnnotationManager == null || _studentPickupAnnotations.isEmpty) {
      return;
    }

    for (final annotation in _studentPickupAnnotations) {
      try {
        await _pointAnnotationManager!.delete(annotation);
      } catch (_) {
        // Marker may already be gone after map style reloads.
      }
    }
    _studentPickupAnnotations.clear();
  }

  /// Draws the trip's planned route as a road-following line through its route
  /// stops. Returns true when a route line was drawn.
  Future<bool> _drawPlannedRoute(
    Trip trip, {
    List<Map<String, double>>? embeddedStops,
  }) async {
    if (_polylineAnnotationManager == null) return false;

    List<Map<String, double>> stops;
    if (embeddedStops != null && embeddedStops.length >= 2) {
      stops = embeddedStops;
    } else {
      final routeId = trip.routeId;
      if (routeId == null) return false;
      stops = await ParentTrackingService.getRouteStopCoordinates(routeId);
    }
    if (!mounted) return false;
    if (stops.length < 2) return false;

    List<Position> positions = stops
        .map((s) => Position(s['longitude']!, s['latitude']!))
        .toList();

    // Snap the stop path to roads so the line follows streets (both parent and
    // driver maps). The straight stop-to-stop path above remains the fallback
    // when Mapbox Directions is unavailable.
    final routeInfo = await RoutingService.getRouteThroughWaypoints(stops);
    if (!mounted) return false;
    if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
      positions = routeInfo.coordinates
          .map((c) => Position(c['longitude']!, c['latitude']!))
          .toList();
      setState(() {
        _totalTripDistance = routeInfo.distance;
        _remainingDistance = routeInfo.distance;
        _remainingTime = Duration(seconds: routeInfo.duration.round());
      });
    }

    try {
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }
      _routePolyline = await _polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: AppTheme.routeGreen.value,
          lineWidth: 6.0,
          lineOpacity: 1.0,
        ),
      );
      print('✅ Planned route polyline drawn with ${positions.length} points');
    } catch (e) {
      print('❌ Failed to draw planned route polyline: $e');
      return false;
    }

    await _ensureRouteEndpointMarkers(stops);
    await _fitCameraToRoutePositions(positions);
    return true;
  }

  Future<void> _fitCameraToRoutePositions(List<Position> positions) async {
    if (_mapboxMap == null || positions.isEmpty) return;

    double minLat = positions.first.lat.toDouble();
    double maxLat = minLat;
    double minLng = positions.first.lng.toDouble();
    double maxLng = minLng;

    for (final point in positions) {
      final lat = point.lat.toDouble();
      final lng = point.lng.toDouble();
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final maxDiff = math.max(maxLat - minLat, maxLng - minLng);

    double zoom;
    if (maxDiff > 0.15) {
      zoom = 10.0;
    } else if (maxDiff > 0.08) {
      zoom = 11.0;
    } else if (maxDiff > 0.03) {
      zoom = 12.5;
    } else if (maxDiff > 0.01) {
      zoom = 14.0;
    } else {
      zoom = 15.5;
    }

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  /// Ensures green (start) and red (end) markers exist using the first/last
  /// route stop when the trip has no explicit start/end coordinates.
  Future<void> _ensureRouteEndpointMarkers(
    List<Map<String, double>> stops,
  ) async {
    if (_pointAnnotationManager == null || stops.length < 2) return;
    try {
      if (_startLocationAnnotation == null) {
        final first = stops.first;
        _startLocationAnnotation = await _pointAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(first['longitude']!, first['latitude']!),
            ),
            image: await _createMarkerImage(Colors.green, '🚀'),
          ),
        );
      }
      if (_endLocationAnnotation == null) {
        final last = stops.last;
        _endLocationAnnotation = await _pointAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(last['longitude']!, last['latitude']!),
            ),
            image: await _createMarkerImage(Colors.red, '🏁'),
          ),
        );
      }
    } catch (e) {
      print('⚠️ Failed to add route endpoint markers: $e');
    }
  }

  /// Draw route from current location to destination
  Future<void> _drawRouteFromCurrentLocation(Trip trip) async {
    if (_polylineAnnotationManager == null) {
      print('❌ Polyline annotation manager not ready');
      return;
    }

    if (trip.endLatitude == null || trip.endLongitude == null) {
      print('❌ Cannot draw route - missing destination coordinates');
      return;
    }

    try {
      // Parent live-tracking should use bus location first.
      double? startLat = trip.currentLatitude;
      double? startLng = trip.currentLongitude;

      // Fallback to device GPS when bus coordinates are unavailable.
      if (startLat == null || startLng == null) {
        final currentLocation =
            await LocationServiceResolver.getCurrentPosition();
        if (currentLocation != null) {
          startLat = currentLocation.latitude;
          startLng = currentLocation.longitude;
        }
      }

      if (startLat == null || startLng == null) {
        print('❌ Cannot draw route - no valid origin location available');
        // Fall back to full route if no valid origin location
        await _drawRoutePolyline(trip);
        return;
      }

      print('🗺️ Getting route from current location to destination...');
      print('📍 Route origin: $startLat, $startLng');
      print('🏁 Destination: ${trip.endLatitude}, ${trip.endLongitude}');

      // Reverse geocode street names (non-blocking UI updates)
      // Current street
      _reverseGeocode(startLat, startLng).then((name) {
        if (!mounted) return;
        if (name != null && name != _currentStreetName) {
          setState(() => _currentStreetName = name);
        }
      });
      // Destination street
      if (trip.endLatitude != null && trip.endLongitude != null) {
        _reverseGeocode(trip.endLatitude!, trip.endLongitude!).then((name) {
          if (!mounted) return;
          if (name != null && name != _destinationStreetName) {
            setState(() => _destinationStreetName = name);
          }
        });
      }

      // Remove existing route polyline
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }

      // Get route coordinates from current location to destination
      final routeInfo = await RoutingService.getRouteInfo(
        startLat: startLat,
        startLng: startLng,
        endLat: trip.endLatitude!,
        endLng: trip.endLongitude!,
      );

      List<Position> routeCoordinates;

      if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
        // Use road-based route coordinates
        routeCoordinates = routeInfo.coordinates
            .map((coord) => Position(coord['longitude']!, coord['latitude']!))
            .toList();
        print(
          '✅ Using road-based route from current location with ${routeCoordinates.length} points',
        );
        print(
          '📏 Route distance: ${(routeInfo.distance / 1000).toStringAsFixed(2)} km',
        );
        print(
          '⏱️ Route duration: ${(routeInfo.duration / 60).toStringAsFixed(1)} min',
        );

        // Store route information for UI display
        if (mounted) {
          setState(() {
            _remainingDistance = routeInfo.distance; // in meters
            _totalTripDistance = routeInfo.distance; // in meters
            _remainingTime = Duration(seconds: routeInfo.duration.round());
            _distanceTraveled = 0.0; // Reset traveled distance
            _progressPercentage = 0.0; // Reset progress
          });
        }
      } else {
        // Fallback to straight line if routing fails
        print('⚠️ Routing service failed, using straight line as fallback');
        routeCoordinates = [
          Position(startLng, startLat), // Current origin (bus/device)
          Position(trip.endLongitude!, trip.endLatitude!), // Destination
        ];
      }

      // Create route line coordinates
      final routeLine = LineString(coordinates: routeCoordinates);

      // Use green color for better identification of current location to destination
      Color routeColor = Colors.green;

      // Create polyline annotation
      final polylineOptions = PolylineAnnotationOptions(
        geometry: routeLine,
        lineColor: routeColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      _routePolyline = await _polylineAnnotationManager!.create(
        polylineOptions,
      );

      print(
        '✅ Route polyline drawn from current location to ${trip.endLatitude}, ${trip.endLongitude}',
      );
      print('✅ Route color: ${routeColor.toString()}');
      print(
        '✅ Route polyline created with ${routeCoordinates.length} coordinates',
      );
    } catch (e) {
      print('❌ Error drawing route from current location: $e');
      // Fall back to full route if current location route fails
      await _drawRoutePolyline(trip);
    }
  }

  Future<void> _drawRoutePolyline(Trip trip) async {
    if (_polylineAnnotationManager == null) {
      print('❌ Polyline annotation manager not ready');
      return;
    }

    if (trip.startLatitude == null ||
        trip.startLongitude == null ||
        trip.endLatitude == null ||
        trip.endLongitude == null) {
      print('❌ Cannot draw route polyline - missing coordinates');
      return;
    }

    try {
      // Remove existing route polyline
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }

      print('🗺️ Getting road-based route from routing service...');

      // Get route coordinates from routing service (road-based)
      final routeInfo = await RoutingService.getRouteInfo(
        startLat: trip.startLatitude!,
        startLng: trip.startLongitude!,
        endLat: trip.endLatitude!,
        endLng: trip.endLongitude!,
      );

      List<Position> routeCoordinates;

      if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
        // Use road-based route coordinates
        routeCoordinates = routeInfo.coordinates
            .map((coord) => Position(coord['longitude']!, coord['latitude']!))
            .toList();
        print(
          '✅ Using road-based route with ${routeCoordinates.length} points',
        );
        print(
          '📏 Route distance: ${(routeInfo.distance / 1000).toStringAsFixed(2)} km',
        );
        print(
          '⏱️ Route duration: ${(routeInfo.duration / 60).toStringAsFixed(1)} min',
        );

        // Store route information for UI display
        if (mounted) {
          setState(() {
            _remainingDistance = routeInfo.distance; // in meters
            _totalTripDistance = routeInfo.distance; // in meters
            _remainingTime = Duration(seconds: routeInfo.duration.round());
            _distanceTraveled = 0.0; // Reset traveled distance
            _progressPercentage = 0.0; // Reset progress
          });
        }
      } else {
        // Fallback to straight line if routing fails
        print('⚠️ Routing service failed, using straight line as fallback');
        routeCoordinates = [
          Position(trip.startLongitude!, trip.startLatitude!), // Start point
          Position(trip.endLongitude!, trip.endLatitude!), // End point
        ];
      }

      // Create route line coordinates
      final routeLine = LineString(coordinates: routeCoordinates);

      // Use green color for better identification of current location to destination
      Color routeColor = Colors.green;

      // Create polyline annotation
      final polylineOptions = PolylineAnnotationOptions(
        geometry: routeLine,
        lineColor: routeColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      _routePolyline = await _polylineAnnotationManager!.create(
        polylineOptions,
      );

      print(
        '✅ Route polyline drawn from ${trip.startLatitude}, ${trip.startLongitude} to ${trip.endLatitude}, ${trip.endLongitude}',
      );
      print('✅ Route color: ${routeColor.toString()} (${trip.status.name})');
      print(
        '✅ Route polyline created with ${routeCoordinates.length} coordinates',
      );
    } catch (e) {
      print('❌ Error drawing route polyline: $e');
    }
  }

  void _addTripMarkers() async {
    if (!mounted) return;

    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Map or annotation manager not ready');
      return;
    }

    final tripState = _getDisplayTripState();
    print('🔍 DEBUG: Total trips loaded: ${tripState.trips.length}');
    print(
      '🔍 DEBUG: Trip states: ${tripState.trips.map((t) => '${t.tripId}: ${t.status.name}').join(', ')}',
    );

    final activeTrips = tripState.trips.where((trip) => trip.isActive).toList();
    print('🔍 DEBUG: Active trips found: ${activeTrips.length}');

    if (activeTrips.isEmpty) {
      print('ℹ️ No active trips to display markers for');
      return;
    }

    try {
      print('🚌 Adding markers for ${activeTrips.length} active trips:');
      for (final trip in activeTrips) {
        // Parent live tracking renders a single animated vehicle marker instead.
        if (widget.pollActiveTrips) continue;

        print(
          '🔍 DEBUG: Trip ${trip.tripId} - Start: ${_getLocationName(trip.startLatitude, trip.startLongitude, trip.startLocation)}',
        );
        print(
          '🔍 DEBUG: Trip ${trip.tripId} - End: ${_getLocationName(trip.endLatitude, trip.endLongitude, trip.endLocation)}',
        );
        print('🔍 DEBUG: Trip ${trip.tripId} - Status: ${trip.status.name}');

        if (trip.startLatitude != null && trip.startLongitude != null) {
          final tripPoint = Point(
            coordinates: Position(trip.startLongitude!, trip.startLatitude!),
          );

          final tripMarker = PointAnnotationOptions(
            geometry: tripPoint,
            image: await _createMarkerImage(Colors.orange, '🚌'),
          );

          await _pointAnnotationManager!.create(tripMarker);
          print(
            '  ✅ Trip ${trip.tripId} marker added at: ${_getLocationName(trip.startLatitude, trip.startLongitude, trip.startLocation)}',
          );
        } else {
          print('  ❌ Trip ${trip.tripId} has no valid coordinates');
        }
      }
      // In parent live tracking the marker is driven by the real-time feed.
      if (!widget.pollActiveTrips) {
        _handleTripVehicleUpdate(activeTrips.first);
      }
      print('✅ All trip markers added to map');
    } catch (e) {
      print('❌ Error adding trip markers: $e');
    }
  }

  String? _parentTripKey(ParentState state) {
    final live = state.activeTrips.where((t) => t.isActive).toList();
    if (live.isEmpty) return null;
    final trip = live.first;
    return trip.backendTripId.isNotEmpty
        ? trip.backendTripId
        : trip.id.toString();
  }

  void _onParentStateChanged(ParentState? previous, ParentState next) {
    if (!mounted || !widget.pollActiveTrips) return;

    final prevTripKey = previous != null ? _parentTripKey(previous) : null;
    final nextTripKey = _parentTripKey(next);

    if (_mapboxMap != null && nextTripKey != null) {
      if (prevTripKey != nextTripKey) {
        _plannedRouteTripId = null;
        _cachedRouteStops = null;
      }
      _loadTripRoute();
      _addTripMarkers();
    } else if (_mapboxMap != null && nextTripKey == null) {
      _clearRoutePolyline();
      _clearVehicleMarker();
      _clearStudentPickupMarkers();
      _clearParentToStartPolyline();
    }
  }

  void _onTripStateChanged(TripState? previous, TripState next) {
    if (!mounted) return;

    // Parent mode: tripProvider is a fallback data source for route geometry.
    if (widget.pollActiveTrips) {
      if (_mapboxMap != null && next.currentTrip != null) {
        _loadTripRoute();
      }
      return;
    }

    print('🔄 DEBUG: Trip provider state changed');
    print('🔄 DEBUG: Previous currentTrip: ${previous?.currentTrip?.tripId}');
    print('🔄 DEBUG: Next currentTrip: ${next.currentTrip?.tripId}');
    print('🔄 DEBUG: Map ready: ${_mapboxMap != null}');

    if (_mapboxMap != null && next.currentTrip != null) {
      print('🔄 DEBUG: Triggering marker updates...');
      _loadTripRoute();
      _addTripMarkers();
      if (!widget.pollActiveTrips) {
        _startDistanceTracking(next.currentTrip!);
        // In parent mode the marker is driven by the real-time status feed.
        _handleTripVehicleUpdate(next.currentTrip!);
      }
    } else if (_mapboxMap != null && next.currentTrip == null) {
      print('🔄 DEBUG: No active trip - clearing route polyline...');
      _clearRoutePolyline();
      if (!widget.pollActiveTrips) {
        _stopDistanceTracking();
      }
      _clearVehicleMarker();
    } else {
      print(
        '🔄 DEBUG: Skipping marker updates - map: ${_mapboxMap != null}, trip: ${next.currentTrip != null}',
      );
    }
  }

  Future<void> _clearVehicleMarker() async {
    _vehicleAnimationTimer?.cancel();
    _vehicleAnimationTimer = null;
    _lastVehiclePoint = null;
    _lastAcceptedVehicleLat = null;
    _lastAcceptedVehicleLng = null;
    _lastRenderedVehicleLat = null;
    _lastRenderedVehicleLng = null;
    _vehicleAnimationInProgress = false;
    _isCreatingVehicleMarker = false;
    _isVehicleMarkerReady = false;
    _lastVehicleHeading = null;
    _lastVehicleSpeed = null;
    _lastVehicleUpdateAt = null;
    _isVehiclePositionStale = false;
    _rawVehicleTrack.clear();
    _vehicleTrailPoints.clear();
    if (_pointAnnotationManager != null && _vehicleLocationAnnotation != null) {
      await _pointAnnotationManager!.delete(_vehicleLocationAnnotation!);
      _vehicleLocationAnnotation = null;
    }
    if (_polylineAnnotationManager != null && _vehicleTrailPolyline != null) {
      await _polylineAnnotationManager!.delete(_vehicleTrailPolyline!);
      _vehicleTrailPolyline = null;
    }
  }

  // ── Real-time vehicle status feed ─────────────────────────────────────────

  /// Polls the lightweight `/trips/{id}/status/` endpoint for the freshest GPS
  /// fix (with device heading/speed), filters GPS noise, snaps the segment to
  /// the road network, animates the marker, and extends the breadcrumb trail.
  Future<void> _pollVehicleRealtimeStatus() async {
    if (!widget.pollActiveTrips) return;
    if (_isFetchingVehicleStatus) return;
    if (_pointAnnotationManager == null) return;

    final trip = _getCurrentMapTrip();
    final tripId = trip?.tripId;
    if (tripId == null || tripId.isEmpty) return;

    _isFetchingVehicleStatus = true;
    try {
      final response = await ParentTrackingService.getTripRealtimeStatus(
        tripId,
      );
      if (!mounted) return;
      if (!response.success || response.data == null) {
        _recomputeVehicleStaleness();
        return;
      }

      final data = response.data!;
      final coords =
          CoordinateUtils.fromLatLngFields(
            data['latitude'] ?? data['current_latitude'],
            data['longitude'] ?? data['current_longitude'],
          ) ??
          CoordinateUtils.fromLocationValue(data['current_location']);
      final lat = coords?['latitude'];
      final lng = coords?['longitude'];
      final heading = _toNullableDouble(data['heading']);
      final speed = _toNullableDouble(data['speed']);
      final lastUpdateRaw = data['last_update']?.toString();

      if (lastUpdateRaw != null) {
        _lastVehicleUpdateAt = DateTime.tryParse(lastUpdateRaw)?.toLocal();
      }
      _lastVehicleHeading = heading;
      _lastVehicleSpeed = speed;
      _recomputeVehicleStaleness();

      if (lat == null || lng == null) return;

      // Duplicate fix (same position re-served) → nothing to animate.
      if (_isDuplicateVehicleCoordinate(lat, lng)) return;

      // GPS noise filter: ignore tiny jitter so the marker doesn't shiver.
      if (_lastAcceptedVehicleLat != null && _lastAcceptedVehicleLng != null) {
        final moved = _haversineMeters(
          _lastAcceptedVehicleLat!,
          _lastAcceptedVehicleLng!,
          lat,
          lng,
        );
        if (moved < _minVehicleMoveMeters) return;
      }

      _rememberAcceptedVehicleCoordinate(lat, lng);
      _rawVehicleTrack.add({'latitude': lat, 'longitude': lng});
      if (_rawVehicleTrack.length > 100) {
        _rawVehicleTrack.removeAt(0);
      }

      await _moveVehicleWithSnapping(lat, lng, heading);
    } catch (e) {
      print('⚠️ Vehicle status poll failed: $e');
    } finally {
      _isFetchingVehicleStatus = false;
    }
  }

  double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Snaps the segment from the previous position to the new fix onto roads
  /// (Uber-style) and animates the marker along it; falls back to a straight
  /// interpolation when matching is unavailable.
  Future<void> _moveVehicleWithSnapping(
    double lat,
    double lng,
    double? heading,
  ) async {
    final target = Point(coordinates: Position(lng, lat));

    // No prior position yet → just place the marker.
    if (!_isVehicleMarkerReady || _vehicleLocationAnnotation == null) {
      await _animateVehicleMarkerTo(target, headingOverride: heading);
      _appendTrailPoint(lat, lng);
      return;
    }

    final from = _lastVehiclePoint;
    List<Point>? snapped;
    if (from != null) {
      final segment = await RoutingService.getSnappedPath([
        {
          'latitude': from.coordinates.lat.toDouble(),
          'longitude': from.coordinates.lng.toDouble(),
        },
        {'latitude': lat, 'longitude': lng},
      ]);
      if (segment != null && segment.length >= 2) {
        snapped = segment
            .map(
              (c) =>
                  Point(coordinates: Position(c['longitude']!, c['latitude']!)),
            )
            .toList();
      }
    }

    if (!mounted) return;

    if (snapped != null) {
      await _animateVehicleAlongPath(snapped, headingOverride: heading);
    } else {
      await _animateVehicleMarkerTo(target, headingOverride: heading);
      _appendTrailPoint(lat, lng);
    }
  }

  void _recomputeVehicleStaleness() {
    final last = _lastVehicleUpdateAt;
    final stale =
        last == null ||
        DateTime.now().difference(last) > _vehicleStaleThreshold;
    if (stale != _isVehiclePositionStale && mounted) {
      setState(() => _isVehiclePositionStale = stale);
    }
  }

  void _appendTrailPoint(double lat, double lng) {
    _vehicleTrailPoints.add(Point(coordinates: Position(lng, lat)));
    if (_vehicleTrailPoints.length > 300) {
      _vehicleTrailPoints.removeAt(0);
    }
    _redrawVehicleTrail();
  }

  Future<void> _redrawVehicleTrail() async {
    if (_polylineAnnotationManager == null) return;
    if (_vehicleTrailPoints.length < 2) return;
    try {
      if (_vehicleTrailPolyline != null) {
        await _polylineAnnotationManager!.delete(_vehicleTrailPolyline!);
        _vehicleTrailPolyline = null;
      }
      _vehicleTrailPolyline = await _polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: _vehicleTrailPoints.map((p) => p.coordinates).toList(),
          ),
          lineColor: Colors.teal.toARGB32(),
          lineWidth: 4.0,
          lineOpacity: 0.7,
        ),
      );
    } catch (e) {
      print('⚠️ Failed to draw vehicle trail: $e');
    }
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Widget _buildParentMapLegend() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      constraints: BoxConstraints(maxWidth: 210.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Map key',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          _parentMapLegendRow(
            color: AppTheme.routeGreen,
            label: 'Bus route',
            isDashed: false,
          ),
          SizedBox(height: 6.h),
          _parentMapLegendRow(
            color: AppTheme.secondaryColor,
            label: 'Your route to pickup',
            isDashed: true,
          ),
          SizedBox(height: 6.h),
          _parentMapLegendRow(
            color: AppTheme.primaryColor,
            label: 'Child pickup stop',
            isDashed: false,
            isDot: true,
          ),
          SizedBox(height: 6.h),
          _parentMapLegendRow(
            color: const Color(0xFF4285F4),
            label: 'Live bus',
            isDashed: false,
            isBus: true,
          ),
        ],
      ),
    );
  }

  Widget _parentMapLegendRow({
    required Color color,
    required String label,
    required bool isDashed,
    bool isDot = false,
    bool isBus = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 28.w,
          child: isBus
              ? Icon(
                  Icons.directions_bus_filled_rounded,
                  size: 16.w,
                  color: color,
                )
              : isDot
              ? Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : _parentMapLegendLine(color: color, isDashed: isDashed),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _parentMapLegendLine({required Color color, required bool isDashed}) {
    if (!isDashed) {
      return Container(
        height: 3.h,
        width: 24.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return Row(
      children: List.generate(
        4,
        (index) => Container(
          width: 4.w,
          height: 3.h,
          margin: EdgeInsets.only(right: index < 3 ? 2.w : 0),
          color: color,
        ),
      ),
    );
  }

  Widget _buildVehicleFreshnessChip() {
    final last = _lastVehicleUpdateAt;
    final bool live = !_isVehiclePositionStale && last != null;

    String label;
    if (last == null) {
      label = 'Waiting for GPS…';
    } else {
      final secs = DateTime.now().difference(last).inSeconds;
      if (secs <= 2) {
        label = 'Live';
      } else if (secs < 60) {
        label = 'Updated ${secs}s ago';
      } else {
        final mins = secs ~/ 60;
        label = 'Updated ${mins}m ago';
      }
    }

    // Append current speed (km/h) when live and moving.
    if (live && _lastVehicleSpeed != null && _lastVehicleSpeed! > 0.5) {
      label = '$label · ${_lastVehicleSpeed!.round()} km/h';
    }

    final Color color = live ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isDuplicateVehicleCoordinate(double lat, double lng) {
    bool matches(double? storedLat, double? storedLng) {
      if (storedLat == null || storedLng == null) return false;
      return (storedLat - lat).abs() < _vehicleCoordinateEpsilon &&
          (storedLng - lng).abs() < _vehicleCoordinateEpsilon;
    }

    return matches(_lastAcceptedVehicleLat, _lastAcceptedVehicleLng) ||
        matches(_lastRenderedVehicleLat, _lastRenderedVehicleLng);
  }

  void _rememberAcceptedVehicleCoordinate(double lat, double lng) {
    _lastAcceptedVehicleLat = lat;
    _lastAcceptedVehicleLng = lng;
  }

  void _rememberRenderedVehicleCoordinate(double lat, double lng) {
    _lastRenderedVehicleLat = lat;
    _lastRenderedVehicleLng = lng;
    _lastVehiclePoint = Point(coordinates: Position(lng, lat));
  }

  void _handleTripVehicleUpdate(Trip trip) {
    if (_pointAnnotationManager == null) return;
    if (trip.currentLatitude == null || trip.currentLongitude == null) return;

    final lat = trip.currentLatitude!;
    final lng = trip.currentLongitude!;
    if (_isDuplicateVehicleCoordinate(lat, lng)) return;

    _rememberAcceptedVehicleCoordinate(lat, lng);
    _animateVehicleMarkerTo(Point(coordinates: Position(lng, lat)));
  }

  /// Optional integration point for Firebase/WebSocket coordinate streams.
  /// Each event should contain `latitude` and `longitude` as num.
  void bindVehicleCoordinateStream(Stream<Map<String, dynamic>> stream) {
    _vehicleCoordinateSubscription?.cancel();
    _vehicleCoordinateSubscription = stream.listen((event) {
      final lat = (event['latitude'] as num?)?.toDouble();
      final lng = (event['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      if (_isDuplicateVehicleCoordinate(lat, lng)) return;

      _rememberAcceptedVehicleCoordinate(lat, lng);
      _animateVehicleMarkerTo(Point(coordinates: Position(lng, lat)));
    });
  }

  Future<void> _animateVehicleMarkerTo(
    Point targetPoint, {
    double? headingOverride,
  }) async {
    if (_pointAnnotationManager == null || !mounted) return;

    final targetLat = targetPoint.coordinates.lat.toDouble();
    final targetLng = targetPoint.coordinates.lng.toDouble();

    Point startPoint;
    if (_vehicleAnimationInProgress &&
        _vehicleLocationAnnotation?.geometry != null) {
      startPoint = _vehicleLocationAnnotation!.geometry;
    } else {
      startPoint = _lastVehiclePoint ?? targetPoint;
    }

    // Prefer the device-reported heading; otherwise derive it from movement.
    // Keep the previous heading when essentially stationary to avoid spinning.
    final double bearing =
        headingOverride ??
        (_haversineMeters(
                  startPoint.coordinates.lat.toDouble(),
                  startPoint.coordinates.lng.toDouble(),
                  targetLat,
                  targetLng,
                ) <
                1.0
            ? (_lastVehicleHeading ?? 0.0)
            : _calculateBearing(
                startPoint.coordinates.lat.toDouble(),
                startPoint.coordinates.lng.toDouble(),
                targetLat,
                targetLng,
              ));

    if (!_isVehicleMarkerReady || _vehicleLocationAnnotation == null) {
      if (_isCreatingVehicleMarker) return;
      _isCreatingVehicleMarker = true;
      try {
        final vehicleMarker = PointAnnotationOptions(
          geometry: targetPoint,
          image: await _createMarkerImage(Colors.blue, '🚌'),
          iconRotate: bearing,
        );
        _vehicleLocationAnnotation = await _pointAnnotationManager!.create(
          vehicleMarker,
        );
        _rememberRenderedVehicleCoordinate(targetLat, targetLng);
        _isVehicleMarkerReady = true;
        if (_followVehicle) {
          _animateCameraToVehicle(targetPoint, bearing);
        }
      } finally {
        _isCreatingVehicleMarker = false;
      }
      return;
    }

    if ((startPoint.coordinates.lat.toDouble() - targetLat).abs() <
            _vehicleCoordinateEpsilon &&
        (startPoint.coordinates.lng.toDouble() - targetLng).abs() <
            _vehicleCoordinateEpsilon) {
      _rememberRenderedVehicleCoordinate(targetLat, targetLng);
      return;
    }

    _vehicleAnimationTimer?.cancel();
    _vehicleAnimationInProgress = true;

    const totalFrames = 60;
    final totalDurationMs = widget.pollActiveTrips
        ? AppConfig.parentLiveTrackingPollSeconds * 1000
        : 2000;
    final frameDurationMs = totalDurationMs ~/ totalFrames;
    int frame = 0;

    _vehicleAnimationTimer = Timer.periodic(
      Duration(milliseconds: frameDurationMs),
      (timer) async {
        if (!mounted || _vehicleLocationAnnotation == null) {
          timer.cancel();
          _vehicleAnimationInProgress = false;
          return;
        }
        frame++;
        final t = frame / totalFrames;
        final easedT = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
        final interpolatedLat =
            startPoint.coordinates.lat.toDouble() +
            (targetLat - startPoint.coordinates.lat.toDouble()) * easedT;
        final interpolatedLng =
            startPoint.coordinates.lng.toDouble() +
            (targetLng - startPoint.coordinates.lng.toDouble()) * easedT;
        final interpolatedPoint = Point(
          coordinates: Position(interpolatedLng, interpolatedLat),
        );

        _vehicleLocationAnnotation!
          ..geometry = interpolatedPoint
          ..iconRotate = bearing;
        await _pointAnnotationManager!.update(_vehicleLocationAnnotation!);

        if (_followVehicle && frame % 3 == 0) {
          _animateCameraToVehicle(interpolatedPoint, bearing);
        }

        if (frame >= totalFrames) {
          timer.cancel();
          _vehicleAnimationInProgress = false;
          _rememberRenderedVehicleCoordinate(targetLat, targetLng);
        }
      },
    );
  }

  /// Animates the vehicle marker through a multi-point (road-snapped) path over
  /// the poll window, computing per-segment bearings so the icon turns with the
  /// road. Each traversed vertex is appended to the breadcrumb trail.
  Future<void> _animateVehicleAlongPath(
    List<Point> path, {
    double? headingOverride,
  }) async {
    if (_pointAnnotationManager == null || !mounted) return;
    if (path.length < 2) {
      if (path.isNotEmpty) {
        await _animateVehicleMarkerTo(
          path.first,
          headingOverride: headingOverride,
        );
      }
      return;
    }

    // Ensure the marker exists before animating along the path.
    if (!_isVehicleMarkerReady || _vehicleLocationAnnotation == null) {
      await _animateVehicleMarkerTo(
        path.first,
        headingOverride: headingOverride,
      );
    }

    _vehicleAnimationTimer?.cancel();
    _vehicleAnimationInProgress = true;

    // Cumulative segment lengths to distribute motion at constant speed.
    final segmentLengths = <double>[];
    double totalLength = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final d = _haversineMeters(
        path[i].coordinates.lat.toDouble(),
        path[i].coordinates.lng.toDouble(),
        path[i + 1].coordinates.lat.toDouble(),
        path[i + 1].coordinates.lng.toDouble(),
      );
      segmentLengths.add(d);
      totalLength += d;
    }
    if (totalLength <= 0) {
      _vehicleAnimationInProgress = false;
      final last = path.last;
      await _animateVehicleMarkerTo(last, headingOverride: headingOverride);
      return;
    }

    const totalFrames = 60;
    final totalDurationMs = widget.pollActiveTrips
        ? AppConfig.parentLiveTrackingPollSeconds * 1000
        : 2000;
    final frameDurationMs = totalDurationMs ~/ totalFrames;
    int frame = 0;

    _vehicleAnimationTimer = Timer.periodic(
      Duration(milliseconds: frameDurationMs),
      (timer) async {
        if (!mounted || _vehicleLocationAnnotation == null) {
          timer.cancel();
          _vehicleAnimationInProgress = false;
          return;
        }
        frame++;
        final t = (frame / totalFrames).clamp(0.0, 1.0);
        final eased = Curves.easeInOut.transform(t);
        final distanceAlong = eased * totalLength;

        // Locate the active segment for this distance.
        double acc = 0;
        int seg = 0;
        while (seg < segmentLengths.length &&
            acc + segmentLengths[seg] < distanceAlong) {
          acc += segmentLengths[seg];
          seg++;
        }
        if (seg >= segmentLengths.length) seg = segmentLengths.length - 1;

        final segStart = path[seg];
        final segEnd = path[seg + 1];
        final segLen = segmentLengths[seg];
        final localT = segLen > 0 ? (distanceAlong - acc) / segLen : 0.0;

        final lat =
            segStart.coordinates.lat.toDouble() +
            (segEnd.coordinates.lat.toDouble() -
                    segStart.coordinates.lat.toDouble()) *
                localT;
        final lng =
            segStart.coordinates.lng.toDouble() +
            (segEnd.coordinates.lng.toDouble() -
                    segStart.coordinates.lng.toDouble()) *
                localT;
        final point = Point(coordinates: Position(lng, lat));

        final bearing =
            headingOverride ??
            _calculateBearing(
              segStart.coordinates.lat.toDouble(),
              segStart.coordinates.lng.toDouble(),
              segEnd.coordinates.lat.toDouble(),
              segEnd.coordinates.lng.toDouble(),
            );

        _vehicleLocationAnnotation!
          ..geometry = point
          ..iconRotate = bearing;
        await _pointAnnotationManager!.update(_vehicleLocationAnnotation!);

        if (_followVehicle && frame % 3 == 0) {
          _animateCameraToVehicle(point, bearing);
        }

        if (frame >= totalFrames) {
          timer.cancel();
          _vehicleAnimationInProgress = false;
          final end = path.last;
          _rememberRenderedVehicleCoordinate(
            end.coordinates.lat.toDouble(),
            end.coordinates.lng.toDouble(),
          );
          // Add the full snapped segment to the breadcrumb trail.
          for (final p in path) {
            _vehicleTrailPoints.add(p);
          }
          if (_vehicleTrailPoints.length > 300) {
            _vehicleTrailPoints.removeRange(
              0,
              _vehicleTrailPoints.length - 300,
            );
          }
          _redrawVehicleTrail();
        }
      },
    );
  }

  Future<void> _animateCameraToVehicle(Point point, double bearing) async {
    if (_mapboxMap == null) return;
    _mapboxMap!.easeTo(
      CameraOptions(center: point, zoom: 16.0, bearing: bearing),
      MapAnimationOptions(duration: 600),
    );
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = _degreesToRadians(lat1);
    final phi2 = _degreesToRadians(lat2);
    final deltaLambda = _degreesToRadians(lon2 - lon1);
    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final theta = math.atan2(y, x);
    return (theta * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Start real-time distance tracking for a trip
  void _startDistanceTracking(Trip trip) async {
    try {
      print('📏 Starting distance tracking for trip ${trip.tripId}');

      // Check if location service is already running
      if (!LocationServiceResolver.getServiceStatus()['is_tracking']) {
        print('⚠️ Location service not running, starting it first...');
        final locationStarted = await LocationServiceResolver.startTracking(
          onLocationUpdate: (position) {
            print(
              '📍 Map received location update: ${position.latitude}, ${position.longitude}',
            );

            // Update current location and marker
            setState(() {
              _currentLocation = Point(
                coordinates: Position(position.longitude, position.latitude),
              );
            });

            // Update the current location marker with dark green color
            _addCurrentLocationMarker();

            // Force distance update on location change
            RealtimeDistanceTracker.forceDistanceUpdate();
          },
          onLocationError: (error) {
            print('❌ Map location error: $error');
          },
          onUserGuidance: (guidance) {
            print('💡 User guidance: $guidance');
            if (mounted) {
              setState(() {
                _locationGuidance = guidance;
                _showLocationGuidance = true;
              });

              // Auto-hide guidance after 10 seconds
              Timer(Duration(seconds: 10), () {
                if (mounted) {
                  setState(() {
                    _showLocationGuidance = false;
                  });
                }
              });
            }
          },
        );

        if (!locationStarted) {
          print('❌ Failed to start location service');
          return;
        }
      }

      print('📏 Setting up distance tracking callbacks...');
      final trackingStarted =
          await RealtimeDistanceTracker.startDistanceTracking(
            trip: trip,
            onDistanceUpdate: _handleDistanceUpdate,
            onDistanceError: _handleDistanceError,
            onProgressUpdate: _handleProgressUpdate,
          );

      if (trackingStarted) {
        print('✅ Distance tracking started successfully');
        print('📏 Callbacks registered:');
        print('  - onDistanceUpdate: _handleDistanceUpdate');
        print('  - onDistanceError: _handleDistanceError');
        print('  - onProgressUpdate: _handleProgressUpdate');

        // Print tracking status for debugging
        final status = await RealtimeDistanceTracker.getTrackingStatus();
        print('📊 Distance tracking status: $status');
      } else {
        print('❌ Failed to start distance tracking');
      }
    } catch (e) {
      print('❌ Error starting distance tracking: $e');
    }
  }

  /// Stop distance tracking
  void _stopDistanceTracking() {
    try {
      print('📏 Stopping distance tracking...');
      RealtimeDistanceTracker.stopDistanceTracking();

      // Reset distance variables
      _remainingDistance = null;
      _distanceTraveled = null;
      _totalTripDistance = null;
      _progressPercentage = 0.0;

      // Trigger UI update
      if (mounted) {
        setState(() {});
      }

      print('✅ Distance tracking stopped');
    } catch (e) {
      print('❌ Error stopping distance tracking: $e');
    }
  }

  /// Handle distance updates
  void _handleDistanceUpdate(
    double remaining,
    double traveled,
    double total,
  ) async {
    if (!mounted) return;

    print('📏 _handleDistanceUpdate called with:');
    print('  Remaining: ${(remaining / 1000).toStringAsFixed(2)} km');
    print('  Traveled: ${(traveled / 1000).toStringAsFixed(2)} km');
    print('  Total: ${(total / 1000).toStringAsFixed(2)} km');

    setState(() {
      _remainingDistance = remaining;
      _distanceTraveled = traveled;
      _totalTripDistance = total;
    });

    // Calculate remaining time
    final remainingTime = await _calculateRemainingTime();
    setState(() {
      _remainingTime = remainingTime;
    });

    print(
      '📏 UI state updated - _remainingDistance: $_remainingDistance, _distanceTraveled: $_distanceTraveled',
    );
    print('📏 Widget will receive:');
    print('  remainingDistance: $_remainingDistance');
    print('  distanceTraveled: $_distanceTraveled');
    print('  totalTripDistance: $_totalTripDistance');
    print('  remainingTime: ${_formatRemainingTime(_remainingTime)}');

    // Update route line to show only remaining portion
    _updateRouteLineForProgress();
  }

  /// Handle distance errors
  void _handleDistanceError(String error) {
    print('❌ Distance tracking error: $error');
  }

  /// Handle progress updates
  void _handleProgressUpdate(double progress) {
    if (!mounted) return;

    print(
      '📊 _handleProgressUpdate called with: ${progress.toStringAsFixed(1)}%',
    );

    setState(() {
      _progressPercentage = progress;
    });

    print('📊 UI state updated - _progressPercentage: $_progressPercentage');

    // Update route line to show only remaining portion
    _updateRouteLineForProgress();
  }

  /// Update route line to show only remaining portion based on progress
  void _updateRouteLineForProgress() async {
    if (_polylineAnnotationManager == null || _mapboxMap == null) {
      print('❌ Cannot update route line - missing dependencies');
      return;
    }

    // Throttle route updates to prevent excessive redraws
    final now = DateTime.now();
    if (_lastRouteUpdate != null &&
        now.difference(_lastRouteUpdate!) < _minRouteUpdateInterval) {
      print('🔄 Throttling route update (too frequent)');
      return;
    }
    _lastRouteUpdate = now;

    final tripState = ref.read(tripProvider);
    final currentTrip = tripState.currentTrip;
    if (currentTrip == null) {
      print('❌ No active trip for route line update');
      return;
    }

    try {
      // Get current location
      final currentLocation =
          await LocationServiceResolver.getCurrentPosition();
      if (currentLocation == null) {
        print('❌ No current location for route line update');
        return;
      }

      // Get remaining route coordinates based on current position
      final remainingRouteCoordinates =
          await RealtimeDistanceTracker.getRemainingRouteCoordinates();
      if (remainingRouteCoordinates == null ||
          remainingRouteCoordinates.isEmpty) {
        print(
          '❌ No remaining route coordinates available for route line update',
        );
        print('🔄 Falling back to current location route display...');
        // Fall back to showing the route from current location if no remaining coordinates
        await _drawRouteFromCurrentLocation(currentTrip);
        return;
      }

      // Get current route progress for logging
      final routeProgress =
          await RealtimeDistanceTracker.getCurrentRouteProgress();
      print(
        '🔄 Updating route line - Route Progress: ${(routeProgress * 100).toStringAsFixed(1)}%, Remaining points: ${remainingRouteCoordinates.length}',
      );

      if (remainingRouteCoordinates.isEmpty) {
        print('✅ Trip completed - clearing route line');
        await _clearRoutePolyline();
        return;
      }

      // Add current location as the starting point of remaining route
      final currentLocationCoord = {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      };

      final updatedRouteCoordinates = [
        currentLocationCoord,
        ...remainingRouteCoordinates,
      ];

      // Convert to Position objects
      final routePositions = updatedRouteCoordinates
          .map((coord) => Position(coord['longitude']!, coord['latitude']!))
          .toList();

      // Remove existing route polyline
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }

      // Create new route line with remaining portion
      final routeLine = LineString(coordinates: routePositions);

      // Use green color for better identification of current location to destination
      Color routeColor = Colors.green;

      // Create polyline annotation
      final polylineOptions = PolylineAnnotationOptions(
        geometry: routeLine,
        lineColor: routeColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      _routePolyline = await _polylineAnnotationManager!.create(
        polylineOptions,
      );

      print(
        '✅ Route line updated - Remaining points: ${routePositions.length}, Color: ${routeColor.toString()}',
      );
    } catch (e) {
      print('❌ Error updating route line for progress: $e');
    }
  }

  /// Debug distance tracking
  void _debugDistanceTracking() async {
    print('\n🔍 DEBUG: Distance Tracking Status');
    print('===================================');

    // Get tracking status
    final status = await RealtimeDistanceTracker.getTrackingStatus();
    status.forEach((key, value) {
      print('$key: $value');
    });

    // Get formatted distances
    final distances = RealtimeDistanceTracker.getFormattedDistances();
    print('\n📏 Formatted Distances:');
    distances.forEach((key, value) {
      print('$key: $value');
    });

    // Show current UI state
    print('\n📱 Current UI State:');
    print('_remainingDistance: $_remainingDistance');
    print('_distanceTraveled: $_distanceTraveled');
    print('_totalTripDistance: $_totalTripDistance');
    print('_progressPercentage: $_progressPercentage');

    // Force distance update
    print('\n🔄 Forcing distance update...');
    await RealtimeDistanceTracker.forceDistanceUpdate();

    // Show current location
    final currentLocation = await LocationServiceResolver.getCurrentPosition();
    if (currentLocation != null) {
      print('\n📍 Current Location:');
      print('Latitude: ${currentLocation.latitude}');
      print('Longitude: ${currentLocation.longitude}');
      print('Accuracy: ${currentLocation.accuracy}m');
      print('Speed: ${currentLocation.speed.toStringAsFixed(1)} m/s');
    } else {
      print('\n❌ No current location available');
    }
  }

  /// Force distance update for testing
  void _forceDistanceUpdate() async {
    print('🔄 Manually forcing distance update...');
    try {
      await RealtimeDistanceTracker.forceDistanceUpdate();
      print('✅ Distance update forced successfully');
    } catch (e) {
      print('❌ Error forcing distance update: $e');
    }
  }

  /// Check for location service conflicts
  void _checkLocationConflicts() async {
    print('\n🔍 Checking for location service conflicts...');
    try {
      final conflicts = await LocationServiceResolver.checkConflicts();

      print('🔍 Conflict Check Results:');
      print('Has conflicts: ${conflicts['has_conflicts']}');

      if (conflicts['conflicts'].isNotEmpty) {
        print('❌ Conflicts found:');
        for (final conflict in conflicts['conflicts']) {
          print('  - $conflict');
        }
      }

      if (conflicts['recommendations'].isNotEmpty) {
        print('💡 Recommendations:');
        for (final recommendation in conflicts['recommendations']) {
          print('  - $recommendation');
        }
      }

      print('📊 Service Status:');
      final status = conflicts['service_status'] as Map<String, dynamic>;
      status.forEach((key, value) {
        print('  $key: $value');
      });
    } catch (e) {
      print('❌ Error checking conflicts: $e');
    }
  }

  /// Force accept current location (for testing)
  void _forceAcceptLocation() async {
    print('🆘 Force accepting current location...');
    try {
      final position = await LocationServiceResolver.getCurrentPosition();
      if (position != null) {
        LocationServiceResolver.forceAcceptLocation(position);
        print('✅ Location force accepted: ${position.accuracy}m accuracy');
      } else {
        print('❌ No location available to force accept');
      }
    } catch (e) {
      print('❌ Error force accepting location: $e');
    }
  }

  /// Force restart location service (for debugging)
  void _forceRestartLocationService() async {
    print('🔄 Force restarting location service...');
    try {
      await LocationServiceResolver.forceRestart();
      print('✅ Location service force restarted');
    } catch (e) {
      print('❌ Error force restarting location service: $e');
    }
  }

  /// Calculate remaining time to destination
  Future<Duration?> _calculateRemainingTime() async {
    try {
      final tripState = ref.read(tripProvider);
      final currentTrip = tripState.currentTrip;
      if (currentTrip == null) return null;

      // Get remaining distance
      final remainingDistance = _remainingDistance;
      if (remainingDistance == null || remainingDistance <= 0) return null;

      // Get current speed (if available from location service)
      final currentLocation =
          await LocationServiceResolver.getCurrentPosition();
      if (currentLocation == null) return null;

      // Estimate speed based on recent movement (simplified)
      // In a real implementation, you'd track speed over time
      const double estimatedSpeedKmh = 30.0; // Default school bus speed

      // Calculate time in minutes
      final timeInMinutes = (remainingDistance / 1000) / estimatedSpeedKmh * 60;

      return Duration(minutes: timeInMinutes.round());
    } catch (e) {
      print('❌ Error calculating remaining time: $e');
      return null;
    }
  }

  /// Format remaining time for display
  String _formatRemainingTime(Duration? remainingTime) {
    if (remainingTime == null) return 'Calculating...';

    if (remainingTime.inHours > 0) {
      return '${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m';
    } else {
      return '${remainingTime.inMinutes}m';
    }
  }

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Get location name from coordinates (simplified version)
  String _getLocationName(
    double? latitude,
    double? longitude,
    String? locationName,
  ) {
    if (locationName != null && locationName.isNotEmpty) {
      return locationName;
    }

    if (latitude != null && longitude != null) {
      // Return a simplified coordinate format for display
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }

    return 'Unknown Location';
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    if (_geocodeCache.containsKey(key)) return _geocodeCache[key];
    try {
      final places = await geocoding.placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty) {
        final p = places.first;
        final street = [p.street, p.thoroughfare, p.subLocality]
            .where((e) => e != null && e.trim().isNotEmpty)
            .map((e) => e!.trim())
            .toList()
            .join(', ');
        final city = [p.locality, p.administrativeArea]
            .where((e) => e != null && e.trim().isNotEmpty)
            .map((e) => e!.trim())
            .toList()
            .join(', ');
        final result = street.isNotEmpty
            ? (city.isNotEmpty ? '$street • $city' : street)
            : (city.isNotEmpty ? city : null);
        if (result != null) {
          _geocodeCache[key] = result;
        }
        return result;
      }
    } catch (_) {}
    return null;
  }

  void _centerMapOnCurrentLocation() {
    () async {
      final fresh = await LocationServiceResolver.getCurrentPosition();
      if (fresh != null) {
        _currentLocation = Point(
          coordinates: Position(fresh.longitude, fresh.latitude),
        );
      }
      if (_mapboxMap != null && _currentLocation != null) {
        _mapboxMap!.flyTo(
          CameraOptions(center: _currentLocation!, zoom: 16.0),
          MapAnimationOptions(duration: 900),
        );
      }
    }();
  }

  void _zoomToTripRoute(Trip trip) async {
    if (_mapboxMap == null) {
      print('❌ DEBUG: Cannot zoom - map not ready');
      return;
    }

    // Collect all relevant points to show
    List<Position> pointsToShow = [];
    const double maxReasonableDistanceKm =
        50.0; // Maximum distance to include trip points

    // Always prioritize current location if available
    if (_currentLocation != null) {
      pointsToShow.add(_currentLocation!.coordinates);
      print('📍 Including current location in bounds');

      // Check if trip locations are within reasonable distance
      bool tripStartInRange = false;
      bool tripEndInRange = false;

      if (trip.startLatitude != null && trip.startLongitude != null) {
        final distance = _calculateDistance(
          _currentLocation!.coordinates.lat.toDouble(),
          _currentLocation!.coordinates.lng.toDouble(),
          trip.startLatitude!,
          trip.startLongitude!,
        );
        if (distance <= maxReasonableDistanceKm) {
          pointsToShow.add(Position(trip.startLongitude!, trip.startLatitude!));
          tripStartInRange = true;
          print(
            '🚀 Including trip start in bounds (${distance.toStringAsFixed(1)}km away)',
          );
        } else {
          print(
            '⚠️ Trip start too far (${distance.toStringAsFixed(1)}km) - not including in bounds',
          );
        }
      }

      if (trip.endLatitude != null && trip.endLongitude != null) {
        final distance = _calculateDistance(
          _currentLocation!.coordinates.lat.toDouble(),
          _currentLocation!.coordinates.lng.toDouble(),
          trip.endLatitude!,
          trip.endLongitude!,
        );
        if (distance <= maxReasonableDistanceKm) {
          pointsToShow.add(Position(trip.endLongitude!, trip.endLatitude!));
          tripEndInRange = true;
          print(
            '🏁 Including trip end in bounds (${distance.toStringAsFixed(1)}km away)',
          );
        } else {
          print(
            '⚠️ Trip end too far (${distance.toStringAsFixed(1)}km) - not including in bounds',
          );
        }
      }

      // If trip points are too far, just center on current location
      if (!tripStartInRange && !tripEndInRange) {
        print('📍 Trip locations too far - centering on current location only');
        _mapboxMap!.flyTo(
          CameraOptions(center: _currentLocation!, zoom: 16.0),
          MapAnimationOptions(duration: 1200),
        );
        return;
      }
    } else {
      // No current location - add trip points if available
      if (trip.startLatitude != null && trip.startLongitude != null) {
        pointsToShow.add(Position(trip.startLongitude!, trip.startLatitude!));
        print('🚀 Including trip start in bounds (no current location)');
      }
      if (trip.endLatitude != null && trip.endLongitude != null) {
        pointsToShow.add(Position(trip.endLongitude!, trip.endLatitude!));
        print('🏁 Including trip end in bounds (no current location)');
      }
    }

    if (pointsToShow.isEmpty) {
      print('❌ DEBUG: No valid points to zoom to');
      return;
    }

    // Calculate bounds to fit all points
    double minLat = pointsToShow.first.lat.toDouble();
    double maxLat = pointsToShow.first.lat.toDouble();
    double minLng = pointsToShow.first.lng.toDouble();
    double maxLng = pointsToShow.first.lng.toDouble();

    for (final point in pointsToShow) {
      final lat = point.lat.toDouble();
      final lng = point.lng.toDouble();
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    // Calculate center point
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calculate zoom level based on bounds
    // If points are close together, zoom in more; if far apart, zoom out
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    double zoom;
    if (maxDiff > 0.1) {
      // Points are far apart (more than ~11km)
      zoom = 11.0;
    } else if (maxDiff > 0.05) {
      // Points are moderately apart (5-11km)
      zoom = 12.0;
    } else if (maxDiff > 0.01) {
      // Points are close (1-5km)
      zoom = 13.5;
    } else {
      // Points are very close (<1km)
      zoom = 15.0;
    }

    // If we only have one point (current location), use a closer zoom
    if (pointsToShow.length == 1 && _currentLocation != null) {
      zoom = 16.0;
    }

    final centerPoint = Point(coordinates: Position(centerLng, centerLat));

    _mapboxMap!.flyTo(
      CameraOptions(center: centerPoint, zoom: zoom),
      MapAnimationOptions(duration: 1200),
    );
    print(
      '✅ DEBUG: Map zoomed to fit ${pointsToShow.length} points (bounds: ${minLat.toStringAsFixed(4)}, ${minLng.toStringAsFixed(4)} to ${maxLat.toStringAsFixed(4)}, ${maxLng.toStringAsFixed(4)}, zoom: ${zoom.toStringAsFixed(1)})',
    );
  }

  Future<void> _clearRoutePolyline() async {
    _plannedRouteTripId = null;
    _cachedRouteStops = null;
    if (_polylineAnnotationManager != null && _routePolyline != null) {
      try {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
        print('✅ Route polyline cleared');
      } catch (e) {
        print('❌ Error clearing route polyline: $e');
      }
    }
    await _clearParentToStartPolyline();
  }

  void _refreshMapData() async {
    if (!mounted) return;

    print('🔄 Refreshing map data...');

    // Refresh active trip data
    await _loadTrackingTrips();

    // Update map with new data
    if (_mapboxMap != null) {
      _addCurrentLocationMarker();
      _loadTripRoute();
      _addTripMarkers();
    }
  }

  /// Message driver - creates parent-driver chat from tracking screen.
  /// Uses createDriverParentChat(studentId) per web/desktop guide.
  Future<void> _messageDriver() async {
    if (_isCreatingDriverChat) return;
    final currentTrip = _getCurrentMapTrip();
    if (currentTrip == null) return;

    final parentState = ref.read(parentProvider);
    final students = parentState.students;
    if (students.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No students linked. Add a student to message the driver.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isCreatingDriverChat = true);
    try {
      // Student-based: backend resolves parent and driver from student
      final studentId = students.first.id;
      var resp = await CommunicationService.createDriverParentChat(
        studentId: studentId,
      );

      // Fallback: driver-based if student endpoint fails
      if (!resp.success && currentTrip.driverId > 0) {
        resp = await CommunicationService.createChat(
          chatType: 'driver_parent',
          otherUserId: currentTrip.driverId,
          studentId: studentId,
        );
      }

      if (!mounted) return;
      if (resp.success && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        final rawId =
            data['id'] ?? data['chat_id'] ?? (data['chat'] as Map?)?['id'];
        final chatId = rawId is int ? rawId : null;
        if (chatId != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chatId)),
          );
        } else {
          _showChatErrorSnackBar(
            resp.error ?? 'Chat created but could not open',
          );
        }
      } else {
        _showChatErrorSnackBar(
          resp.error ?? 'Could not start chat with driver',
        );
      }
    } catch (e) {
      if (mounted) _showChatErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isCreatingDriverChat = false);
    }
  }

  void _showChatErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _toggleRouteVisibility() async {
    if (_routePolyline == null) {
      // Route is not visible, show it from current location
      final currentTrip = _getCurrentMapTrip();
      if (currentTrip != null) {
        await _drawRouteFromCurrentLocation(currentTrip);
        print('✅ Route polyline shown from current location');
      }
    } else {
      // Route is visible, hide it
      await _clearRoutePolyline();
      print('✅ Route polyline hidden');
    }
  }

  void _addTestGreenMarker() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Cannot add test green marker - map not ready');
      return;
    }

    try {
      print('🟢 DEBUG: Adding test green marker...');

      // Add a test green marker at a known location
      final testPoint = Point(
        coordinates: Position(36.817223, -1.286389), // Nairobi coordinates
      );

      final testGreenMarker = PointAnnotationOptions(
        geometry: testPoint,
        image: await _createMarkerImage(Colors.green, '🚀'),
      );

      await _pointAnnotationManager!.create(testGreenMarker);
      print('✅ Test green marker added successfully');
    } catch (e) {
      print('❌ Error adding test green marker: $e');
    }
  }

  Future<Uint8List> _createAbbreviationMarkerImage(
    Color color,
    String label,
  ) async {
    final text = label.trim().isEmpty ? '?' : label.trim().toUpperCase();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 56.0;
    final fontSize = text.length <= 2
        ? size * 0.38
        : text.length <= 4
        ? size * 0.28
        : size * 0.22;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final circleRadius = size * 0.38;
    canvas.drawCircle(Offset(size / 2, size / 2), circleRadius, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(size / 2, size / 2), circleRadius, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createMarkerImage(Color color, String emoji) async {
    print('🎨 DEBUG: Creating marker image - Color: $color, Emoji: $emoji');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 60.0; // Increased from 40.0 for better visibility

    // Draw pin shape background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create pin shape (rounded rectangle with pointed bottom)
    final pinPath = Path();
    final pinWidth = size * 0.6;
    final pinHeight = size * 0.8;
    final cornerRadius = size * 0.15;

    // Top rounded rectangle
    pinPath.addRRect(
      RRect.fromLTRBR(
        (size - pinWidth) / 2,
        (size - pinHeight) / 2,
        (size + pinWidth) / 2,
        (size + pinHeight) / 2 - size * 0.1,
        Radius.circular(cornerRadius),
      ),
    );

    // Bottom pointed triangle
    pinPath.moveTo(size / 2, (size + pinHeight) / 2 - size * 0.1);
    pinPath.lineTo(
      size / 2 - pinWidth / 3,
      (size + pinHeight) / 2 + size * 0.1,
    );
    pinPath.lineTo(
      size / 2 + pinWidth / 3,
      (size + pinHeight) / 2 + size * 0.1,
    );
    pinPath.close();

    canvas.drawPath(pinPath, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(pinPath, borderPaint);

    // Draw emoji in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size * 0.4, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - size * 0.05, // Slightly above center
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    print(
      '🎨 DEBUG: Pin marker image created successfully - Size: ${byteData!.lengthInBytes} bytes',
    );
    return byteData.buffer.asUint8List();
  }
}

// No Active Trip Card
class _NoActiveTripCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 32.w, color: const Color(0xFF0052CC)),
          SizedBox(height: 8.h),
          Text(
            'Map Ready',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0052CC),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'No active trips. The map is ready for navigation.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20.w,
                  color: Colors.orange[800],
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'No active trip. Wait for an active trip to communicate with driver.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.orange[800],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Trip Details Card with Dropdown

class _TripDetailsCard extends StatefulWidget {
  final TripState tripState;
  final Point? currentLocation;
  final double? remainingDistance;
  final double? distanceTraveled;
  final double? totalTripDistance;
  final double progressPercentage;
  final Duration? remainingTime;
  final String? currentStreetName;
  final String? destinationStreetName;
  final VoidCallback? onMessageDriver;
  final bool isCreatingDriverChat;

  const _TripDetailsCard({
    required this.tripState,
    this.currentLocation,
    this.remainingDistance,
    this.distanceTraveled,
    this.totalTripDistance,
    this.progressPercentage = 0.0,
    this.remainingTime,
    this.currentStreetName,
    this.destinationStreetName,
    this.onMessageDriver,
    this.isCreatingDriverChat = false,
  });

  @override
  State<_TripDetailsCard> createState() => _TripDetailsCardState();
}

class _TripDetailsCardState extends State<_TripDetailsCard> {
  bool _isExpanded = false;

  /// Format remaining time for display
  String _formatRemainingTime(Duration remainingTime) {
    if (remainingTime.inHours > 0) {
      return '${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m';
    } else {
      return '${remainingTime.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTrip = widget.tripState.currentTrip;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Trip Info (Always Visible)
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Trip Header
                Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: currentTrip != null
                            ? const Color(0xFF667EEA)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrip != null
                                ? 'Active Trip'
                                : 'No Active Trip',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            currentTrip?.tripId ??
                                'Start a trip to see details',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentTrip != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: 20.w,
                          ),
                        ),
                      ),
                  ],
                ),

                if (currentTrip != null) ...[
                  SizedBox(height: 16.h),

                  // Trip Status
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            currentTrip.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _getStatusText(currentTrip.status),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(currentTrip.status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(currentTrip.actualStart),
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Expanded Trip Details (Dropdown)
          if (_isExpanded && currentTrip != null)
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
              child: Column(
                children: [
                  Container(height: 1.h, color: Colors.grey[200]),
                  SizedBox(height: 16.h),

                  // Trip Details
                  _TripDetailRow(
                    icon: Icons.route,
                    label: 'Route',
                    value: currentTrip.routeName ?? 'Unknown',
                  ),
                  SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.directions_bus,
                    label: 'Vehicle',
                    value: currentTrip.vehicleName ?? 'Unknown',
                  ),
                  SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.person,
                    label: 'Driver',
                    value: currentTrip.driverName ?? 'Unknown',
                  ),
                  if (widget.onMessageDriver != null) ...[
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isCreatingDriverChat
                              ? null
                              : widget.onMessageDriver,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0052CC).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(0xFF0052CC).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.isCreatingDriverChat)
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 20.w,
                                    color: const Color(0xFF0052CC),
                                  ),
                                SizedBox(width: 8.w),
                                Text(
                                  widget.isCreatingDriverChat
                                      ? 'Starting chat...'
                                      : 'Message driver',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0052CC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Distance Information
                  // Debug: Check what distance values we have
                  if (widget.remainingDistance != null ||
                      widget.distanceTraveled != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'DEBUG: remaining=${widget.remainingDistance}, traveled=${widget.distanceTraveled}, total=${widget.totalTripDistance}',
                        style: GoogleFonts.poppins(fontSize: 10.sp),
                      ),
                    ),
                  ],
                  // Always show distance information section
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        // Streets (if available)
                        if (widget.currentStreetName != null ||
                            widget.destinationStreetName != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 14.w,
                                color: Colors.green,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  widget.currentStreetName ??
                                      'Current street resolving...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    color: Colors.green[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.flag, size: 14.w, color: Colors.red),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  widget.destinationStreetName ??
                                      'Destination street resolving...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    color: Colors.red[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                        ],
                        // Progress Header
                        Row(
                          children: [
                            Icon(
                              Icons.timeline,
                              color: const Color(0xFF667EEA),
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Trip Progress',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.progressPercentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Progress Bar
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (widget.progressPercentage / 100)
                                .clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Distance Information
                        Row(
                          children: [
                            Expanded(
                              child: _DistanceInfo(
                                icon: Icons.navigation,
                                label: 'Remaining',
                                value: widget.remainingDistance != null
                                    ? '${(widget.remainingDistance! / 1000).toStringAsFixed(2)} km'
                                    : 'Calculating...',
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _DistanceInfo(
                                icon: Icons.check_circle,
                                label: 'Traveled',
                                value: widget.distanceTraveled != null
                                    ? '${(widget.distanceTraveled! / 1000).toStringAsFixed(2)} km'
                                    : 'Calculating...',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // Time Information
                        if (widget.remainingTime != null) ...[
                          SizedBox(height: 12.h),
                          _TimeInfo(
                            icon: Icons.access_time,
                            label: 'Estimated Arrival',
                            value: _formatRemainingTime(widget.remainingTime!),
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  if (currentTrip.startLocation != null)
                    _TripDetailRow(
                      icon: Icons.location_on,
                      label: 'Start Location',
                      value: currentTrip.startLocation!,
                    ),

                  if (currentTrip.startLocation != null) SizedBox(height: 12.h),

                  if (currentTrip.endLocation != null)
                    _TripDetailRow(
                      icon: Icons.flag,
                      label: 'End Location',
                      value: currentTrip.endLocation!,
                    ),

                  if (currentTrip.endLocation != null) SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: currentTrip.duration != null
                        ? '${currentTrip.duration} minutes'
                        : 'Not available',
                  ),

                  // ETA Information
                  if (currentTrip.estimatedArrival != null) ...[
                    SizedBox(height: 12.h),
                    _buildETASection(currentTrip),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.inProgress:
        return Colors.green;
      case TripStatus.completed:
        return Colors.blue;
      case TripStatus.cancelled:
        return Colors.red;
      case TripStatus.delayed:
        return Colors.amber;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'PENDING';
      case TripStatus.inProgress:
        return 'IN PROGRESS';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
      case TripStatus.delayed:
        return 'DELAYED';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Not started';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildETASection(Trip trip) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: trip.isRunningLate
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: trip.isRunningLate
              ? Colors.red.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ETA Header
          Row(
            children: [
              Icon(
                trip.isRunningLate ? Icons.warning : Icons.access_time,
                size: 16.w,
                color: trip.isRunningLate ? Colors.red : Colors.blue,
              ),
              SizedBox(width: 8.w),
              Text(
                'Estimated Arrival',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: trip.isRunningLate ? Colors.red : Colors.blue,
                ),
              ),
              const Spacer(),
              if (trip.isRunningLate)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'DELAYED',
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 8.h),

          // ETA Time
          Row(
            children: [
              Text(
                'ETA: ',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                trip.formattedTimeToArrival,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: trip.isRunningLate ? Colors.red : Colors.blue,
                ),
              ),
              const Spacer(),
              Text(
                _formatETA(trip.estimatedArrival!),
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),

          // Traffic Conditions
          if (trip.trafficConditions != 'Unknown') ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.traffic, size: 12.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  trip.trafficConditions,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inHours > 0) {
      return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
    } else {
      return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _TripDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CurrentLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.my_location, color: Colors.grey[700], size: 24.w),
      ),
    );
  }
}

class _FollowVehicleButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _FollowVehicleButton({
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.gps_fixed,
          color: isEnabled ? Colors.white : Colors.grey[700],
          size: 24.w,
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RefreshButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.refresh, color: Colors.grey[700], size: 24.w),
      ),
    );
  }
}

class _TestGreenMarkerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TestGreenMarkerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.place, color: Colors.white, size: 24.w),
      ),
    );
  }
}

class _ZoomToStartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ZoomToStartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.navigation, color: Colors.white, size: 24.w),
      ),
    );
  }
}

class _ToggleRouteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ToggleRouteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.route, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Distance Information Widget
class _DistanceInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DistanceInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Time Information Widget
class _TimeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Debug Distance Button Widget
class _DebugDistanceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DebugDistanceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.bug_report, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Force Distance Update Button Widget
class _ForceDistanceUpdateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForceDistanceUpdateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.refresh, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Location Guidance Banner Widget
class _LocationGuidanceBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _LocationGuidanceBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.white, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, color: Colors.white, size: 20.w),
          ),
        ],
      ),
    );
  }
}

// Check Conflicts Button Widget
class _CheckConflictsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CheckConflictsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.bug_report, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Force Accept Location Button Widget
class _ForceAcceptLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForceAcceptLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.location_on, color: Colors.white, size: 24.w),
      ),
    );
  }
}

class _ForceRestartLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForceRestartLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.restart_alt, color: Colors.white, size: 24.w),
      ),
    );
  }
}
