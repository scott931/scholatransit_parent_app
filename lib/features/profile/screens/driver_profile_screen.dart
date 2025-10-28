import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/models/driver_model.dart';
import '../../../core/theme/app_theme.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically load profile data when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      // Only load if we're authenticated but don't have driver data yet
      if (authState.isAuthenticated &&
          authState.driver == null &&
          !authState.isLoading) {
        ref.read(authProvider.notifier).loadDriverProfile();
      }
      // Load active trips for stats
      ref.read(tripProvider.notifier).loadActiveTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driver = authState.driver;

    // Listen for authentication state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      // If user is no longer authenticated, navigate to login
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        if (mounted) {
          context.go('/login');
        }
      }
    });

    if (authState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await ref.read(authProvider.notifier).loadDriverProfile();
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                authState.error != null
                    ? Icons.error_outline
                    : Icons.person_off,
                size: 64,
                color: authState.error != null ? Colors.red : Colors.grey,
              ),
              SizedBox(height: 16.h),
              Text(
                authState.error != null
                    ? 'Error loading profile'
                    : 'No profile data available',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: authState.error != null ? Colors.red : Colors.grey,
                ),
              ),
              if (authState.error != null) ...[
                SizedBox(height: 8.h),
                Text(
                  authState.error!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).loadDriverProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(authProvider.notifier).loadDriverProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Header
            _ProfileHeader(driver: driver),

            SizedBox(height: 24.h),

            // Stats Section
            _buildStatsSection(),

            SizedBox(height: 24.h),

            // Profile Information
            _buildInfoSection(
              title: 'Personal Information',
              children: [
                _buildInfoField(label: 'First Name', value: driver.firstName),
                _buildInfoField(label: 'Last Name', value: driver.lastName),
                _buildInfoField(label: 'Email', value: driver.email),
                _buildInfoField(label: 'Phone', value: driver.phone),
                _buildInfoField(
                  label: 'Address',
                  value: driver.address ?? 'Not provided',
                  maxLines: 2,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Professional Information
            _buildInfoSection(
              title: 'Professional Information',
              children: [
                _buildInfoField(
                  label: 'License Number',
                  value: driver.licenseNumber,
                ),
                _buildInfoField(
                  label: 'Date of Birth',
                  value:
                      driver.dateOfBirth?.toString().split(' ')[0] ??
                      'Not provided',
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Emergency Contact
            _buildInfoSection(
              title: 'Emergency Contact',
              children: [
                _buildInfoField(
                  label: 'Contact Name',
                  value: driver.emergencyContact ?? 'Not provided',
                ),
                _buildInfoField(
                  label: 'Contact Phone',
                  value: driver.emergencyPhone ?? 'Not provided',
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Action Buttons
            _buildActionButton(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () => _showLogoutDialog(),
              isDestructive: true,
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final activeTrips = ref.watch(activeTripsProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Text(
            'Driver Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.directions_bus,
                  label: 'Active Trips',
                  value: activeTrips.length.toString(),
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Status',
                  value: 'Active',
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: value.isEmpty
                    ? AppTheme.textTertiary
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? AppTheme.errorColor
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Perform logout
                await ref.read(authProvider.notifier).logout();

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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Driver driver;

  const _ProfileHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50.r,
            backgroundColor: Colors.white,
            child: driver.profileImage != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driver.profileImage!,
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100.w,
                        height: 100.h,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        size: 50.w,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : Icon(Icons.person, size: 50.w, color: AppTheme.primaryColor),
          ),
          SizedBox(height: 16.h),

          // Driver Name
          Text(
            driver.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),

          // Driver ID
          Text(
            'Driver ID: ${driver.id}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8.h),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getStatusColor(driver.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _getStatusColor(driver.status),
                width: 1,
              ),
            ),
            child: Text(
              driver.status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(driver.status),
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'inactive':
        return AppTheme.errorColor;
      case 'on_leave':
        return AppTheme.warningColor;
      default:
        return AppTheme.textTertiary;
    }
  }
}
