import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/attendance_history_model.dart';

class AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback? onTap;

  const AttendanceRecordCard({super.key, required this.record, this.onTap});

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
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Status Icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: record.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    record.status.icon,
                    color: record.status.color,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),

                // Student Name and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatDate(record.tripDate),
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: record.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: record.status.color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    record.status.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: record.status.color,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Route and Driver Info
            Row(
              children: [
                _buildInfoItem(Icons.route, record.routeName, Colors.blue),
                SizedBox(width: 16.w),
                _buildInfoItem(Icons.person, record.driverName, Colors.green),
              ],
            ),

            SizedBox(height: 8.h),

            // Time Information
            Row(
              children: [
                _buildTimeInfo(
                  'Scheduled',
                  _formatTime(record.scheduledPickupTime),
                  Colors.grey[600]!,
                ),
                if (record.actualPickupTime != null) ...[
                  SizedBox(width: 16.w),
                  _buildTimeInfo(
                    'Actual',
                    _formatTime(record.actualPickupTime!),
                    record.isOnTime ? Colors.green : Colors.orange,
                  ),
                ],
              ],
            ),

            // Delay Information
            if (record.delayDuration != null && !record.isOnTime) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: record.isLate
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      record.isLate ? Icons.schedule : Icons.schedule,
                      size: 14.w,
                      color: record.isLate ? Colors.orange : Colors.blue,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      record.delayDisplayText,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: record.isLate ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Notes
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  record.notes!,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.w, color: color),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey[500]),
        ),
        SizedBox(height: 2.h),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return 'Today';
    } else if (recordDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
