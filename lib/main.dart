import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui' as ui;

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/location_health_monitor.dart';
import 'core/services/simple_communication_log_service.dart';
import 'core/services/android_notification_listener_service.dart';
import 'core/widgets/system_back_button_handler.dart';
import 'core/config/app_config.dart';
import 'core/utils/hot_reload_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Import background handler function - must be imported before Firebase init
import 'core/services/notification_service.dart' show firebaseMessagingBackgroundHandler;
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background message handler BEFORE initializing Firebase
  // This must be done before Firebase.initializeApp() is called
  // The handler is defined in notification_service.dart as a top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Firebase: $e');
    print('⚠️ App will continue without Firebase functionality');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize services
  await _initializeServices();

  // Request permissions
  await _requestPermissions();

  runApp(const ProviderScope(child: GoDropApp()));
}

Future<void> _initializeServices() async {
  // Initialize persistent storage (SharedPreferences + Hive box)
  await StorageService.init();

  // Initialize API client (Dio, interceptors)
  await ApiService.init();

  // Initialize communication log service
  await SimpleCommunicationLogService.init();

  // Initialize notification service for local notifications
  await NotificationService.init();

  // Initialize Android notification listener service (Android only)
  await AndroidNotificationListenerService.initialize();

  // Initialize location health monitoring
  LocationHealthMonitor.startMonitoring();

  // Initialize Mapbox SDK
  await _initializeMapbox();
}

Future<void> _initializeMapbox() async {
  try {
    print('🗺️ Initializing Mapbox SDK...');
    print('🗺️ Mapbox Token: ${AppConfig.mapboxToken.substring(0, 20)}...');

    // Validate token format
    if (AppConfig.mapboxToken.isEmpty ||
        !AppConfig.mapboxToken.startsWith('pk.')) {
      throw Exception('Invalid Mapbox token format');
    }

    MapboxOptions.setAccessToken(AppConfig.mapboxToken);
    print('✅ Mapbox SDK initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Mapbox SDK: $e');
    // Don't throw the error to prevent app crash, but log it
    print('⚠️ App will continue without Mapbox functionality');
  }
}

Future<void> _requestPermissions() async {
  // Request location permission
  await Permission.locationWhenInUse.request();

  // Request notification permission
  await Permission.notification.request();

  // Request camera permission (for QR scanning)
  await Permission.camera.request();

  // Request contact permission (for parent contact selection)
  await Permission.contacts.request();
}

class GoDropApp extends ConsumerWidget {
  const GoDropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize hot reload handler in development
    if (kDebugMode) {
      HotReloadHandler.initialize(ref);
    }

    return ScreenUtilInit(
      designSize: const ui.Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'GoDrop Parent',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: ref.watch(appRouterProvider),
          builder: (context, child) {
            return SystemBackButtonHandler(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0), // Disable text scaling
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
