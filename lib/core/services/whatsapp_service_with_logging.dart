import 'package:url_launcher/url_launcher.dart';
import '../services/simple_communication_log_service.dart';
import '../models/communication_log_model.dart';
import 'consolidated_whatsapp_service.dart';

/// Legacy WhatsAppService with logging - now uses ConsolidatedWhatsAppService internally
/// Maintains backward compatibility while using the improved implementation
class WhatsAppService {
  /// Launch WhatsApp with a specific phone number
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    String? message,
    String? contactName,
    String? studentName,
  }) async {
    return ConsolidatedWhatsAppService.launchWhatsAppWithLogging(
      phoneNumber: phoneNumber,
      message: message,
      contactName: contactName,
      studentName: studentName,
    );
  }

  /// Launch WhatsApp with a pre-filled message
  static Future<bool> launchWhatsAppWithMessage({
    required String phoneNumber,
    required String message,
    String? contactName,
    String? studentName,
  }) async {
    return ConsolidatedWhatsAppService.launchWhatsAppWithMessage(
      phoneNumber: phoneNumber,
      message: message,
      contactName: contactName,
      studentName: studentName,
      enableLogging: true,
    );
  }

  /// Check if WhatsApp is available on the device
  static Future<bool> isWhatsAppAvailable() async {
    return ConsolidatedWhatsAppService.isWhatsAppAvailable();
  }

  /// Get default driver phone number
  static String getDefaultDriverPhone() {
    return ConsolidatedWhatsAppService.getDefaultDriverPhone();
  }

  /// Get default admin phone number
  static String getDefaultAdminPhone() {
    return ConsolidatedWhatsAppService.getDefaultAdminPhone();
  }

  /// Get default parent phone number
  static String getDefaultParentPhone() {
    return ConsolidatedWhatsAppService.getDefaultParentPhone();
  }

  /// Validate if a phone number is suitable for WhatsApp
  static bool isValidPhoneNumber(String phoneNumber) {
    return ConsolidatedWhatsAppService.isValidPhoneNumber(phoneNumber);
  }
}
