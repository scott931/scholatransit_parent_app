import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/attendance_history_provider.dart';
import '../../../core/providers/trip_logs_provider.dart';
import '../../../core/models/trip_log_model.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceHistoryProvider);
    final tripLogsState = ref.watch(tripLogsProvider);

    // Listen for errors
    ref.listen<AttendanceHistoryState>(attendanceHistoryProvider, (
      previous,
      next,
    ) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    });

    // Listen for trip logs errors
    ref.listen<TripLogsState>(tripLogsProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(attendanceState, tripLogsState),

              SizedBox(height: 16.h),

              // Trip Logs Content
              Expanded(child: _buildTripLogsTab(tripLogsState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(
    AttendanceHistoryState attendanceState,
    TripLogsState tripLogsState,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 5.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean stats cards
          Row(
            children: [
              Expanded(
                child: _buildSimpleStatusCard(
                  icon: Icons.directions_bus_rounded,
                  label: 'Total Trips',
                  value: tripLogsState.tripLogs.length.toString(),
                  color: const Color(0xFF3B82F6),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showThisMonthDates(tripLogsState.tripLogs),
                  child: _buildSimpleStatusCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'This Month',
                    value: _getThisMonthTripCount(
                      tripLogsState.tripLogs,
                    ).toString(),
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 20.w),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  int _getThisMonthTripCount(List<TripLog> tripLogs) {
    final now = DateTime.now();
    return tripLogs.where((tripLog) {
      return tripLog.scheduledStart.year == now.year &&
          tripLog.scheduledStart.month == now.month;
    }).length;
  }

  void _showThisMonthDates(List<TripLog> tripLogs) {
    final now = DateTime.now();
    final thisMonthTrips = tripLogs.where((tripLog) {
      return tripLog.scheduledStart.year == now.year &&
          tripLog.scheduledStart.month == now.month;
    }).toList();

    // Sort by date
    thisMonthTrips.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: const Color(0xFF10B981),
              size: 24.w,
            ),
            SizedBox(width: 12.w),
            Text(
              'This Month Trips',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400.h),
          child: thisMonthTrips.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48.w,
                      color: const Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No trips this month',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: thisMonthTrips.length,
                  itemBuilder: (context, index) {
                    final trip = thisMonthTrips[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: _getTripLogStatusColor(
                                trip.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              Icons.directions_bus_rounded,
                              size: 16.w,
                              color: _getTripLogStatusColor(trip.status),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(trip.scheduledStart),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${trip.routeName} - ${trip.vehicleName}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getTripLogStatusColor(
                                trip.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              trip.status.displayName,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: _getTripLogStatusColor(trip.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripLogsTab(TripLogsState tripLogsState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Logs Header
          Row(
            children: [
              Text(
                'Trip Logs',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              if (tripLogsState.isLoading)
                SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF3B82F6),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      ref.read(tripLogsProvider.notifier).refreshTripLogs();
                    },
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: const Color(0xFF6B7280),
                      size: 20.w,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),

          // Trip Logs List
          if (tripLogsState.tripLogs.isEmpty && !tripLogsState.isLoading)
            _buildTripLogsEmptyState()
          else
            _buildTripLogsList(tripLogsState),

          SizedBox(height: 100.h), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildTripLogsEmptyState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 48.w,
            color: const Color(0xFF9CA3AF),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Trip Logs Found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Trip logs will appear here when you start driving routes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripLogsList(TripLogsState tripLogsState) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tripLogsState.tripLogs.length,
      itemBuilder: (context, index) {
        final tripLog = tripLogsState.tripLogs[index];
        return _buildTripLogCard(tripLog);
      },
    );
  }

  Widget _buildTripLogCard(TripLog tripLog) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTripLogDetails(tripLog),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getTripLogStatusColor(
                        tripLog.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      tripLog.status.displayName,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _getTripLogStatusColor(tripLog.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(tripLog.scheduledStart),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Trip Info
              Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 16.w,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${tripLog.routeName} - ${tripLog.vehicleName}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // Driver Info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16.w,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    tripLog.driverName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // Duration and Distance
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16.w,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${_calculateDuration(tripLog)} min',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.straighten,
                    size: 16.w,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${(tripLog.totalDistance ?? 0.0).toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTripLogStatusColor(TripLogStatus status) {
    switch (status) {
      case TripLogStatus.completed:
        return const Color(0xFF10B981);
      case TripLogStatus.inProgress:
        return const Color(0xFF3B82F6);
      case TripLogStatus.scheduled:
        return const Color(0xFF8B5CF6);
      case TripLogStatus.cancelled:
        return const Color(0xFFEF4444);
      case TripLogStatus.delayed:
        return const Color(0xFFF59E0B);
    }
  }

  void _showTripLogDetails(TripLog tripLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trip Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Trip ID', tripLog.tripId),
              _buildDetailRow('Status', tripLog.status.displayName),
              _buildDetailRow('Route', tripLog.routeName),
              _buildDetailRow('Vehicle', tripLog.vehicleName),
              _buildDetailRow('Driver', tripLog.driverName),
              _buildDetailRow(
                'Start Time',
                _formatDateTime(tripLog.scheduledStart),
              ),
              _buildDetailRow(
                'End Time',
                _formatDateTime(tripLog.scheduledEnd),
              ),
              _buildDetailRow(
                'Duration',
                '${_calculateDuration(tripLog)} minutes',
              ),
              _buildDetailRow(
                'Distance',
                '${(tripLog.totalDistance ?? 0.0).toStringAsFixed(2)} km',
              ),
              _buildDetailRow('Start Location', tripLog.startLocation ?? 'N/A'),
              _buildDetailRow('End Location', tripLog.endLocation ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  int _calculateDuration(TripLog tripLog) {
    if (tripLog.actualStart != null && tripLog.actualEnd != null) {
      return tripLog.actualEnd!.difference(tripLog.actualStart!).inMinutes;
    } else {
      return tripLog.scheduledEnd.difference(tripLog.scheduledStart).inMinutes;
    }
  }
}
