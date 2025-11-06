import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../../core/services/android_notification_listener_service.dart';

class NotificationListenerSettingsScreen extends StatefulWidget {
  const NotificationListenerSettingsScreen({super.key});

  @override
  State<NotificationListenerSettingsScreen> createState() =>
      _NotificationListenerSettingsScreenState();
}

class _NotificationListenerSettingsScreenState
    extends State<NotificationListenerSettingsScreen> {
  bool _isEnabled = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeNotifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
    _setupNotificationListener();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() => _isLoading = true);
    try {
      final enabled = await AndroidNotificationListenerService
          .isNotificationListenerEnabled();
      setState(() {
        _isEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error checking permission: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupNotificationListener() {
    AndroidNotificationListenerService.notificationStream.listen((event) {
      if (mounted) {
        setState(() {
          // Refresh notifications when new ones arrive
        });
        _loadActiveNotifications();
      }
    });
  }

  Future<void> _requestPermission() async {
    await AndroidNotificationListenerService.requestNotificationListenerPermission();
    // Wait a bit for user to enable it
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissionStatus();
  }

  Future<void> _loadActiveNotifications() async {
    if (!_isEnabled) return;

    setState(() => _isLoadingNotifications = true);
    try {
      final notifications =
          await AndroidNotificationListenerService.getActiveNotifications();
      setState(() {
        _activeNotifications = notifications;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() => _isLoadingNotifications = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Listener'),
        ),
        body: const Center(
          child: Text(
            'Notification listener is only available on Android',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Listener'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkPermissionStatus();
          if (_isEnabled) {
            await _loadActiveNotifications();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Permission Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isEnabled ? Icons.check_circle : Icons.cancel,
                            color: _isEnabled ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isEnabled
                                  ? 'Notification Listener Enabled'
                                  : 'Notification Listener Disabled',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (!_isEnabled)
                        ElevatedButton.icon(
                          onPressed: _requestPermission,
                          icon: const Icon(Icons.settings),
                          label: const Text('Enable Notification Listener'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Notifications Section
              if (_isEnabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadActiveNotifications,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoadingNotifications)
                  const Center(child: CircularProgressIndicator())
                else if (_activeNotifications.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No active notifications'),
                      ),
                    ),
                  )
                else
                  ..._activeNotifications.map((notification) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          notification['title'] ?? 'No title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (notification['text'] != null &&
                                notification['text'].toString().isNotEmpty)
                              Text(notification['text'].toString()),
                            const SizedBox(height: 4),
                            Text(
                              'Package: ${notification['packageName']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (notification['postTime'] != null)
                              Text(
                                'Time: ${DateTime.fromMillisecondsSinceEpoch(notification['postTime'] as int).toString()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


