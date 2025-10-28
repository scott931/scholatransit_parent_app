import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/attendance_history_model.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final AttendanceSummary summary;

  const AttendanceSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryColor,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'Attendance Summary',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Trips',
                  summary.totalTrips.toString(),
                  Icons.directions_bus,
                  AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  'Present',
                  summary.presentCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Attendance Rate',
                  '${summary.attendanceRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  summary.attendanceRate >= 80 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatItem(
                  'Punctuality',
                  '${summary.punctualityRate.toStringAsFixed(1)}%',
                  Icons.schedule,
                  summary.punctualityRate >= 80 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),

          // Additional Stats
          if (summary.absentCount > 0 ||
              summary.lateCount > 0 ||
              summary.noShowCount > 0) ...[
            SizedBox(height: 16.h),
            _buildAdditionalStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (summary.absentCount > 0)
                _buildMiniStat('Absent', summary.absentCount, Colors.red),
              if (summary.lateCount > 0)
                _buildMiniStat('Late', summary.lateCount, Colors.orange),
              if (summary.noShowCount > 0)
                _buildMiniStat('No Show', summary.noShowCount, Colors.red),
              if (summary.cancelledCount > 0)
                _buildMiniStat(
                  'Cancelled',
                  summary.cancelledCount,
                  Colors.grey,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
