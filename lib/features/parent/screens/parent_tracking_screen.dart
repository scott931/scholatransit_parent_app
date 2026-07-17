import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/parent_trip_model.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/screens/map_screen.dart';

class ParentTrackingScreen extends ConsumerStatefulWidget {
  const ParentTrackingScreen({super.key});

  @override
  ConsumerState<ParentTrackingScreen> createState() =>
      _ParentTrackingScreenState();
}

class _ParentTrackingScreenState extends ConsumerState<ParentTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentProvider.notifier).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);

    if (parentState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    final liveTrips = parentState.activeTrips.liveTrips;

    // Live tracking only when a bus trip is in progress on the road.
    if (liveTrips.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: RefreshIndicator(
          onRefresh: () => ref.read(parentProvider.notifier).refreshData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 56.w,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'No Active Trips',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Live tracking will appear here when your child\'s bus trip is in progress. Pull down to refresh.',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const MapScreen(pollActiveTrips: true);
  }
}
