import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/notifications/screens/notification_details_screen.dart';
import '../../features/emergency/screens/emergency_alert_details_screen.dart';
import '../providers/parent_provider.dart';

class NotificationItemCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationItemCard({super.key, required this.notification});

  @override
  ConsumerState<NotificationItemCard> createState() =>
      _NotificationItemCardState();
}

class _NotificationItemCardState extends ConsumerState<NotificationItemCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print notification structure
    print('🔍 Notification fields: ${widget.notification.keys.toList()}');
    print('🔍 Notification data: $widget.notification');

    // Handle different notification field names
    final title =
        widget.notification['title']?.toString() ??
        widget.notification['message']?.toString() ??
        widget.notification['emergency_type_display']?.toString() ??
        'Notification';
    final body =
        widget.notification['body']?.toString() ??
        widget.notification['description']?.toString() ??
        widget.notification['message']?.toString() ??
        widget.notification['emergency_type_display']?.toString() ??
        'Tap to view details';
    final timestampStr =
        widget.notification['timestamp']?.toString() ??
        widget.notification['created_at']?.toString();
    final timestamp = timestampStr != null
        ? DateTime.tryParse(timestampStr) ?? DateTime.now()
        : DateTime.now();
    final type =
        widget.notification['type']?.toString() ??
        widget.notification['emergency_type']?.toString() ??
        'general';
    final isRead =
        widget.notification['isRead'] as bool? ??
        widget.notification['is_read'] as bool? ??
        false;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Dismissible(
                key: Key('notification_${widget.notification['id']}'),
                direction: DismissDirection.horizontal,
                background: _buildSwipeBackground(true, isRead),
                secondaryBackground: _buildSwipeBackground(false, isRead),
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    ref
                        .read(parentProvider.notifier)
                        .markNotificationAsRead(widget.notification['id']);
                  } else if (direction == DismissDirection.endToStart) {
                    // Delete notification - implement if needed
                  }
                },
                child: GestureDetector(
                  onTap: () async {
                    print('🔔 Notification card tapped!');
                    print('📱 Notification data: ${widget.notification}');
                    print('📱 Notification type: $type');

                    if (!isRead) {
                      print('📱 Marking notification as read...');
                      final notificationId = widget.notification['id'];
                      if (notificationId is int) {
                        ref
                            .read(parentProvider.notifier)
                            .markNotificationAsRead(notificationId);
                      } else if (notificationId is String) {
                        // For string IDs, we might need to handle them differently
                        // or convert them to integers if possible
                        print('📱 Notification ID is string: $notificationId');
                        // Try to extract numeric part if it's in format like "emergency_2"
                        if (notificationId.contains('_')) {
                          final parts = notificationId.split('_');
                          final numericPart = parts.last;
                          final numericId = int.tryParse(numericPart);
                          if (numericId != null) {
                            ref
                                .read(parentProvider.notifier)
                                .markNotificationAsRead(numericId);
                          } else {
                            print('❌ Could not convert string ID to integer');
                          }
                        } else {
                          print('❌ String ID format not recognized');
                        }
                      } else {
                        print(
                          '❌ Notification ID type not supported: ${notificationId.runtimeType}',
                        );
                      }
                    }

                    // Check if this is an emergency alert
                    final alertId =
                        widget.notification['alert_id'] ??
                        widget.notification['emergency_alert_id'];

                    print('📱 Alert ID: $alertId');

                    if (type.toLowerCase() == 'emergency') {
                      print('🚨 Navigating to emergency alert details...');

                      // For emergency notifications, we need to extract the alert ID
                      // The notification ID might be in format "emergency_2" where 2 is the actual ID
                      int? actualAlertId;

                      if (alertId != null) {
                        // If we have a direct alert_id field
                        actualAlertId = alertId is int
                            ? alertId
                            : int.tryParse(alertId.toString());
                      } else {
                        // Try to extract ID from the notification ID (e.g., "emergency_2" -> 2)
                        final notificationId =
                            widget.notification['id']?.toString() ?? '';
                        if (notificationId.startsWith('emergency_')) {
                          final idPart = notificationId.split('_').last;
                          actualAlertId = int.tryParse(idPart);
                        }
                      }

                      print('📱 Actual Alert ID: $actualAlertId');

                      if (actualAlertId != null) {
                        // Navigate to emergency alert details
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EmergencyAlertDetailsScreen(
                              alertId: actualAlertId!,
                            ),
                          ),
                        );
                      } else {
                        print(
                          '❌ Could not extract alert ID, showing notification details instead',
                        );
                        // Fallback to regular notification details
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailsScreen(
                              notification: widget.notification,
                            ),
                          ),
                        );
                      }
                    } else {
                      print('📄 Navigating to regular notification details...');
                      // Navigate to regular notification details
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailsScreen(
                            notification: widget.notification,
                          ),
                        ),
                      );
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _hoverController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_hoverController.value * 0.02),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 0.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Main content
                              Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with type badge and time
                                    _buildHeader(type, timestamp, isRead),
                                    SizedBox(height: 12.h),

                                    // Title with modern typography
                                    _buildTitle(title, isRead),
                                    SizedBox(height: 8.h),

                                    // Description with improved readability (truncated)
                                    _buildDescription(body, isRead),
                                  ],
                                ),
                              ),

                              // Unread indicator
                              if (!isRead)
                                Positioned(
                                  top: 20.h,
                                  right: 20.w,
                                  child: _buildUnreadIndicator(type),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String type, DateTime timestamp, bool isRead) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Modern type badge with icon - Flexible to prevent overflow
        Flexible(
          flex: 2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _getTypeColor(type).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    size: 14.w,
                    color: _getTypeColor(type),
                  ),
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    _getTypeLabel(type),
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _getTypeColor(type),
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 8.w),

        // Modern time display - Flexible to prevent overflow
        Flexible(
          flex: 1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.grey[100]?.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12.w,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    _formatTimestamp(timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(String title, bool isRead) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16.sp,
        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
        color: isRead ? Colors.grey[700] : Colors.grey[900],
        height: 1.3,
        letterSpacing: 0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(String body, bool isRead) {
    return Text(
      body,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        color: isRead ? Colors.grey[500] : Colors.grey[700],
        height: 1.5,
        letterSpacing: 0.1,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Sender info if available
        if (widget.notification['sender_name'] != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 12.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'From: ${widget.notification['sender_name']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ] else
          const Spacer(),

        // Action indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12.w,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4.w),
              Text(
                'Tap to view',
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
    );
  }

  Widget _buildUnreadIndicator(String type) {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: _getTypeColor(type),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeft, bool isRead) {
    final color = isLeft ? (isRead ? Colors.orange : Colors.blue) : Colors.red;
    final icon = isLeft
        ? (isRead
              ? Icons.mark_email_unread_rounded
              : Icons.mark_email_read_rounded)
        : Icons.delete_rounded;
    final text = isLeft ? (isRead ? 'Mark Unread' : 'Mark Read') : 'Delete';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        mainAxisAlignment: isLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (!isLeft) const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color[700], size: 20.w),
                ),
                SizedBox(height: 8.h),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color[700],
                  ),
                ),
              ],
            ),
          ),
          if (isLeft) const Spacer(),
        ],
      ),
    );
  }

  LinearGradient _buildCardGradient(String type, bool isRead) {
    if (isRead) {
      return LinearGradient(
        colors: [Colors.grey[50]!, Colors.grey[100]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    final typeColor = _getTypeColor(type);
    return LinearGradient(
      colors: [Colors.white, typeColor.withOpacity(0.02), Colors.grey[50]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<BoxShadow> _buildCardShadows(String type, bool isRead) {
    if (isRead) {
      return [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    final typeColor = _getTypeColor(type);
    return [
      BoxShadow(
        color: typeColor.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return const Color(0xFFE53E3E); // Modern red
      case 'trip':
        return const Color(0xFF3182CE); // Modern blue
      case 'student':
        return const Color(0xFF38A169); // Modern green
      case 'message':
        return const Color(0xFFED8936); // Modern orange
      case 'comment':
        return const Color(0xFF805AD5); // Modern purple
      case 'connect':
        return const Color(0xFF3182CE); // Modern blue
      case 'joined':
        return const Color(0xFF38A169); // Modern green
      default:
        return const Color(0xFF718096); // Modern gray
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Icons.warning_rounded;
      case 'trip':
        return Icons.directions_bus_rounded;
      case 'student':
        return Icons.school_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'connect':
        return Icons.link_rounded;
      case 'joined':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return 'Emergency';
      case 'trip':
        return 'Trip';
      case 'student':
        return 'Student';
      case 'message':
        return 'Message';
      case 'comment':
        return 'Comment';
      case 'connect':
        return 'Connect';
      case 'joined':
        return 'New User';
      default:
        return 'Notification';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = timestamp.day;
      final month = months[timestamp.month - 1];
      final year = timestamp.year;
      final hour = timestamp.hour;
      final minute = timestamp.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');

      return '$day $month $year at $displayHour:$minuteStr $period';
    }
  }
}
