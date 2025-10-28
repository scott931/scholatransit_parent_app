import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';

// General Alert Model
class GeneralAlert {
  final int id;
  final String title;
  final String description;
  final String type; // 'info', 'warning', 'success', 'error'
  final String priority; // 'low', 'medium', 'high', 'critical'
  final String status; // 'active', 'resolved', 'pending'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const GeneralAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.metadata,
  });

  factory GeneralAlert.fromJson(Map<String, dynamic> json) {
    return GeneralAlert(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String? ?? 'info',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_read': isRead,
      'metadata': metadata,
    };
  }

  GeneralAlert copyWith({
    int? id,
    String? title,
    String? description,
    String? type,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return GeneralAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

// General Alert State
class GeneralAlertState {
  final List<GeneralAlert> alerts;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const GeneralAlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  GeneralAlertState copyWith({
    List<GeneralAlert>? alerts,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return GeneralAlertState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// General Alert Notifier
class GeneralAlertNotifier extends StateNotifier<GeneralAlertState> {
  GeneralAlertNotifier() : super(const GeneralAlertState());

  // Load general alerts using centralized ApiService
  Future<void> loadGeneralAlerts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.generalAlerts,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final List<dynamic> alertsJson = data['results'] ?? [];
        final alerts = alertsJson
            .map((json) => GeneralAlert.fromJson(json))
            .toList();

        final unreadCount = alerts.where((alert) => !alert.isRead).length;

        state = state.copyWith(
          alerts: alerts,
          isLoading: false,
          unreadCount: unreadCount,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load alerts',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading alerts: $e',
      );
    }
  }

  // Create general alert using centralized ApiService
  Future<bool> createGeneralAlert({
    required String title,
    required String description,
    String type = 'info',
    String priority = 'medium',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.createGeneralAlert,
        data: {
          'title': title,
          'description': description,
          'type': type,
          'priority': priority,
          'metadata': metadata,
        },
      );

      if (response.success) {
        // Reload alerts to get the new one
        await loadGeneralAlerts();
        return true;
      } else {
        state = state.copyWith(
          error: response.error ?? 'Failed to create alert',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error creating alert: $e');
      return false;
    }
  }

  // Acknowledge general alert using centralized ApiService
  Future<bool> acknowledgeGeneralAlert(int alertId) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        ApiEndpoints.acknowledgeGeneralAlert(alertId),
      );

      if (response.success) {
        // Update the alert in the state
        final updatedAlerts = state.alerts.map((alert) {
          if (alert.id == alertId) {
            return alert.copyWith(isRead: true);
          }
          return alert;
        }).toList();

        final unreadCount = updatedAlerts
            .where((alert) => !alert.isRead)
            .length;

        state = state.copyWith(alerts: updatedAlerts, unreadCount: unreadCount);
        return true;
      } else {
        state = state.copyWith(
          error: response.error ?? 'Failed to acknowledge alert',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error acknowledging alert: $e');
      return false;
    }
  }

  // Mark all alerts as read
  Future<void> markAllAsRead() async {
    final updatedAlerts = state.alerts.map((alert) {
      return alert.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(alerts: updatedAlerts, unreadCount: 0);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final generalAlertProvider =
    StateNotifierProvider<GeneralAlertNotifier, GeneralAlertState>(
      (ref) => GeneralAlertNotifier(),
    );
