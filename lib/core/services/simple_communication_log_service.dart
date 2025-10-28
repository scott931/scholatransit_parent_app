import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/communication_log_model.dart';
import 'consolidated_communication_service.dart';

/// Legacy SimpleCommunicationLogService - now uses ConsolidatedCommunicationService internally
/// Maintains backward compatibility while using the improved implementation
class SimpleCommunicationLogService {
  /// Initialize the communication log service
  static Future<void> init() async {
    await ConsolidatedCommunicationService.init();
  }

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
    return ConsolidatedCommunicationService.logCommunication(
      phoneNumber: phoneNumber,
      contactName: contactName,
      type: type,
      success: success,
      message: message,
      errorMessage: errorMessage,
      studentName: studentName,
      driverId: driverId,
    );
  }

  /// Get all communication logs
  static List<CommunicationLog> getAllLogs() {
    return ConsolidatedCommunicationService.getAllLogs();
  }

  /// Get logs by type
  static List<CommunicationLog> getLogsByType(CommunicationType type) {
    return ConsolidatedCommunicationService.getLogsByType(type);
  }

  /// Get logs by date range
  static List<CommunicationLog> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return ConsolidatedCommunicationService.getLogsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get logs by phone number
  static List<CommunicationLog> getLogsByPhoneNumber(String phoneNumber) {
    return ConsolidatedCommunicationService.getLogsByPhoneNumber(phoneNumber);
  }

  /// Get successful logs only
  static List<CommunicationLog> getSuccessfulLogs() {
    return ConsolidatedCommunicationService.getSuccessfulLogs();
  }

  /// Get failed logs only
  static List<CommunicationLog> getFailedLogs() {
    return ConsolidatedCommunicationService.getFailedLogs();
  }

  /// Get communication statistics
  static Map<String, dynamic> getStatistics() {
    return ConsolidatedCommunicationService.getStatistics();
  }

  /// Clear all logs
  static Future<void> clearAllLogs() async {
    return ConsolidatedCommunicationService.clearAllLogs();
  }

  /// Delete a specific log
  static Future<void> deleteLog(String logId) async {
    return ConsolidatedCommunicationService.deleteLog(logId);
  }

  /// Get recent logs (last 10)
  static List<CommunicationLog> getRecentLogs({int limit = 10}) {
    return ConsolidatedCommunicationService.getRecentLogs(limit: limit);
  }

  /// Search logs by contact name or phone number
  static List<CommunicationLog> searchLogs(String query) {
    return ConsolidatedCommunicationService.searchLogs(query);
  }

  /// Force reload logs from storage
  static Future<void> reloadLogs() async {
    return ConsolidatedCommunicationService.reloadLogs();
  }

  /// Check if service is initialized
  static bool get isInitialized =>
      ConsolidatedCommunicationService.isInitialized;

  /// Get current log count
  static int get logCount => ConsolidatedCommunicationService.logCount;

  /// Add test logs for debugging (remove in production)
  static Future<void> addTestLogs() async {
    return ConsolidatedCommunicationService.addTestLogs();
  }
}
