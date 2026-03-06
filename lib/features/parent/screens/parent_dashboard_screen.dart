import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/models/parent_trip_model.dart';
import '../../../core/models/parent_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service_resolver.dart';
import '../widgets/bus_tracking_card.dart';
import '../widgets/child_status_card.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _currentLocationAnnotation;
  Map<String, dynamic>? _lastLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  @override
  void dispose() {
    _mapboxMap = null;
    _pointAnnotationManager = null;
    super.dispose();
  }

  void _initializeDashboard() {
    // Load parent data
    ref.read(parentProvider.notifier).loadParentData();

    // Start notification monitoring
    ref.read(parentProvider.notifier).startNotificationMonitoring();

    // Start location tracking when user is authenticated
    _startLocationTracking();

    // Notification listener disabled to prevent app blocking on some devices
    // _autoRequestNotificationListenerPermission();
  }

  Future<void> _startLocationTracking() async {
    try {
      print('📍 Starting location tracking for authenticated parent...');
      await ref.read(parentProvider.notifier).startLocationTracking();
      
      // Get initial position immediately to show on map
      final initialPosition = await LocationServiceResolver.getCurrentPosition();
      if (initialPosition != null && mounted) {
        print('📍 Got initial position: ${initialPosition.latitude}, ${initialPosition.longitude}');
        // Update the map if it's already created
        if (_mapboxMap != null && _pointAnnotationManager != null) {
          await _updateLocationMarker({
            'latitude': initialPosition.latitude,
            'longitude': initialPosition.longitude,
            'accuracy': initialPosition.accuracy,
            'timestamp': initialPosition.timestamp?.toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('❌ Failed to start location tracking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);
    final authState = ref.watch(parentAuthProvider);

    // Listen for authentication state changes and start location tracking
    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      if ((previous == null || !previous.isAuthenticated) &&
          next.isAuthenticated &&
          mounted) {
        print('🔐 User authenticated, starting location tracking...');
        _startLocationTracking();
      }
    });

    // Listen for location updates and update map marker
    ref.listen<ParentState>(parentProvider, (previous, next) {
      if (next.currentLocation != null &&
          _mapboxMap != null &&
          _pointAnnotationManager != null &&
          mounted) {
        final currentLocation = next.currentLocation!;
        final locationKey = '${currentLocation['latitude']}_${currentLocation['longitude']}';
        final lastLocationKey = _lastLocation != null 
            ? '${_lastLocation!['latitude']}_${_lastLocation!['longitude']}'
            : null;
        
        if (locationKey != lastLocationKey) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateLocationMarker(currentLocation);
          });
          _lastLocation = Map<String, dynamic>.from(currentLocation);
        }
      }
    });

    // Check authentication first
    if (!authState.isAuthenticated) {
      return _buildNotAuthenticatedState(context);
    }

    // Show loading state
    if (parentState.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.h,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Loading your dashboard...',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (parentState.error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 56.w,
                    color: AppTheme.errorColor,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  parentState.error!,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28.h),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(parentProvider.notifier).refreshData(),
                  icon: Icon(Icons.refresh_rounded, size: 20.w),
                  label: Text('Try Again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(parentProvider.notifier).refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section - Modern gradient header
              _buildWelcomeSection(authState.parent),

              // Active Trips Section
              if (parentState.activeTrips.isNotEmpty) ...[
                _buildActiveTripsSection(parentState.activeTrips),
                SizedBox(height: 20.h),
              ],

              // Children Status Section
              if (parentState.children.isNotEmpty) ...[
                _buildChildrenStatusSection(parentState.children),
                SizedBox(height: 20.h),
              ],

              // Bus Tracking Map - commented out for mobile
              // _buildBusTrackingMap(parentState),
              // SizedBox(height: 20.h),

              // Quick Actions
              _buildQuickActionsSection(),
              SizedBox(height: 20.h),

              // Recent Notifications
              _buildRecentNotificationsSection(parentState.notifications),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(parent) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 24.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryVariant,
            const Color(0xFF1E40AF),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 28.w,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()}!',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  (parent?.fullName ?? '').trim().isEmpty
                      ? 'Parent'
                      : (parent?.fullName ?? 'Parent').trim(),
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Track your children\'s safety in real-time',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripsSection(List<ParentTrip> activeTrips) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.directions_bus_rounded,
            title: 'Active Trips',
          ),
          SizedBox(height: 14.h),
          ...activeTrips.map((trip) => BusTrackingCard(trip: trip)),
        ],
      ),
    );
  }

  Widget _buildChildrenStatusSection(List<Child> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.family_restroom_rounded,
            title: 'Children Status',
          ),
          SizedBox(height: 14.h),
          ...children.map((child) => ChildStatusCard(child: child)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 20.w, color: AppTheme.primaryColor),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBusTrackingMap(ParentState parentState) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 200.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            // Real Mapbox Map with error handling
            _buildMapWidget(parentState),
            // Bus location indicator
            if (parentState.currentLocation != null)
              Positioned(
                top: 20.h,
                left: 20.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_bus,
                        color: const Color(0xFF0052CC),
                        size: 16.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Bus Location',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.flash_on_rounded,
            title: 'Quick Actions',
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.directions_bus_rounded,
                  label: 'Track Bus',
                  onTap: () => context.go('/parent/tracking'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.schedule_rounded,
                  label: 'Schedule',
                  onTap: () => context.go('/parent/schedule'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chats',
                  onTap: () => context.go('/chats'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.school_rounded,
                  label: 'Students',
                  onTap: () => context.go('/parent/students'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'QR Scanner',
                  onTap: () => context.go('/parent/qr-scanner'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map_rounded,
                  label: 'Map View',
                  onTap: () => context.go('/parent/map'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _QuickActionCard(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            onTap: () => context.go('/parent/notifications'),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotificationsSection(
    List<Map<String, dynamic>> notifications,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildSectionHeader(
                  icon: Icons.notifications_rounded,
                  title: 'Recent Notifications',
                ),
              ),
              TextButton(
                onPressed: () => context.go('/parent/notifications'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (notifications.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 28.w, horizontal: 20.w),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppTheme.borderColor.withOpacity(0.5),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 24.w,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'No recent notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...notifications.take(3).map(
                  (notification) => Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: AppTheme.primaryColor,
                            size: 20.w,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            notification['message'] ?? 'Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
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

  Widget _buildMapWidget(ParentState parentState) {
    try {
      return MapWidget(
        key: const ValueKey("dashboardMapWidget"),
        cameraOptions: CameraOptions(
          center: parentState.currentLocation != null
              ? Point(
                  coordinates: Position(
                    parentState.currentLocation!['longitude'] as double,
                    parentState.currentLocation!['latitude'] as double,
                  ),
                )
              : Point(
                  coordinates: Position(
                    AppConfig.defaultLongitude,
                    AppConfig.defaultLatitude,
                  ),
                ),
          zoom: parentState.currentLocation != null ? 15.0 : 12.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        onMapCreated: (MapboxMap mapboxMap) async {
          print('🗺️ Dashboard map created successfully');
          _mapboxMap = mapboxMap;
          
          // Create annotation manager
          try {
            _pointAnnotationManager = await mapboxMap.annotations
                .createPointAnnotationManager();
            print('✅ Point annotation manager created');
          } catch (e) {
            print('❌ Failed to create annotation manager: $e');
          }

          // Add current location marker if available
          if (parentState.currentLocation != null) {
            await _updateLocationMarker(parentState.currentLocation!);
          } else {
            // Try to get current location immediately if not in state yet
            try {
              final position = await LocationServiceResolver.getCurrentPosition();
              if (position != null) {
                await _updateLocationMarker({
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'accuracy': position.accuracy,
                  'timestamp': position.timestamp?.toIso8601String(),
                });
              }
            } catch (e) {
              print('⚠️ Could not get initial location: $e');
            }
          }
        },
      );
    } catch (e) {
      print('❌ Failed to create map widget: $e');
      // Fallback to a simple container with map placeholder
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48.w, color: Colors.grey[400]),
              SizedBox(height: 8.h),
              Text(
                'Map unavailable',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _updateLocationMarker(Map<String, dynamic> location) async {
    if (_mapboxMap == null || _pointAnnotationManager == null) {
      return;
    }

    try {
      final latitude = location['latitude'] as double;
      final longitude = location['longitude'] as double;

      print(
        '📍 Updating location marker: $latitude, $longitude',
      );

      // Remove existing marker if any
      if (_currentLocationAnnotation != null) {
        try {
          await _pointAnnotationManager!.delete(_currentLocationAnnotation!);
        } catch (e) {
          print('⚠️ Could not delete old marker: $e');
        }
        _currentLocationAnnotation = null;
      }

      // Create new marker
      final locationPoint = Point(
        coordinates: Position(longitude, latitude),
      );

      final locationMarker = PointAnnotationOptions(
        geometry: locationPoint,
        image: await _createLocationMarker(),
      );

      _currentLocationAnnotation = await _pointAnnotationManager!.create(locationMarker);

      // Fly camera to location
      if (_mapboxMap != null) {
        _mapboxMap!.flyTo(
          CameraOptions(center: locationPoint, zoom: 15.0),
          MapAnimationOptions(duration: 1000),
        );
      }

      print('✅ Location marker updated successfully');
    } catch (e) {
      print('❌ Failed to update location marker: $e');
    }
  }

  Future<Uint8List> _createLocationMarker() async {
    const size = 50.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Pushpin head (circular top)
    final headRadius = size * 0.25;
    final headCenter = Offset(size / 2, headRadius + 2);
    
    // Draw shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headCenter.dx + 1, headCenter.dy + 1),
      headRadius,
      shadowPaint,
    );
    
    // Draw pushpin head (red circle)
    final headPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headRadius, headPaint);
    
    // Draw highlight on head
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.3, headCenter.dy - headRadius * 0.3),
      headRadius * 0.4,
      highlightPaint,
    );
    
    // Draw pin point (triangle pointing down)
    final pinPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;
    
    final pinTop = headCenter.dy + headRadius;
    final pinBottom = size - 2;
    final pinWidth = size * 0.15;
    
    final pinPath = Path()
      ..moveTo(size / 2, pinTop)
      ..lineTo(size / 2 - pinWidth, pinBottom)
      ..lineTo(size / 2 + pinWidth, pinBottom)
      ..close();
    
    canvas.drawPath(pinPath, pinPaint);
    
    // Draw white center dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headCenter, headRadius * 0.3, dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Widget _buildNotAuthenticatedState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 64.w,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'Authentication Required',
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Please log in to access your dashboard.',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),
              FilledButton(
                onPressed: () => context.go('/login'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 36.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Go to Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
        margin: fullWidth ? EdgeInsets.zero : null,
        padding: EdgeInsets.symmetric(
          vertical: 18.w,
          horizontal: fullWidth ? 20.w : 16.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: AppTheme.borderColor.withOpacity(0.5),
          ),
        ),
        child: fullWidth
            ? Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.15),
                          AppTheme.secondaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.primaryColor,
                      size: 22.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14.w,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.12),
                          AppTheme.secondaryColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(icon, color: AppTheme.primaryColor, size: 24.w),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
