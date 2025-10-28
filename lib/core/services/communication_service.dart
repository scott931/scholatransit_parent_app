import 'api_service.dart';
import 'consolidated_communication_service.dart';

/// Legacy CommunicationService - now uses ConsolidatedCommunicationService internally
/// Maintains backward compatibility while using the improved implementation
class CommunicationService {
  /// List all chats for the authenticated user
  static Future<ApiResponse<Map<String, dynamic>>> listChats({
    int? page,
    int? pageSize,
  }) async {
    return ConsolidatedCommunicationService.listChats(
      page: page,
      pageSize: pageSize,
    );
  }

  /// Create a Driver-Parent chat (student_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createDriverParentChat({
    required int studentId,
  }) async {
    return ConsolidatedCommunicationService.createDriverParentChat(
      studentId: studentId,
    );
  }

  /// Create an Admin-Driver chat (driver_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createAdminDriverChat({
    required int driverId,
  }) async {
    return ConsolidatedCommunicationService.createAdminDriverChat(
      driverId: driverId,
    );
  }

  /// Create an Admin-Parent chat (parent_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createAdminParentChat({
    required int parentId,
  }) async {
    return ConsolidatedCommunicationService.createAdminParentChat(
      parentId: parentId,
    );
  }

  /// Create a general chat (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> createGeneralChat({
    required String title,
    required List<int> participantIds,
    String? description,
  }) async {
    return ConsolidatedCommunicationService.createGeneralChat(
      title: title,
      participantIds: participantIds,
      description: description,
    );
  }

  /// Get chat details (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> getChatDetails({
    required int chatId,
  }) async {
    return ConsolidatedCommunicationService.getChatDetails(chatId: chatId);
  }

  /// Send text message
  static Future<ApiResponse<Map<String, dynamic>>> sendTextMessage({
    required int chatId,
    required String content,
  }) async {
    return ConsolidatedCommunicationService.sendTextMessage(
      chatId: chatId,
      content: content,
    );
  }

  /// Send voice message
  static Future<ApiResponse<Map<String, dynamic>>> sendVoiceMessage({
    required int chatId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    return ConsolidatedCommunicationService.sendVoiceMessage(
      chatId: chatId,
      content: content,
      attachment: attachment,
      replyTo: replyTo,
    );
  }

  /// Send image message
  static Future<ApiResponse<Map<String, dynamic>>> sendImageMessage({
    required int chatId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    return ConsolidatedCommunicationService.sendImageMessage(
      chatId: chatId,
      content: content,
      attachment: attachment,
      replyTo: replyTo,
    );
  }

  /// Reply to a message in a chat
  static Future<ApiResponse<Map<String, dynamic>>> replyToMessage({
    required int chatId,
    required int replyToMessageId,
    required String content,
    String? attachment,
  }) async {
    return ConsolidatedCommunicationService.replyToMessage(
      chatId: chatId,
      replyToMessageId: replyToMessageId,
      content: content,
      attachment: attachment,
    );
  }

  /// Mark a chat as read (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> markChatAsRead({
    required int chatId,
  }) async {
    return ConsolidatedCommunicationService.markChatAsRead(chatId: chatId);
  }

  /// Toggle chat pin (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> toggleChatPin({
    required int chatId,
  }) async {
    return ConsolidatedCommunicationService.toggleChatPin(chatId: chatId);
  }

  /// Toggle chat mute (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> toggleChatMute({
    required int chatId,
  }) async {
    return ConsolidatedCommunicationService.toggleChatMute(chatId: chatId);
  }

  /// Get unread count across chats (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> getUnreadCount() async {
    return ConsolidatedCommunicationService.getUnreadCount();
  }

  /// Search chats (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> searchChats({
    required String query,
  }) async {
    return ConsolidatedCommunicationService.searchChats(query: query);
  }
}
