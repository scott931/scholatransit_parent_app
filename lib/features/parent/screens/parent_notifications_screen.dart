import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/widgets/notification_item_card.dart';
import 'package:go_router/go_router.dart';

class ParentNotificationsScreen extends ConsumerStatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  ConsumerState<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState
    extends ConsumerState<ParentNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    // Check if parent is authenticated
    final authState = ref.read(parentAuthProvider);
    final parentState = ref.read(parentProvider);

    print('🔍 Notifications screen - Current state:');
    print('  - isAuthenticated: ${authState.isAuthenticated}');
    print('  - parent: ${authState.parent != null}');
    print('  - isLoading: ${parentState.isLoading}');
    print('  - notifications count: ${parentState.notifications.length}');
    print('  - unread count: ${parentState.unreadCount}');

    // Debug: Print all notifications to see what we have
    for (int i = 0; i < parentState.notifications.length; i++) {
      final notification = parentState.notifications[i];
      try {
        print('📱 Notification $i: ${notification.toString()}');
      } catch (e) {
        print('📱 Notification $i: [Error printing notification: $e]');
        print('📱 Notification $i keys: ${notification.keys.toList()}');
      }
    }

    if (authState.isAuthenticated &&
        parentState.notifications.isEmpty &&
        !parentState.isLoading) {
      print('📱 Loading parent data from notifications screen...');
      ref.read(parentProvider.notifier).loadParentData();
    } else if (!authState.isAuthenticated) {
      print('⚠️ Parent not authenticated, cannot load notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);
    final authState = ref.watch(parentAuthProvider);

    print('🚨 PARENT NOTIFICATIONS SCREEN - This is the correct screen!');
    print('📊 Current state:');
    print('  - Notifications count: ${parentState.notifications.length}');
    print('  - Unread count: ${parentState.unreadCount}');
    print('  - Is loading: ${parentState.isLoading}');
    print('  - Error: ${parentState.error}');

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
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                children: [
                  // Title and unread count
                  Row(
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      if (parentState.unreadCount != null &&
                          parentState.unreadCount! > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${parentState.unreadCount}',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // Action buttons
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                      size: 20.w,
                    ),
                    onPressed: () async {
                      await ref.read(parentProvider.notifier).loadParentData();
                    },
                  ),
                  if (parentState.unreadCount != null &&
                      parentState.unreadCount! > 0)
                    IconButton(
                      icon: Icon(
                        Icons.mark_email_read,
                        color: Colors.blue[600],
                        size: 20.w,
                      ),
                      onPressed: () {
                        ref
                            .read(parentProvider.notifier)
                            .markAllNotificationsAsRead();
                      },
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: !authState.isAuthenticated
                  ? _buildNotAuthenticatedState(context)
                  : parentState.isLoading
                  ? _buildLoadingState()
                  : parentState.error != null
                  ? _buildErrorState(context, parentState.error!)
                  : parentState.notifications.isEmpty
                  ? _buildEmptyState(context)
                  : _buildNotificationsList(
                      context,
                      ref,
                      parentState,
                      authState,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAuthenticatedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80.w, color: Colors.grey[400]),
            SizedBox(height: 24.h),
            Text(
              'Authentication Required',
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Please log in to view your notifications',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Go to Login',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.w, color: Colors.red[400]),
            SizedBox(height: 24.h),
            Text(
              'Error Loading Notifications',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () async {
                await ref.read(parentProvider.notifier).loadParentData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          CircularProgressIndicator(color: Colors.blue[600], strokeWidth: 3),
          SizedBox(height: 16.h),
          Text(
            'Loading notifications...',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    const Color(0xFF3B82F6).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 50.w,
                color: const Color(0xFF3B82F6),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'You\'ll receive notifications about your children\'s trips and emergencies here',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[600],
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16.w,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Pull down to refresh',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    parentState,
    authState,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(parentProvider.notifier).loadParentData();
      },
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 8.h,
          bottom: 24.h,
        ),
        itemCount: parentState.notifications.length,
        itemBuilder: (context, index) {
          final notification = parentState.notifications[index];
          return NotificationItemCard(notification: notification);
        },
      ),
    );
  }
}
