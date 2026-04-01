import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../map/screens/map_screen.dart';

class ParentTrackingScreen extends ConsumerWidget {
  const ParentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Only show map and bus tracking when there's an active trip
    if (parentState.activeTrips.isEmpty) {
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
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 56.w,
                    color: AppTheme.primaryColor.withOpacity(0.6),
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
                  'Live tracking will appear here when your child has an active bus trip.',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MapScreen(pollActiveTrips: true);
  }
}
