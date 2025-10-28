import 'package:url_launcher/url_launcher.dart';
import 'consolidated_whatsapp_service.dart';

/// Legacy WhatsAppService - now uses ConsolidatedWhatsAppService internally
/// Maintains backward compatibility while using the improved implementation
class WhatsAppService {
  /// Launch WhatsApp with a specific phone number
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    String? message,
    String? contactName,
    String? studentName,
  }) async {
    return ConsolidatedWhatsAppService.launchWhatsAppWithoutLogging(
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
  }) async {
    return ConsolidatedWhatsAppService.launchWhatsAppWithMessage(
      phoneNumber: phoneNumber,
      message: message,
      enableLogging: false,
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

  /// Check if phone number is valid for WhatsApp
  static bool isValidPhoneNumber(String phoneNumber) {
    return ConsolidatedWhatsAppService.isValidPhoneNumber(phoneNumber);
  }
}
