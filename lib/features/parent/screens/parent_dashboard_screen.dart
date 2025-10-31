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
import '../widgets/bus_tracking_card.dart';
import '../widgets/child_status_card.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  void _initializeDashboard() {
    // Load parent data
    ref.read(parentProvider.notifier).loadParentData();

    // Start notification monitoring
    ref.read(parentProvider.notifier).startNotificationMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);
    final authState = ref.watch(parentAuthProvider);

    // Check authentication first
    if (!authState.isAuthenticated) {
      return _buildNotAuthenticatedState(context);
    }

    // Show loading state
    if (parentState.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (parentState.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.w, color: Colors.red[300]),
              SizedBox(height: 16.h),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                parentState.error!,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () =>
                    ref.read(parentProvider.notifier).refreshData(),
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(parentProvider.notifier).refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
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

              // Bus Tracking Map
              _buildBusTrackingMap(parentState),
              SizedBox(height: 20.h),

              // Quick Actions
              _buildQuickActionsSection(),
              SizedBox(height: 20.h),

              // Recent Notifications
              _buildRecentNotificationsSection(parentState.notifications),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(parent) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 10.w, 20.w, 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF0052CC).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()}!',
            style: GoogleFonts.poppins(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0052CC),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            parent?.fullName ?? 'Parent',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Track your children\'s safety in real-time',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripsSection(List<ParentTrip> activeTrips) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Trips',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          ...activeTrips.map((trip) => BusTrackingCard(trip: trip)),
        ],
      ),
    );
  }

  Widget _buildChildrenStatusSection(List<Child> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Children Status',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          ...children.map((child) => ChildStatusCard(child: child)),
        ],
      ),
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
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.directions_bus,
                  label: 'Track Bus',
                  onTap: () => context.go('/parent/tracking'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.schedule,
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
                  icon: Icons.chat,
                  label: 'Chats',
                  onTap: () => context.go('/chats'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.school,
                  label: 'Students',
                  onTap: () => context.go('/parent/students'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.qr_code_scanner,
                  label: 'QR Scanner',
                  onTap: () => context.go('/parent/qr-scanner'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map,
                  label: 'Map View',
                  onTap: () => context.go('/parent/map'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  onTap: () => context.go('/parent/notifications'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotificationsSection(
    List<Map<String, dynamic>> notifications,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/parent/notifications'),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF0052CC),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (notifications.isEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'No recent notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...notifications
                .take(3)
                .map(
                  (notification) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: const Color(0xFF0052CC),
                          size: 20.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            notification['message'] ?? 'Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.black,
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
          zoom: 12.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        onMapCreated: (MapboxMap mapboxMap) async {
          print('🗺️ Dashboard map created successfully');
          // Add current location marker if available
          if (parentState.currentLocation != null) {
            try {
              final pointAnnotationManager = await mapboxMap.annotations
                  .createPointAnnotationManager();

              await pointAnnotationManager.create(
                PointAnnotationOptions(
                  geometry: Point(
                    coordinates: Position(
                      parentState.currentLocation!['longitude'] as double,
                      parentState.currentLocation!['latitude'] as double,
                    ),
                  ),
                  image: await _createLocationMarker(),
                ),
              );
            } catch (e) {
              print('❌ Failed to add location marker: $e');
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

  Future<Uint8List> _createLocationMarker() async {
    const size = 40.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = const Color(0xFF0052CC)
      ..style = PaintingStyle.fill;

    // Draw circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 2, paint);

    // Draw white center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 4, centerPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Widget _buildNotAuthenticatedState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80.w, color: Colors.grey[400]),
              SizedBox(height: 24.h),
              Text(
                'Authentication Required',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Please log in to access your dashboard.',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  'Go to Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.white,
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

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: const Color(0xFF0052CC), size: 20.w),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
