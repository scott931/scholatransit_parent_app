import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/widgets/notification_item_card.dart';
import '../../../core/services/notification_navigation_service.dart';
import 'package:go_router/go_router.dart';

class ParentNotificationsScreen extends ConsumerStatefulWidget {
  final dynamic highlightNotificationId;
  final Map<String, dynamic>? notificationData;
  
  const ParentNotificationsScreen({
    super.key,
    this.highlightNotificationId,
    this.notificationData,
  });

  @override
  ConsumerState<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState
    extends ConsumerState<ParentNotificationsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh notifications to see any that were received in background
      print('📱 App resumed - refreshing notifications to show background notifications');
      final authState = ref.read(parentAuthProvider);
      if (authState.isAuthenticated) {
        ref.read(parentProvider.notifier).loadParentData();
      }
    }
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
    
    // Check if we have notification data from navigation (from tapped notification)
    // First check widget parameter (from router extra if available)
    if (widget.notificationData != null) {
      print('📱 Found notification data in widget parameter');
      _addNotificationFromData(widget.notificationData!);
    } else {
      // Also check pending notification data from NotificationNavigationService
      // This is needed because GoRouter's go() doesn't support extra parameters
      final pendingData = NotificationNavigationService.getAndClearPendingNotificationData();
      if (pendingData != null) {
        print('📱 Found pending notification data from navigation service');
        _addNotificationFromData(pendingData);
      } else {
        print('📱 No notification data found to add');
      }
    }

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

  /// Add a notification to the state from notification data (e.g., from tapped background notification)
  Future<void> _addNotificationFromData(Map<String, dynamic> notificationData) async {
    try {
      print('═══════════════════════════════════════════════════════════');
      print('📱 ADDING NOTIFICATION FROM DATA');
      print('═══════════════════════════════════════════════════════════');
      print('📱 Notification data received: $notificationData');
      print('📱 Notification data type: ${notificationData.runtimeType}');
      print('📱 Notification data keys: ${notificationData.keys.toList()}');
      
      // CRITICAL: Debug - print all values to see what we have
      notificationData.forEach((key, value) {
        print('   - $key: $value (type: ${value.runtimeType}, isEmpty: ${value?.toString().isEmpty ?? true})');
      });
      
      // CRITICAL: Extract body with multiple fallbacks - check all possible locations
      final title = notificationData['title']?.toString() ?? 
                   notificationData['notification_title']?.toString() ??
                   'Notification';
      
      // Try multiple sources for body - this is critical for displaying content
      final body = notificationData['body']?.toString() ?? 
                  notificationData['message']?.toString() ??
                  notificationData['notification_body']?.toString() ??
                  notificationData['description']?.toString() ??
                  (notificationData['data'] is Map 
                    ? (notificationData['data'] as Map<String, dynamic>)['body']?.toString() ??
                      (notificationData['data'] as Map<String, dynamic>)['message']?.toString()
                    : null) ??
                  '';
      
      final data = notificationData['data'] as Map<String, dynamic>? ?? {};
      final type = notificationData['type']?.toString() ?? 
                  notificationData['notification_type']?.toString() ??
                  'general';
      
      print('📱 Extracted values:');
      print('   - Title: "$title" (length: ${title.length})');
      print('   - Body: "$body" (length: ${body.length})');
      print('   - Type: $type');
      print('   - Data keys: ${data.keys.toList()}');
      print('   - Full notificationData keys: ${notificationData.keys.toList()}');
      
      // Debug: Check if body is in nested data
      if (body.isEmpty && data.isNotEmpty) {
        print('⚠️ Body is empty, checking nested data...');
        print('   - data[\'body\']: ${data['body']}');
        print('   - data[\'message\']: ${data['message']}');
      }
      
      // CRITICAL: If body is still empty, try to get it from data map
      final finalBody = body.isNotEmpty 
          ? body 
          : (data['body']?.toString() ?? 
             data['message']?.toString() ?? 
             data['notification_body']?.toString() ?? 
             '');
      
      print('📱 Final body after all fallbacks: "$finalBody" (length: ${finalBody.length})');
      
      // Create a notification object that matches both server format and NotificationDetailsScreen expectations
      final now = DateTime.now();
      
      // CRITICAL: Create base notification with body/message FIRST, then spread data
      // This ensures body/message are not overwritten by data spread
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch, // Temporary ID
        'title': title,
        // CRITICAL: Set body and message FIRST before spreading data
        // This ensures they're not overwritten by empty values from data
        'body': finalBody.isNotEmpty ? finalBody : 'No message content available',
        'message': finalBody.isNotEmpty ? finalBody : 'No message content available',
        // Include both 'notification_type' (for server format) and 'type' (for NotificationDetailsScreen)
        'notification_type': type,
        'type': type,
        'notification_type_display': type.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' '),
        // Include both 'created_at' (for server format) and 'timestamp' (for NotificationDetailsScreen)
        'created_at': now.toIso8601String(),
        'timestamp': now.toIso8601String(),
        'is_read': false,
        'isRead': false,
        // CRITICAL: Spread data LAST, but exclude body/message to prevent overwriting
        // Filter out body/message from data if they're empty, so they don't overwrite our values
        ...Map.fromEntries(
          data.entries.where((entry) {
            // Don't include body/message if they're empty strings - we'll set them explicitly
            if ((entry.key == 'body' || entry.key == 'message') && 
                (entry.value == null || entry.value.toString().isEmpty)) {
              return false;
            }
            return true;
          })
        ),
        // CRITICAL: Always set body and message explicitly AFTER spreading data
        // Use finalBody if available, otherwise try data, otherwise use fallback
        'body': finalBody.isNotEmpty 
            ? finalBody 
            : ((data['body']?.toString()?.isNotEmpty == true) 
                ? data['body']!.toString() 
                : ((data['message']?.toString()?.isNotEmpty == true)
                    ? data['message']!.toString()
                    : 'No message content available')),
        'message': finalBody.isNotEmpty 
            ? finalBody 
            : ((data['message']?.toString()?.isNotEmpty == true) 
                ? data['message']!.toString() 
                : ((data['body']?.toString()?.isNotEmpty == true)
                    ? data['body']!.toString()
                    : 'No message content available')),
      };
      
      print('📱 Created notification object:');
      print('   - ID: ${notification['id']}');
      print('   - Title: "${notification['title']}"');
      print('   - Body: "${notification['body']}" (length: ${notification['body'].toString().length})');
      print('   - Message: "${notification['message']}" (length: ${notification['message'].toString().length})');
      print('   - Type: ${notification['type']}');
      print('   - Timestamp: ${notification['timestamp']}');
      print('═══════════════════════════════════════════════════════════');
      
      // Add to parent provider state
      // Access the notifier through ref
      final notifier = ref.read(parentProvider.notifier);
      
      // Use a private method to add notification - we'll need to make it public or use a different approach
      // For now, let's add it directly to the state by calling loadParentData which will merge with server data
      // But first, let's try to add it directly if there's a public method
      
      // Actually, we can't directly access _addNotification, so let's add it to a temporary list
      // and it will be merged when loadParentData is called
      // Or better: create a method in parent provider to add a notification
      
      // For now, let's just refresh to get server data, and the notification should appear
      // But the issue is the server doesn't have it yet
      
      // Verify notification has body before adding
      print('📱 Verifying notification before adding:');
      print('   - Has title: ${notification['title'] != null && notification['title'].toString().isNotEmpty}');
      print('   - Has body: ${notification['body'] != null && notification['body'].toString().isNotEmpty}');
      print('   - Has message: ${notification['message'] != null && notification['message'].toString().isNotEmpty}');
      print('   - Body value: "${notification['body']}"');
      print('   - Message value: "${notification['message']}"');
      
      // CRITICAL: Double-check body before adding
      print('📱 FINAL CHECK before adding to provider:');
      print('   - Notification body: "${notification['body']}" (length: ${notification['body']?.toString().length ?? 0})');
      print('   - Notification message: "${notification['message']}" (length: ${notification['message']?.toString().length ?? 0})');
      print('   - Full notification object: $notification');
      
      // Add notification using the provider's public method
      ref.read(parentProvider.notifier).addNotificationFromExternalSource(notification);
      
      // Verify it was added - wait a bit for state to update
      await Future.delayed(Duration(milliseconds: 100));
      final updatedState = ref.read(parentProvider);
      print('✅ Added notification to state');
      print('📱 Total notifications now: ${updatedState.notifications.length}');
      if (updatedState.notifications.isNotEmpty) {
        final addedNotification = updatedState.notifications.first;
        print('═══════════════════════════════════════════════════════════');
        print('📱 VERIFICATION - First notification in state:');
        print('═══════════════════════════════════════════════════════════');
        print('   - Title: "${addedNotification['title']}"');
        print('   - Body: "${addedNotification['body']}" (length: ${addedNotification['body']?.toString().length ?? 0})');
        print('   - Message: "${addedNotification['message']}" (length: ${addedNotification['message']?.toString().length ?? 0})');
        print('   - Keys: ${addedNotification.keys.toList()}');
        print('   - Full notification: $addedNotification');
        print('═══════════════════════════════════════════════════════════');
        
        // CRITICAL: If body is still empty, log a warning
        final bodyInState = addedNotification['body']?.toString() ?? '';
        final messageInState = addedNotification['message']?.toString() ?? '';
        if (bodyInState.isEmpty || bodyInState == 'No message content available') {
          print('⚠️⚠️⚠️ WARNING: Body is still empty in state! ⚠️⚠️⚠️');
          print('⚠️ This means the body was lost during the add process');
        } else {
          print('✅ Body is present in state: "$bodyInState"');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Failed to add notification from data: $e');
      print('❌ Stack trace: $stackTrace');
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
