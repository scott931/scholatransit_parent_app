import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
// REMOVED: import '../../features/notifications/screens/notifications_screen.dart'; // Using parent notifications instead
import '../../features/notifications/screens/alert_details_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/parent/screens/parent_tracking_screen.dart';
import '../../features/parent/screens/parent_schedule_screen.dart';
import '../../features/communication/screens/conversations_screen.dart';
import '../../features/communication/screens/chat_list_screen.dart';
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../features/parent/screens/parent_notifications_screen.dart';
import '../../features/parent/screens/parent_profile_screen.dart';
import '../../features/parent/screens/parent_students_screen.dart';
import '../../features/communication/screens/whatsapp_redirect_screen.dart';
import '../../features/communication/screens/contact_demo_screen.dart';
import '../../features/students/screens/qr_scanner_screen.dart';
import '../../features/students/screens/students_screen.dart';
import '../../features/students/screens/student_details_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import '../../features/trips/screens/trip_details_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/trip_logs/screens/trip_logs_screen.dart';
import '../../core/providers/parent_auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Root route - redirect to splash
      GoRoute(path: '/', name: 'root', redirect: (context, state) => '/splash'),
      // Splash route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Parent-only and shared routes
      // REMOVED: Duplicate notifications route - using /parent/notifications instead
      GoRoute(
        path: '/notifications/alert-details',
        name: 'alert-details',
        builder: (context, state) {
          final alertData = state.extra as Map<String, dynamic>;
          return AlertDetailsScreen(alertData: alertData);
        },
      ),
      GoRoute(
        path: '/communication/chats',
        name: 'communication-chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/communication/chats/:id',
        name: 'communication-chat-details',
        builder: (context, state) {
          final chatId = int.parse(state.pathParameters['id']!);
          return ChatDetailScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/conversations/whatsapp-redirect',
        name: 'whatsapp-redirect',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WhatsAppRedirectScreen(
            contactName: extra['contactName'] as String,
            contactType: extra['contactType'] as String,
            phoneNumber: extra['phoneNumber'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/contact-demo',
        name: 'contact-demo',
        builder: (context, state) => const ContactDemoScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Trip logs route
      GoRoute(
        path: '/trip-logs',
        name: 'trip-logs',
        builder: (context, state) => const TripLogsScreen(),
      ),
      // Students routes
      GoRoute(
        path: '/students',
        name: 'students',
        builder: (context, state) => const StudentsScreen(),
      ),
      GoRoute(
        path: '/students/:id',
        name: 'student-details',
        builder: (context, state) {
          final studentId = int.parse(state.pathParameters['id']!);
          return StudentDetailsScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/students/qr-scanner',
        name: 'students-qr-scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/students/simple-qr-scanner',
        name: 'students-simple-qr-scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      // Trips routes
      GoRoute(
        path: '/trips',
        name: 'trips',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: '/trips/details/:id',
        name: 'trip-details',
        builder: (context, state) {
          final tripId = int.parse(state.pathParameters['id']!);
          return TripDetailsScreen(tripId: tripId);
        },
      ),
      // Profile route
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Standalone QR Scanner route (not wrapped in ParentMainShell)
      GoRoute(
        path: '/parent/qr-scanner',
        name: 'parent-qr-scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      // Parent routes (wrapped in ParentMainShell)
      ShellRoute(
        builder: (context, state, child) => ParentMainShell(child: child),
        routes: [
          // Parent dashboard route
          GoRoute(
            path: '/parent/dashboard',
            name: 'parent-dashboard',
            builder: (context, state) => const ParentDashboardScreen(),
            redirect: (context, state) {
              final authState = ref.read(parentAuthProvider);
              return authState.isAuthenticated ? null : '/login';
            },
          ),
          GoRoute(
            path: '/parent/tracking',
            name: 'parent-tracking',
            builder: (context, state) => const ParentTrackingScreen(),
          ),
          GoRoute(
            path: '/parent/schedule',
            name: 'parent-schedule',
            builder: (context, state) => const ParentScheduleScreen(),
          ),
          GoRoute(
            path: '/parent/messages',
            name: 'parent-messages',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/parent/notifications',
            name: 'parent-notifications',
            builder: (context, state) => const ParentNotificationsScreen(),
            redirect: (context, state) {
              final authState = ref.read(parentAuthProvider);
              return authState.isAuthenticated ? null : '/login';
            },
          ),
          GoRoute(
            path: '/parent/students',
            name: 'parent-students',
            builder: (context, state) => const ParentStudentsScreen(),
            redirect: (context, state) {
              final authState = ref.read(parentAuthProvider);
              return authState.isAuthenticated ? null : '/login';
            },
          ),
          GoRoute(
            path: '/parent/attendance-history',
            name: 'parent-attendance-history',
            builder: (context, state) => const AttendanceHistoryScreen(),
          ),
          GoRoute(
            path: '/parent/profile',
            name: 'parent-profile',
            builder: (context, state) => const ParentProfileScreen(),
            redirect: (context, state) {
              final authState = ref.read(parentAuthProvider);
              return authState.isAuthenticated ? null : '/login';
            },
          ),
          GoRoute(
            path: '/parent/map',
            name: 'parent-map',
            builder: (context, state) => const MapScreen(),
          ),
        ],
      ),

      // Catch-all route for unknown paths
      GoRoute(
        path: '/:path(.*)',
        name: 'not-found',
        builder: (context, state) => _NotFoundScreen(path: state.uri.path),
      ),
    ],
    errorBuilder: (context, state) => _NotFoundScreen(path: state.uri.path),
  );
});

class ParentMainShell extends ConsumerWidget {
  final Widget child;

  const ParentMainShell({super.key, required this.child});

  String _getPageTitle(String currentPath) {
    switch (currentPath) {
      case '/parent/dashboard':
        return 'Dashboard';
      case '/parent/tracking':
        return 'Live Tracking';
      case '/parent/schedule':
        return 'Schedule';
      case '/parent/messages':
        return 'Messages';
      case '/parent/notifications':
        return 'Notifications';
      case '/parent/students':
        return 'Students';
      case '/parent/attendance-history':
        return 'Attendance History';
      case '/parent/profile':
        return 'Profile';
      case '/parent/map':
        return 'Map View';
      default:
        return 'Go Drop';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final pageTitle = _getPageTitle(currentPath);

    return PopScope(
      canPop: false, // Always prevent default pop behavior
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate back to dashboard from any page
          context.go('/parent/dashboard');
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Show back button if not on dashboard, otherwise show menu
                    currentPath == '/parent/dashboard'
                        ? Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu),
                              color: AppTheme.primaryColor,
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              tooltip: 'Menu',
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: AppTheme.primaryColor,
                            onPressed: () => context.go('/parent/dashboard'),
                            tooltip: 'Back',
                          ),
                    const SizedBox(width: 8),
                    Text(
                      pageTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ).copyWith(color: AppTheme.primaryColor),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      color: AppTheme.primaryColor,
                      tooltip: 'Notifications',
                      onPressed: () => context.go('/parent/notifications'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle_outlined),
                      color: AppTheme.primaryColor,
                      tooltip: 'Profile',
                      onPressed: () => context.go('/parent/profile'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
        drawer: _ParentSideDrawer(
          currentPath: currentPath,
          onNavigate: (path) => context.go(path),
        ),
      ),
    );
  }
}

class _ParentSideDrawer extends ConsumerWidget {
  final String currentPath;
  final void Function(String path) onNavigate;

  const _ParentSideDrawer({
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0052CC), Color(0xFF0066FF)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0052CC).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Go Drop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0052CC),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parent Portal',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _modernTile(
                      context,
                      title: 'Dashboard',
                      icon: Icons.dashboard_rounded,
                      selected: currentPath.startsWith('/parent/dashboard'),
                      to: '/parent/dashboard',
                    ),
                    _modernTile(
                      context,
                      title: 'Live Tracking',
                      icon: Icons.track_changes_rounded,
                      selected: currentPath.startsWith('/parent/tracking'),
                      to: '/parent/tracking',
                    ),
                    _modernTile(
                      context,
                      title: 'Schedule',
                      icon: Icons.schedule_rounded,
                      selected: currentPath.startsWith('/parent/schedule'),
                      to: '/parent/schedule',
                    ),
                    _modernTile(
                      context,
                      title: 'Messages',
                      icon: Icons.chat_bubble_rounded,
                      selected: currentPath.startsWith('/parent/messages'),
                      to: '/parent/messages',
                    ),
                    const SizedBox(height: 16),
                    _modernTile(
                      context,
                      title: 'Notifications',
                      icon: Icons.notifications_rounded,
                      selected: currentPath.startsWith('/parent/notifications'),
                      to: '/parent/notifications',
                    ),
                    _modernTile(
                      context,
                      title: 'Students',
                      icon: Icons.school_rounded,
                      selected: currentPath.startsWith('/parent/students'),
                      to: '/parent/students',
                    ),
                    _modernTile(
                      context,
                      title: 'Attendance History',
                      icon: Icons.history_rounded,
                      selected: currentPath.startsWith(
                        '/parent/attendance-history',
                      ),
                      to: '/parent/attendance-history',
                    ),
                    _modernTile(
                      context,
                      title: 'Profile',
                      icon: Icons.person_rounded,
                      selected: currentPath.startsWith('/parent/profile'),
                      to: '/parent/profile',
                    ),
                    _modernTile(
                      context,
                      title: 'QR Scanner',
                      icon: Icons.qr_code_scanner_rounded,
                      selected: currentPath.startsWith('/parent/qr-scanner'),
                      to: '/parent/qr-scanner',
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool selected,
    required String to,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF0052CC).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: const Color(0xFF0052CC).withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0052CC) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFF0052CC) : Colors.grey[800],
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          onNavigate(to);
        },
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  final String path;

  const _NotFoundScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0052CC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Page Not Found',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'GoException: no routes for location: $path',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0052CC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Home',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static GoRouter router(WidgetRef ref) => ref.read(appRouterProvider);
}
