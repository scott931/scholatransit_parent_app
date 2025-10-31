import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/communication_log_model.dart';
import 'api_service.dart';

/// Consolidated Communication Service
/// Combines all communication functionality including API calls and logging
class ConsolidatedCommunicationService {
  static const String _logsKey = 'communication_logs';
  static List<CommunicationLog> _logs = [];
  static bool _isInitialized = false;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the consolidated communication service
  static Future<void> init() async {
    if (_isInitialized) return;
    await _loadLogs();
    _isInitialized = true;
  }

  /// Load logs from SharedPreferences
  static Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_logsKey) ?? [];

      // Parse logs with error handling for individual entries
      final List<CommunicationLog> loadedLogs = [];
      for (final jsonString in logsJson) {
        try {
          final json = jsonDecode(jsonString);
          final log = CommunicationLog.fromJson(json);
          loadedLogs.add(log);
        } catch (e) {
          print('Error parsing log entry: $e, skipping entry: $jsonString');
          // Continue with other entries instead of failing completely
        }
      }

      _logs = loadedLogs;
      print('Loaded ${_logs.length} communication logs from storage');
    } catch (e) {
      print('Error loading logs: $e');
      _logs = [];
    }
  }

  /// Save logs to SharedPreferences
  static Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => jsonEncode(log.toJson())).toList();
      await prefs.setStringList(_logsKey, logsJson);
      print('Saved ${_logs.length} communication logs to storage');
    } catch (e) {
      print('Error saving logs: $e');
      // Try to save individual logs if batch save fails
      await _saveLogsIndividually();
    }
  }

  /// Fallback method to save logs individually if batch save fails
  static Future<void> _saveLogsIndividually() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> logsJson = [];

      for (final log in _logs) {
        try {
          logsJson.add(jsonEncode(log.toJson()));
        } catch (e) {
          print('Error encoding individual log: $e');
        }
      }

      await prefs.setStringList(_logsKey, logsJson);
      print('Saved ${logsJson.length} communication logs individually');
    } catch (e) {
      print('Error saving logs individually: $e');
    }
  }

  // ============================================================================
  // COMMUNICATION LOGGING
  // ============================================================================

  /// Log a communication attempt
  static Future<void> logCommunication({
    required String phoneNumber,
    required String contactName,
    required CommunicationType type,
    required bool success,
    String? message,
    String? errorMessage,
    String? studentName,
    String? driverId = 'current_driver',
  }) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await init();
      }

      final log = CommunicationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: phoneNumber,
        contactName: contactName,
        type: type,
        timestamp: DateTime.now(),
        message: message,
        success: success,
        errorMessage: errorMessage,
        driverId: driverId ?? 'current_driver',
        studentName: studentName,
      );

      _logs.add(log);
      await _saveLogs();
      print(
        'Communication logged: ${log.type.displayName} to ${log.phoneNumber} (Success: $success)',
      );
    } catch (e) {
      print('Error logging communication: $e');
      // Try to save the log even if there's an error
      try {
        await _saveLogs();
      } catch (saveError) {
        print('Failed to save logs after error: $saveError');
      }
    }
  }

  /// Get all communication logs
  static List<CommunicationLog> getAllLogs() {
    if (!_isInitialized) {
      print('Warning: Service not initialized, returning empty logs');
      return [];
    }
    return List.from(_logs)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by type
  static List<CommunicationLog> getLogsByType(CommunicationType type) {
    return _logs.where((log) => log.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by date range
  static List<CommunicationLog> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _logs
        .where(
          (log) =>
              log.timestamp.isAfter(startDate) &&
              log.timestamp.isBefore(endDate),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by phone number
  static List<CommunicationLog> getLogsByPhoneNumber(String phoneNumber) {
    return _logs.where((log) => log.phoneNumber == phoneNumber).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get successful logs only
  static List<CommunicationLog> getSuccessfulLogs() {
    return _logs.where((log) => log.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get failed logs only
  static List<CommunicationLog> getFailedLogs() {
    return _logs.where((log) => !log.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get communication statistics
  static Map<String, dynamic> getStatistics() {
    final logs = _logs;

    final totalLogs = logs.length;
    final successfulLogs = logs.where((log) => log.success).length;
    final failedLogs = totalLogs - successfulLogs;

    final callLogs = logs
        .where((log) => log.type == CommunicationType.call)
        .length;
    final whatsappLogs = logs
        .where((log) => log.type == CommunicationType.whatsapp)
        .length;
    final smsLogs = logs
        .where((log) => log.type == CommunicationType.sms)
        .length;

    return {
      'total': totalLogs,
      'successful': successfulLogs,
      'failed': failedLogs,
      'success_rate': totalLogs > 0
          ? (successfulLogs / totalLogs * 100).toStringAsFixed(1)
          : '0.0',
      'calls': callLogs,
      'whatsapp': whatsappLogs,
      'sms': smsLogs,
    };
  }

  /// Clear all logs
  static Future<void> clearAllLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  /// Delete a specific log
  static Future<void> deleteLog(String logId) async {
    _logs.removeWhere((log) => log.id == logId);
    await _saveLogs();
  }

  /// Get recent logs (last 10)
  static List<CommunicationLog> getRecentLogs({int limit = 10}) {
    final logs = getAllLogs();
    return logs.take(limit).toList();
  }

  /// Search logs by contact name or phone number
  static List<CommunicationLog> searchLogs(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _logs
        .where(
          (log) =>
              log.contactName.toLowerCase().contains(lowercaseQuery) ||
              log.phoneNumber.contains(query) ||
              (log.studentName?.toLowerCase().contains(lowercaseQuery) ??
                  false),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ============================================================================
  // API COMMUNICATION METHODS
  // ============================================================================

  /// List all chats for the authenticated user
  static Future<ApiResponse<dynamic>> listChats({
    int? page,
    int? pageSize,
  }) async {
    return ApiService.get<dynamic>(
      '/api/v1/communication/chats/',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      },
    );
  }

  /// Create a Driver-Parent chat (student_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createDriverParentChat({
    required int studentId,
  }) async {
    final path = '/api/v1/communication/driver-parent/$studentId/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Create an Admin-Driver chat (driver_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createAdminDriverChat({
    required int driverId,
  }) async {
    final path = '/api/v1/communication/admin-driver/$driverId/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Create an Admin-Parent chat (parent_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createAdminParentChat({
    required int parentId,
  }) async {
    final path = '/api/v1/communication/admin-parent/$parentId/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Create a general chat (any authenticated user) - legacy support
  static Future<ApiResponse<Map<String, dynamic>>> createGeneralChat({
    required String title,
    required List<int> participantIds,
    String? description,
  }) async {
    final path = '/api/v1/communication/chats/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'title': title,
        'description': description,
        'participant_ids': participantIds,
      },
    );
  }

  /// Create a new chat with specified chat_type and other_user_id (optional student)
  static Future<ApiResponse<Map<String, dynamic>>> createChat({
    required String chatType,
    required int otherUserId,
    int? studentId,
  }) async {
    final path = '/api/v1/communication/chats/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'chat_type': chatType,
        'other_user_id': otherUserId,
        if (studentId != null) 'student': studentId,
      },
    );
  }

  /// Get chat details (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> getChatDetails({
    required int chatId,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/';
    return ApiService.get<Map<String, dynamic>>(path);
  }

  /// Send text message
  static Future<ApiResponse<Map<String, dynamic>>> sendTextMessage({
    required int chatId,
    required String content,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {'message_type': 'text', 'content': content},
    );
  }

  /// Send voice message
  static Future<ApiResponse<Map<String, dynamic>>> sendVoiceMessage({
    required int chatId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'content': content,
        'attachment': attachment,
        if (replyTo != null) 'reply_to': replyTo,
      },
    );
  }

  /// Send image message
  static Future<ApiResponse<Map<String, dynamic>>> sendImageMessage({
    required int chatId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'message_type': 'image',
        'content': content,
        'attachment': attachment,
        if (replyTo != null) 'reply_to': replyTo,
      },
    );
  }

  /// Reply to a message in a chat
  static Future<ApiResponse<Map<String, dynamic>>> replyToMessage({
    required int chatId,
    required int replyToMessageId,
    required String content,
    String? attachment,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'message_type': 'text',
        'content': content,
        'attachment': attachment,
        'reply_to': replyToMessageId,
      },
    );
  }

  /// Mark a chat as read (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> markChatAsRead({
    required int chatId,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/read/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Toggle chat pin (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> toggleChatPin({
    required int chatId,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/pin/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Toggle chat mute (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> toggleChatMute({
    required int chatId,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/mute/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Get unread count across chats (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> getUnreadCount() async {
    final path = '/api/v1/communication/unread-count/';
    return ApiService.get<Map<String, dynamic>>(path);
  }

  /// Search chats (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> searchChats({
    required String query,
  }) async {
    final path = '/api/v1/communication/search/';
    return ApiService.get<Map<String, dynamic>>(
      path,
      queryParameters: {'q': query},
    );
  }

  /// Get messages in a chat (supports list or paginated map)
  static Future<ApiResponse<dynamic>> getChatMessages({
    required int chatId,
  }) async {
    final path = '/api/v1/communication/chats/$chatId/messages/';
    return ApiService.get<dynamic>(path);
  }

  // ============================================================================
  // PARENT-SPECIFIC COMMUNICATION METHODS
  // ============================================================================

  /// Create a Parent-Driver chat
  static Future<ApiResponse<Map<String, dynamic>>> createParentDriverChat({
    required int parentId,
    required int driverId,
    required int childId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/',
      data: {'parent_id': parentId, 'driver_id': driverId, 'child_id': childId},
    );
  }

  /// Create a Parent-Admin chat
  static Future<ApiResponse<Map<String, dynamic>>> createParentAdminChat({
    required int parentId,
    required int adminId,
    String? subject,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/',
      data: {'parent_id': parentId, 'admin_id': adminId, 'subject': subject},
    );
  }

  /// Get parent's conversations
  static Future<ApiResponse<Map<String, dynamic>>> getParentConversations({
    int? page,
    int? pageSize,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/api/v1/communication/chats/',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      },
    );
  }

  /// Get conversation details
  static Future<ApiResponse<Map<String, dynamic>>> getConversationDetails({
    required int conversationId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/',
    );
  }

  /// Send message in conversation
  static Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    required int conversationId,
    required String content,
    String? messageType,
    String? attachment,
    int? replyTo,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/messages/',
      data: {
        'content': content,
        'message_type': messageType ?? 'text',
        if (attachment != null) 'attachment': attachment,
        if (replyTo != null) 'reply_to': replyTo,
      },
    );
  }

  /// Get conversation messages
  static Future<ApiResponse<Map<String, dynamic>>> getConversationMessages({
    required int conversationId,
    int? page,
    int? pageSize,
    String? before,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/messages/',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
        if (before != null) 'before': before,
      },
    );
  }

  /// Mark conversation as read
  static Future<ApiResponse<Map<String, dynamic>>> markConversationAsRead({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/read/',
    );
  }

  /// Pin conversation
  static Future<ApiResponse<Map<String, dynamic>>> pinConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/pin/',
    );
  }

  /// Unpin conversation
  static Future<ApiResponse<Map<String, dynamic>>> unpinConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/unpin/',
    );
  }

  /// Mute conversation
  static Future<ApiResponse<Map<String, dynamic>>> muteConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/mute/',
    );
  }

  /// Unmute conversation
  static Future<ApiResponse<Map<String, dynamic>>> unmuteConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/api/v1/communication/chats/$conversationId/unmute/',
    );
  }

  /// Get unread message count for parent
  static Future<ApiResponse<Map<String, dynamic>>> getParentUnreadCount({
    required int parentId,
  }) async {
    return ApiService.get<Map<String, dynamic>>('/api/v1/communication/chats/');
  }

  /// Search conversations for parent
  static Future<ApiResponse<Map<String, dynamic>>> searchParentConversations({
    required int parentId,
    required String query,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/api/v1/communication/chats/',
      queryParameters: {'q': query},
    );
  }

  /// Get driver contact information
  static Future<ApiResponse<Map<String, dynamic>>> getDriverContact({
    required int driverId,
  }) async {
    return ApiService.get<Map<String, dynamic>>('/api/v1/communication/chats/');
  }

  /// Get admin contact information
  static Future<ApiResponse<Map<String, dynamic>>> getAdminContact({
    required int adminId,
  }) async {
    return ApiService.get<Map<String, dynamic>>('/api/v1/communication/chats/');
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Force reload logs from storage
  static Future<void> reloadLogs() async {
    await _loadLogs();
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get current log count
  static int get logCount => _logs.length;

  /// Add test logs for debugging (remove in production)
  static Future<void> addTestLogs() async {
    if (!_isInitialized) {
      await init();
    }

    final testLogs = [
      CommunicationLog(
        id: 'test_1',
        phoneNumber: '+254712345678',
        contactName: 'Test Parent 1',
        type: CommunicationType.call,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        success: true,
        driverId: 'test_driver',
        studentName: 'John Doe',
      ),
      CommunicationLog(
        id: 'test_2',
        phoneNumber: '+254712345679',
        contactName: 'Test Parent 2',
        type: CommunicationType.whatsapp,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        success: false,
        errorMessage: 'WhatsApp not available',
        driverId: 'test_driver',
        studentName: 'Jane Smith',
      ),
    ];

    for (final log in testLogs) {
      _logs.add(log);
    }

    await _saveLogs();
    print('Added ${testLogs.length} test logs');
  }
}
