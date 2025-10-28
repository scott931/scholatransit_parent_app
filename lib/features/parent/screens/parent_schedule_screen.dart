import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/models/parent_trip_model.dart';

class ParentScheduleScreen extends ConsumerStatefulWidget {
  const ParentScheduleScreen({super.key});

  @override
  ConsumerState<ParentScheduleScreen> createState() =>
      _ParentScheduleScreenState();
}

class _ParentScheduleScreenState extends ConsumerState<ParentScheduleScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get only scheduled trips from activeTrips
  List<ParentTrip> _getScheduledTrips(List<ParentTrip> activeTrips) {
    return activeTrips.where((trip) => trip.isScheduled).toList();
  }

  // Get today's scheduled trips
  int _getTodayScheduledCount(List<ParentTrip> scheduledTrips) {
    final today = DateTime.now();
    return scheduledTrips.where((trip) {
      final tripDate = trip.scheduledStartTime;
      return tripDate.year == today.year &&
          tripDate.month == today.month &&
          tripDate.day == today.day;
    }).length;
  }

  // Get upcoming scheduled trips (after today)
  int _getUpcomingScheduledCount(List<ParentTrip> scheduledTrips) {
    final today = DateTime.now();
    return scheduledTrips.where((trip) {
      final tripDate = trip.scheduledStartTime;
      return tripDate.isAfter(today);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(parentState),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),

                    // Search and Filter Section
                    _buildSearchAndFilterSection(),

                    SizedBox(height: 24.h),

                    // Schedule Content
                    _buildScheduleContent(context, ref, parentState),

                    SizedBox(height: 100.h), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(parentState) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selection
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: _showDatePicker,
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    color: const Color(0xFF6B7280),
                    size: 20.w,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Stats Row
          Builder(
            builder: (context) {
              final scheduledTrips = _getScheduledTrips(
                parentState.activeTrips,
              );
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Scheduled',
                      scheduledTrips.length.toString(),
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      'Today',
                      _getTodayScheduledCount(scheduledTrips).toString(),
                      const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      'Upcoming',
                      _getUpcomingScheduledCount(scheduledTrips).toString(),
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),
        SizedBox(height: 16.h),
        // Filter Chips
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search scheduled trips...',
          hintStyle: TextStyle(
            color: const Color(0xFF9CA3AF),
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_outlined,
            color: const Color(0xFF9CA3AF),
            size: 20.w,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 18.w,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'today', 'label': 'Today'},
      {'key': 'tomorrow', 'label': 'Tomorrow'},
      {'key': 'this_week', 'label': 'This Week'},
      {'key': 'next_week', 'label': 'Next Week'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter['label'] as String,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleContent(
    BuildContext context,
    WidgetRef ref,
    parentState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with refresh button
        Row(
          children: [
            Text(
              'Scheduled Trips',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            if (parentState.isLoading)
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF3B82F6),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  ref.read(parentProvider.notifier).refreshData();
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.refresh_outlined,
                    color: const Color(0xFF6B7280),
                    size: 16.w,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),

        // Content
        Builder(
          builder: (context) {
            final scheduledTrips = _getScheduledTrips(parentState.activeTrips);
            if (parentState.isLoading)
              return _buildLoadingState();
            else if (scheduledTrips.isEmpty)
              return _buildEmptyState(context);
            else
              return Column(
                children: _getFilteredTrips(
                  scheduledTrips,
                ).map((trip) => _buildModernTripCard(context, trip)).toList(),
              );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Loading scheduled trips...',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: const Color(0xFF9CA3AF),
            size: 40.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'No scheduled trips',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'No scheduled trips found for the selected date.',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTripCard(BuildContext context, trip) {
    final statusColor = _getStatusColor(trip.status);
    final isLive = trip.status == 'in_progress';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isLive
              ? statusColor.withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _showTripDetails(context, trip),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.tripName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Route ${trip.routeName ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF6B7280),
                            ),
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
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        trip.status.displayName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Info row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time_outlined,
                        'Time',
                        _formatTime(trip.scheduledStartTime),
                        const Color(0xFF6B7280),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.person_outline,
                        'Driver',
                        trip.driverName,
                        const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                // Additional info
                if (trip.actualStartTime != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        size: 14.w,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Started at ${_formatTime(trip.actualStartTime!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (trip.estimatedArrivalMinutes != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: const Color(0xFFF59E0B),
                        size: 14.w,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'ETA: ${trip.estimatedArrivalMinutes} min',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14.w),
        SizedBox(width: 6.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<ParentTrip> _getFilteredTrips(List<ParentTrip> trips) {
    List<ParentTrip> filteredTrips = trips;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTrips = trips.where((trip) {
        return trip.tripName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            trip.routeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            trip.driverName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply date filter
    if (_selectedFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filteredTrips = filteredTrips.where((trip) {
        final tripDate = trip.scheduledStartTime;
        final tripDay = DateTime(tripDate.year, tripDate.month, tripDate.day);

        switch (_selectedFilter) {
          case 'today':
            return tripDay.isAtSameMomentAs(today);
          case 'tomorrow':
            final tomorrow = today.add(const Duration(days: 1));
            return tripDay.isAtSameMomentAs(tomorrow);
          case 'this_week':
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            return tripDay.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                tripDay.isBefore(weekEnd.add(const Duration(days: 1)));
          case 'next_week':
            final nextWeekStart = today.add(Duration(days: 8 - today.weekday));
            final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
            return tripDay.isAfter(
                  nextWeekStart.subtract(const Duration(days: 1)),
                ) &&
                tripDay.isBefore(nextWeekEnd.add(const Duration(days: 1)));
          default:
            return true;
        }
      }).toList();
    }

    return filteredTrips;
  }

  Color _getStatusColor(status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF3B82F6);
      case 'in_progress':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFFF6B6B);
      case 'delayed':
        return const Color(0xFFFFB347);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _showTripDetails(BuildContext context, trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'Trip Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Trip Name', trip.tripName),
              _buildDetailRow('Route', trip.routeName ?? 'N/A'),
              _buildDetailRow('Driver', trip.driverName),
              _buildDetailRow('Status', trip.status.displayName),
              _buildDetailRow(
                'Scheduled Time',
                _formatTime(trip.scheduledStartTime),
              ),
              if (trip.actualStartTime != null)
                _buildDetailRow(
                  'Actual Start',
                  _formatTime(trip.actualStartTime!),
                ),
              if (trip.estimatedArrivalMinutes != null)
                _buildDetailRow(
                  'Estimated Arrival',
                  '${trip.estimatedArrivalMinutes} minutes',
                ),
              if (trip.busNumber != null)
                _buildDetailRow('Bus Number', trip.busNumber!),
              if (trip.busColor != null)
                _buildDetailRow('Bus Color', trip.busColor!),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
