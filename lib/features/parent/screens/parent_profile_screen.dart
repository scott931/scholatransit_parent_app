import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/theme/app_theme.dart';

class ParentProfileScreen extends ConsumerWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentAuthState = ref.watch(parentAuthProvider);
    final parentState = ref.watch(parentProvider);

    // Listen for authentication state changes
    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      // If user is no longer authenticated, navigate to login
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        if (context.mounted) {
          context.go('/login');
        }
      }
    });

    // Load parent data when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (parentAuthState.parent != null && parentState.students.isEmpty) {
        ref.read(parentProvider.notifier).loadParentData();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: parentAuthState.isLoading
          ? _buildLoadingState(context)
          : parentAuthState.parent != null
          ? _buildProfileContent(context, ref, parentAuthState)
          : _buildErrorState(context),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80.w, color: Colors.red[400]),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Profile',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Unable to load your profile information.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    parentAuthState,
  ) {
    final parent = parentAuthState.parent!;

    return CustomScrollView(
      slivers: [
        // Modern App Bar with Profile Header
        SliverAppBar(
          expandedHeight: 280.h,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildModernProfileHeader(context, parent),
          ),
        ),

        // Profile Content
        SliverPadding(
          padding: EdgeInsets.all(20.w),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Refresh Button
              _buildRefreshButton(context, ref),
              SizedBox(height: 16.h),

              // Quick Stats Cards
              _buildQuickStatsCards(context, parent),
              SizedBox(height: 24.h),

              // Personal Information Section
              _buildModernProfileInfo(context, parent),
              SizedBox(height: 24.h),

              // Children Section
              _buildModernChildrenSection(context, parent),
              SizedBox(height: 24.h),

              // Settings Section
              _buildModernSettingsSection(context),
              SizedBox(height: 24.h),

              // Logout Button
              _buildModernLogoutButton(context, ref),
              SizedBox(height: 20.h),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 48.h,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          // Refresh parent profile data
          await ref.read(parentAuthProvider.notifier).refreshParentProfile();
          // Also refresh parent provider data
          await ref.read(parentProvider.notifier).loadParentData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile data refreshed'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20.w),
        label: Text(
          'Refresh Profile Data',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader(BuildContext context, parent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryVariant,
            AppTheme.primaryLight,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Profile Picture with Modern Design
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50.r,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: parent.profileImage != null
                      ? ClipOval(
                          child: Image.network(
                            parent.profileImage!,
                            width: 100.w,
                            height: 100.h,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.person, size: 50.w, color: Colors.white),
                ),
              ),
              SizedBox(height: 16.h),

              // Name with Modern Typography
              Text(
                parent.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),

              // Email with Subtle Styling
              Text(
                parent.email,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Active Parent',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCards(BuildContext context, parent) {
    return Consumer(
      builder: (context, ref, child) {
        final parentState = ref.watch(parentProvider);
        final notificationCount = parentState.unreadCount ?? 0;

        // Use students from parentProvider for consistency
        final students = parentState.students;

        return Row(
          children: [
            Expanded(
              child: _buildChildrenCard(
                context,
                'Children',
                students,
                Icons.child_care,
                AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Active Trips',
                '${parentState.activeTrips.length}',
                Icons.directions_bus,
                AppTheme.successColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Notifications',
                '$notificationCount',
                Icons.notifications,
                AppTheme.warningColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.w),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenCard(
    BuildContext context,
    String title,
    List students,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.w),
          ),
          SizedBox(height: 8.h),
          if (students.isEmpty)
            Text(
              'No Children',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            )
          else if (students.length == 1)
            Text(
              students.first.fullName,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            Column(
              children: [
                Text(
                  '${students.length} Children',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                ...students
                    .take(2)
                    .map(
                      (student) => Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: Text(
                          student.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                if (students.length > 2)
                  Text(
                    '+${students.length - 2} more',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileInfo(BuildContext context, parent) {
    // Debug: Print parent data to see what's available
    print('🔍 DEBUG: Parent data in profile:');
    print('  - Phone: "${parent.phone}" (length: ${parent.phone.length})');
    print('  - Address: "${parent.address}" (null: ${parent.address == null})');
    print(
      '  - Emergency Contact: "${parent.emergencyContact}" (null: ${parent.emergencyContact == null})',
    );
    print(
      '  - Emergency Phone: "${parent.emergencyPhone}" (null: ${parent.emergencyPhone == null})',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),
        // Always show phone, even if empty
        _buildModernInfoItem(
          context,
          'Phone',
          parent.phone.isNotEmpty ? parent.phone : 'Not provided',
          Icons.phone,
        ),
        SizedBox(height: 12.h),
        // Always show address, even if empty
        _buildModernInfoItem(
          context,
          'Address',
          parent.address?.isNotEmpty == true ? parent.address! : 'Not provided',
          Icons.location_on,
        ),
        SizedBox(height: 12.h),
        // Show emergency contact if available
        if (parent.emergencyContact?.isNotEmpty == true) ...[
          _buildModernInfoItem(
            context,
            'Emergency Contact',
            parent.emergencyContact!,
            Icons.emergency,
          ),
          SizedBox(height: 12.h),
        ],
        // Show emergency phone if available
        if (parent.emergencyPhone?.isNotEmpty == true)
          _buildModernInfoItem(
            context,
            'Emergency Phone',
            parent.emergencyPhone!,
            Icons.phone,
          ),
      ],
    );
  }

  Widget _buildModernInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
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
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChildrenSection(BuildContext context, parent) {
    return Consumer(
      builder: (context, ref, child) {
        final parentState = ref.watch(parentProvider);
        final students = parentState.students;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Children',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${students.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (students.isEmpty)
              _buildModernEmptyChildrenState(context)
            else
              ...students.map(
                (student) => _buildModernStudentItem(context, student),
              ),
          ],
        );
      },
    );
  }

  Widget _buildModernEmptyChildrenState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.child_care,
              size: 32.w,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Children Added',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Contact your school to add your children to the system.',
            style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStudentItem(BuildContext context, student) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _getStudentStatusColor(student.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.child_care,
              size: 24.w,
              color: _getStudentStatusColor(student.status),
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
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStudentStatusColor(
                          student.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getStudentStatusDisplayName(student.status),
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStudentStatusColor(student.status),
                        ),
                      ),
                    ),
                  ],
                ),
                if (student.grade != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.school, size: 14.w, color: Colors.black54),
                      SizedBox(width: 4.w),
                      Text(
                        'Grade ${student.grade}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStudentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'suspended':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStudentStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'suspended':
        return 'Suspended';
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      default:
        return status;
    }
  }

  Widget _buildModernSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),
        // _buildModernSettingsItem(
        //   context,
        //   'Notification Settings',
        //   'Manage your notification preferences',
        //   Icons.notifications,
        //   () => _showNotificationSettings(context),
        // ),
        // SizedBox(height: 12.h),
        // _buildModernSettingsItem(
        //   context,
        //   'Privacy Settings',
        //   'Control your privacy and data',
        //   Icons.privacy_tip,
        //   () => _showPrivacySettings(context),
        // ),
        // SizedBox(height: 12.h),
        // _buildModernSettingsItem(
        //   context,
        //   'Help & Support',
        //   'Get help and contact support',
        //   Icons.help,
        //   () => _showHelpSupport(context),
        // ),
        // SizedBox(height: 12.h),
        _buildModernSettingsItem(
          context,
          'About',
          'App version and information',
          Icons.info,
          () => _showAbout(context),
        ),
      ],
    );
  }

  Widget _buildModernSettingsItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.w, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmation(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white, size: 20.w),
            SizedBox(width: 8.w),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _showNotificationSettings(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Notification settings coming soon...')),
  //   );
  // }

  // void _showPrivacySettings(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Privacy settings coming soon...')),
  //   );
  // }

  // void _showHelpSupport(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Help & Support coming soon...')),
  //   );
  // }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Go Drop'),
        content: const Text(
          'Version 1.0.0\n\nGo Drop Parent App for tracking your child\'s bus transportation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Perform logout
                await ref.read(parentAuthProvider.notifier).logout();

                // Close loading dialog
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  // Navigate to login
                  context.go('/login');
                }
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  // Show error and still navigate to login
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  context.go('/login');
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
