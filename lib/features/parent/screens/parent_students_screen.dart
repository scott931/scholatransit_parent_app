import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/parent_student_service.dart';
import '../../../core/theme/app_theme.dart';

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
        backgroundColor: AppTheme.backgroundColor,
        body: _isDebugMode
            ? _buildDebugBody()
            : !authState.isAuthenticated
                ? _buildNotAuthenticatedState(context)
                : parentState.isLoading
                    ? _buildLoadingState()
                    : parentState.error != null
                        ? _buildErrorState(context, parentState.error!)
                        : parentState.students.isEmpty
                            ? _buildEmptyStateWithHeader(context)
                            : _buildModernStudentsView(context, ref, parentState),
        floatingActionButton: _isDebugMode
            ? null
            : authState.isAuthenticated
                ? FloatingActionButton.extended(
                    heroTag: 'addChild',
                    onPressed: () => context.push('/parent/request-student-link'),
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 4,
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(
                      'Link student',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
      );
    } catch (e) {
      print('❌ Error building ParentStudentsScreen: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
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
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 48.w,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Sign in to continue',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please log in to view your linked students.',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: AppTheme.textPrimary.withOpacity(0.6),
                height: 1.4,
              ),
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
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48.w,
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: AppTheme.textPrimary.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(parentProvider.notifier).refreshStudents(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithHeader(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(32.w, 24.h, 32.w, 100.h),
          sliver: SliverToBoxAdapter(
            child: _buildEmptyStateContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          SizedBox(height: 40.h),
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.primaryLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(32.r),
            ),
            child: Icon(
              Icons.school_rounded,
              size: 56.w,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            'No students yet',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Link to a student from your school to see them here. Request access and wait for school approval.',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              color: AppTheme.textPrimary.withOpacity(0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          FilledButton.icon(
            onPressed: () => context.push('/parent/request-student-link'),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Request to link student'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Request to link • School approves • Student appears here',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: AppTheme.textPrimary.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildShimmerCard(),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 14.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStudentsView(
    BuildContext context,
    WidgetRef ref,
    dynamic parentState,
  ) {
    final students = parentState.students as List<Student>;
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(parentProvider.notifier).refreshStudents();
      },
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 100.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildModernStudentCard(
                  context,
                  ref,
                  students[index],
                ),
                childCount: students.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStudentCard(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) {
    final initial = student.firstName.isNotEmpty
        ? student.firstName[0].toUpperCase()
        : '?';
    final hasCurrentTrip = student.currentTrip != null;
    final tripStatus = student.currentTrip?.status ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => _handleStudentTap(context, ref, student),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              if (student.grade.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'Grade ${student.grade}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              if (student.grade.isNotEmpty && student.schoolName.isNotEmpty)
                                SizedBox(width: 8.w),
                              if (student.schoolName.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    student.schoolName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: AppTheme.textPrimary.withOpacity(0.6),
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(student.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        student.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(student.status),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.w,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                if (hasCurrentTrip) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: _getTripStatusColor(tripStatus).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: _getTripStatusColor(tripStatus).withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: 20.w,
                          color: _getTripStatusColor(tripStatus),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'On trip',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: AppTheme.textPrimary.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                tripStatus.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _getTripStatusColor(tripStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (student.hasRouteAssignment && student.routeName != null) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        size: 16.w,
                        color: AppTheme.primaryColor.withOpacity(0.8),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        student.routeName!,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
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
