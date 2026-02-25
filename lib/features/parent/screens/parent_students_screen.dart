import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/parent_student_service.dart';

class ParentStudentsScreen extends ConsumerStatefulWidget {
  const ParentStudentsScreen({super.key});

  @override
  ConsumerState<ParentStudentsScreen> createState() =>
      _ParentStudentsScreenState();
}

class _ParentStudentsScreenState extends ConsumerState<ParentStudentsScreen> {
  bool _isDebugMode = false;
  bool _isLoadingDebug = false;
  String? _debugError;
  List<Student> _debugStudents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStudents();
    });
  }

  void _initializeStudents() {
    try {
      // Check if parent is authenticated
      final authState = ref.read(parentAuthProvider);
      final parentState = ref.read(parentProvider);

      print('🔍 Students screen - Current state:');
      print('  - isAuthenticated: ${authState.isAuthenticated}');
      print('  - parent: ${authState.parent != null}');
      print('  - isLoading: ${parentState.isLoading}');
      print('  - students count: ${parentState.students.length}');
      print('  - error: ${parentState.error}');

      if (authState.isAuthenticated &&
          parentState.students.isEmpty &&
          !parentState.isLoading) {
        print('📱 Loading students from students screen...');
        ref.read(parentProvider.notifier).refreshStudents();
      } else if (!authState.isAuthenticated) {
        print('⚠️ Parent not authenticated, cannot load students');
      } else if (parentState.isLoading) {
        print('⏳ Students are already loading...');
      } else if (parentState.students.isNotEmpty) {
        print('✅ Students already loaded: ${parentState.students.length}');
      }
    } catch (e) {
      print('❌ Error in _initializeStudents: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadDebugStudents() async {
    setState(() {
      _isLoadingDebug = true;
      _debugError = null;
    });

    try {
      print('🔍 DEBUG: Loading students from API...');
      final response = await ParentStudentService.getParentStudents(limit: 50);

      print('🔍 DEBUG: API Response:');
      print('  - Success: ${response.success}');
      print('  - Error: ${response.error}');
      print('  - Data: ${response.data}');

      if (response.success && response.data != null) {
        setState(() {
          _debugStudents = response.data!;
          _isLoadingDebug = false;
        });
        print('✅ DEBUG: Loaded ${_debugStudents.length} students');
      } else {
        setState(() {
          _debugError = response.error ?? 'Unknown error';
          _isLoadingDebug = false;
        });
        print('❌ DEBUG: Failed to load students: $_debugError');
      }
    } catch (e) {
      setState(() {
        _debugError = 'Exception: $e';
        _isLoadingDebug = false;
      });
      print('❌ DEBUG: Exception loading students: $e');
    }
  }

  void _toggleDebugMode() {
    setState(() {
      _isDebugMode = !_isDebugMode;
      if (_isDebugMode && _debugStudents.isEmpty && !_isLoadingDebug) {
        _loadDebugStudents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final parentState = ref.watch(parentProvider);
      final authState = ref.watch(parentAuthProvider);

      print('🏗️ Building ParentStudentsScreen:');
      print('  - Auth: ${authState.isAuthenticated}');
      print('  - Loading: ${parentState.isLoading}');
      print('  - Students: ${parentState.students.length}');
      print('  - Error: ${parentState.error}');

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isDebugMode)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: FloatingActionButton(
                  heroTag: 'debug',
                  mini: true,
                  onPressed: _toggleDebugMode,
                  backgroundColor: Colors.grey[700],
                  child: const Icon(Icons.close),
                  tooltip: 'Exit Debug Mode',
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: FloatingActionButton(
                  heroTag: 'debug',
                  mini: true,
                  onPressed: _toggleDebugMode,
                  backgroundColor: Colors.grey[600],
                  child: const Icon(Icons.bug_report),
                  tooltip: 'Debug Students',
                ),
              ),
            FloatingActionButton.extended(
              heroTag: 'addChild',
              onPressed: () => context.push('/parent/request-student-link'),
              backgroundColor: const Color(0xFF0052CC),
              icon: const Icon(Icons.person_add),
              label: const Text('Add child'),
              tooltip: 'Request to link to a student',
            ),
          ],
        ),
        body: _isDebugMode
            ? _buildDebugBody()
            : !authState.isAuthenticated
            ? _buildNotAuthenticatedState(context)
            : parentState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : parentState.error != null
            ? _buildErrorState(context, parentState.error!)
            : parentState.students.isEmpty
            ? _buildEmptyState(context)
            : _buildStudentsList(context, ref, parentState),
      );
    } catch (e) {
      print('❌ Error building ParentStudentsScreen: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(40.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80.w, color: Colors.red[400]),
                SizedBox(height: 24.h),
                Text(
                  'Error Loading Students',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'An unexpected error occurred: $e',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    // Try to reload the screen
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNotAuthenticatedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80.w, color: Colors.grey[400]),
            SizedBox(height: 24.h),
            Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Please log in to view your students.',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.w, color: Colors.red[400]),
            SizedBox(height: 24.h),
            Text(
              'Error Loading Students',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              error,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                ref.read(parentProvider.notifier).refreshStudents();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60.w),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 60.w,
                color: const Color(0xFF0052CC),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Students Found',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0052CC),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'You don\'t have any students registered yet. Contact your school administrator to add students to your account.',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            FilledButton.icon(
              onPressed: () => context.push('/parent/request-student-link'),
              icon: const Icon(Icons.person_add),
              label: const Text('Request to link to a student'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                textStyle: TextStyle(fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF0052CC).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF0052CC),
                    size: 24.w,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'What you can do:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0052CC),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• Request to link to a student from your school\n• Contact school administration\n• Verify your account details\n• Refresh to try again',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(BuildContext context, WidgetRef ref, parentState) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(parentProvider.notifier).refreshStudents();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: parentState.students.length,
        itemBuilder: (context, index) {
          final student = parentState.students[index];
          return _buildStudentItem(context, ref, student);
        },
      ),
    );
  }

  Widget _buildStudentItem(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    final hasCurrentTrip = student.currentTrip != null;
    final tripStatus = student.currentTrip?.status ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _handleStudentTap(context, ref, student),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Header with Enhanced Design
                Row(
                  children: [
                    // Enhanced Student Avatar with Gradient
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0052CC),
                            const Color(0xFF0066FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0052CC).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 28.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16.w),

                    // Enhanced Student Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0052CC,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  'Grade ${student.grade}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0052CC),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  student.schoolName,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Enhanced Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(student.status),
                            _getStatusColor(student.status).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(
                              student.status,
                            ).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        student.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Enhanced Route Information
                if (student.hasRouteAssignment) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0052CC).withOpacity(0.08),
                          const Color(0xFF0066FF).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFF0052CC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052CC).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.route_rounded,
                                size: 18.w,
                                color: const Color(0xFF0052CC),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Route: ${student.routeName ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0052CC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (student.assignedDriverName != null) ...[
                          SizedBox(height: 12.h),
                          _buildInfoRow(
                            Icons.person_rounded,
                            'Driver',
                            student.assignedDriverName!,
                            Colors.grey[700]!,
                          ),
                        ],
                        if (student.assignedVehicleLicense != null) ...[
                          SizedBox(height: 8.h),
                          _buildInfoRow(
                            Icons.directions_bus_rounded,
                            'Vehicle',
                            student.assignedVehicleLicense!,
                            Colors.grey[700]!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Enhanced Current Trip Status
                if (hasCurrentTrip) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getTripStatusColor(tripStatus).withOpacity(0.1),
                          _getTripStatusColor(tripStatus).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: _getTripStatusColor(tripStatus).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: _getTripStatusColor(
                              tripStatus,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            size: 18.w,
                            color: _getTripStatusColor(tripStatus),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Trip',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                tripStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _getTripStatusColor(tripStatus),
                                ),
                              ),
                              if (student
                                  .currentTrip!
                                  .driverName
                                  .isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  'Driver: ${student.currentTrip!.driverName}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Enhanced Pickup Information
                if (student.pickupStopName != null ||
                    student.pickupStopAddress != null) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.green[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18.w,
                          color: Colors.green[600],
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Pickup: ${student.pickupStopName ?? student.pickupStopAddress ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // Enhanced Contact Information
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      _buildContactIcon(Icons.phone_rounded, Colors.blue[600]!),
                      SizedBox(width: 8.w),
                      Text(
                        student.phoneNumber,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 20.w),
                      _buildContactIcon(
                        Icons.email_rounded,
                        Colors.orange[600]!,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          student.email,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: color),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContactIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, size: 16.w, color: color),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTripStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleStudentTap(BuildContext context, WidgetRef ref, Student student) {
    // Navigate to student details screen
    context.go('/students/${student.id}');
  }

  // Debug mode methods
  Widget _buildDebugBody() {
    if (_isLoadingDebug) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_debugError != null) {
      return _buildDebugErrorState();
    }

    if (_debugStudents.isEmpty) {
      return _buildDebugEmptyState();
    }

    return _buildDebugStudentsList();
  }

  Widget _buildDebugErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.w, color: Colors.red[400]),
            SizedBox(height: 24.h),
            Text(
              'Error Loading Students',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _debugError!,
              style: TextStyle(fontSize: 16.sp, color: Colors.red[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadDebugStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80.w, color: Colors.grey[400]),
            SizedBox(height: 24.h),
            Text(
              'No Students Found',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'No students were returned from the API.',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugStudentsList() {
    return RefreshIndicator(
      onRefresh: _loadDebugStudents,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _debugStudents.length,
        itemBuilder: (context, index) {
          final student = _debugStudents[index];
          return _buildDebugStudentCard(student);
        },
      ),
    );
  }

  Widget _buildDebugStudentCard(Student student) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.blue[600],
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'ID: ${student.studentId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    student.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(student.status),
                    ),
                  ),
                ),
              ],
            ),
            if (student.hasRouteAssignment) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Information',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0052CC),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Route: ${student.routeName ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Driver: ${student.assignedDriverName ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Vehicle: ${student.assignedVehicleLicense ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (student.parents.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent Relationships (${student.parents.length})',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...student.parents.map(
                      (parent) => Text(
                        'Parent ${parent.id}: ${parent.parentName} (${parent.isPrimaryContact ? 'Primary' : 'Secondary'})',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
