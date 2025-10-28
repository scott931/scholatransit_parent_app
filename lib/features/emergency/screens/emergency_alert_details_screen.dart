import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_endpoints.dart';

class EmergencyAlertDetailsScreen extends ConsumerStatefulWidget {
  final int alertId;

  const EmergencyAlertDetailsScreen({super.key, required this.alertId});

  @override
  ConsumerState<EmergencyAlertDetailsScreen> createState() =>
      _EmergencyAlertDetailsScreenState();
}

class _EmergencyAlertDetailsScreenState
    extends ConsumerState<EmergencyAlertDetailsScreen> {
  Map<String, dynamic>? alertData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadEmergencyAlertDetails();
  }

  Future<void> _loadEmergencyAlertDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.emergencyAlertDetails(widget.alertId),
      );

      if (response.success) {
        setState(() {
          alertData = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = response.error ?? 'Failed to load emergency alert details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading emergency alert: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Custom AppBar with reduced height
            Container(
              height: 45.h,
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20.w,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/parent/notifications');
                      }
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                      size: 20.w,
                    ),
                    onPressed: _loadEmergencyAlertDetails,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Colors.grey[600],
                      size: 20.w,
                    ),
                    onPressed: () {
                      _shareEmergencyAlert();
                    },
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : error != null
                  ? _buildErrorState()
                  : _buildAlertDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red[600], strokeWidth: 3),
          SizedBox(height: 16.h),
          Text(
            'Loading emergency alert details...',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48.w,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Alert',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error!,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _loadEmergencyAlertDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertDetails() {
    if (alertData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(),
          SizedBox(height: 20.h),

          // Status and Severity Cards
          _buildStatusCards(),
          SizedBox(height: 20.h),

          // Description Card
          _buildDescriptionCard(),
          SizedBox(height: 20.h),

          // Vehicle Information
          if (alertData!['vehicle'] != null) ...[
            _buildVehicleCard(),
            SizedBox(height: 20.h),
          ],

          // Route Information
          if (alertData!['route'] != null) ...[
            _buildRouteCard(),
            SizedBox(height: 20.h),
          ],

          // Students Affected
          if (alertData!['students'] != null &&
              (alertData!['students'] as List).isNotEmpty) ...[
            _buildStudentsCard(),
            SizedBox(height: 20.h),
          ],

          // Location Information
          if (alertData!['location_display'] != null) ...[
            _buildLocationCard(),
            SizedBox(height: 20.h),
          ],

          // Updates/Progress
          if (alertData!['updates'] != null &&
              (alertData!['updates'] as List).isNotEmpty) ...[
            _buildUpdatesCard(),
            SizedBox(height: 20.h),
          ],

          // Metadata
          if (alertData!['metadata'] != null) ...[
            _buildMetadataCard(),
            SizedBox(height: 20.h),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final title = alertData!['title'] ?? 'Emergency Alert';
    final emergencyType = alertData!['emergency_type_display'] ?? 'Emergency';
    final reportedAt = alertData!['reported_at'] ?? '';
    final reportedBy = alertData!['reported_by']?['full_name'] ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      emergencyType,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.person, size: 16.w, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                'Reported by: $reportedBy',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                'Reported: ${_formatDateTime(reportedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    final status = alertData!['status_display'] ?? 'Unknown';
    final severity = alertData!['severity_display'] ?? 'Unknown';
    final affectedCount = alertData!['affected_students_count'] ?? 0;
    final estimatedDelay = alertData!['estimated_delay_minutes'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Status',
                status,
                _getStatusColor(status),
                Icons.info_rounded,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatusCard(
                'Severity',
                severity,
                _getSeverityColor(severity),
                Icons.priority_high_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Students Affected',
                '$affectedCount',
                Colors.orange[600]!,
                Icons.people_rounded,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatusCard(
                'Estimated Delay',
                '${estimatedDelay}min',
                Colors.blue[600]!,
                Icons.schedule_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final description = alertData!['description'] ?? 'No description available';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: Colors.grey[600],
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    final vehicle = alertData!['vehicle'] as Map<String, dynamic>;
    final licensePlate = vehicle['license_plate'] ?? 'Unknown';
    final make = vehicle['make'] ?? '';
    final model = vehicle['model'] ?? '';
    final year = vehicle['year'] ?? '';
    final status = vehicle['status_display'] ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                color: Colors.blue[600],
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Vehicle Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('License Plate', licensePlate),
          _buildInfoRow('Vehicle', '$make $model $year'),
          _buildInfoRow('Status', status),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    final route = alertData!['route'] as Map<String, dynamic>;
    final name = route['name'] ?? 'Unknown Route';
    final description = route['description'] ?? '';
    final routeType = route['route_type_display'] ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(Icons.route_rounded, color: Colors.green[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Route Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Route Name', name),
          if (description.isNotEmpty) _buildInfoRow('Description', description),
          _buildInfoRow('Type', routeType),
        ],
      ),
    );
  }

  Widget _buildStudentsCard() {
    final students = alertData!['students'] as List<dynamic>;
    final affectedCount = students.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern header with badge
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$affectedCount',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.people_rounded, color: Colors.orange[600], size: 18.w),
              SizedBox(width: 6.w),
              Text(
                'Affected Students',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Compact student list
          ...students.take(5).map((student) {
            final studentData = student as Map<String, dynamic>;
            final name = studentData['full_name'] ?? 'Unknown Student';
            final studentId = studentData['student_id'] ?? '';
            final grade = studentData['grade'] ?? '';

            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey[200]!, width: 0.5),
              ),
              child: Row(
                children: [
                  // Modern avatar with gradient
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (studentId.isNotEmpty || grade.isNotEmpty)
                          Row(
                            children: [
                              if (studentId.isNotEmpty) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'ID: $studentId',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (grade.isNotEmpty) SizedBox(width: 6.w),
                              ],
                              if (grade.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'Grade $grade',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Colors.orange[400],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Modern "more students" indicator
          if (students.length > 5)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.more_horiz, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Text(
                    '${students.length - 5} more students',
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = alertData!['location_display'] ?? '';
    final address = alertData!['address'] ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.purple[600],
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Location Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (location.isNotEmpty) _buildInfoRow('Coordinates', location),
          if (address.isNotEmpty) _buildInfoRow('Address', address),
        ],
      ),
    );
  }

  Widget _buildUpdatesCard() {
    final updates = alertData!['updates'] as List<dynamic>;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(Icons.update_rounded, color: Colors.blue[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Updates & Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...updates.map((update) {
            final updateData = update as Map<String, dynamic>;
            final message = updateData['message'] ?? '';
            final updatedBy =
                updateData['updated_by']?['full_name'] ?? 'Unknown';
            final createdAt = updateData['created_at'] ?? '';

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.person, size: 12.w, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Text(
                        'By: $updatedBy',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Icon(
                        Icons.access_time,
                        size: 12.w,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatDateTime(createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    final metadata = alertData!['metadata'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.grey[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Additional Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...metadata.entries.map((entry) {
            return _buildInfoRow(
              entry.key.replaceAll('_', ' ').toUpperCase(),
              entry.value.toString(),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return Colors.orange[600]!;
      case 'resolved':
        return Colors.green[600]!;
      case 'pending':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'high':
        return Colors.red[600]!;
      case 'critical':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'Unknown';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  void _shareEmergencyAlert() {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emergency alert sharing not implemented yet'),
        backgroundColor: Colors.orange[600],
      ),
    );
  }
}
