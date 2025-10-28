import 'package:flutter/services.dart';

class ContactService {
  static const MethodChannel _channel = MethodChannel('contact_service');

  /// Get all contacts from device
  static Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final List<dynamic> contacts = await _channel.invokeMethod('getContacts');
      return contacts.cast<Map<String, dynamic>>();
    } on PlatformException catch (e) {
      print('Error getting contacts: ${e.message}');
      return [];
    }
  }

  /// Search contacts by name
  static Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    try {
      final List<dynamic> contacts = await _channel.invokeMethod(
        'searchContacts',
        {'query': query},
      );
      return contacts.cast<Map<String, dynamic>>();
    } on PlatformException catch (e) {
      print('Error searching contacts: ${e.message}');
      return [];
    }
  }

  /// Get contact by phone number
  static Future<Map<String, dynamic>?> getContactByPhone(
    String phoneNumber,
  ) async {
    try {
      final Map<String, dynamic>? contact = await _channel.invokeMethod(
        'getContactByPhone',
        {'phoneNumber': phoneNumber},
      );
      return contact;
    } on PlatformException catch (e) {
      print('Error getting contact by phone: ${e.message}');
      return null;
    }
  }

  /// Add contact to device
  static Future<bool> addContact({
    required String name,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final bool success = await _channel.invokeMethod('addContact', {
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
      });
      return success;
    } on PlatformException catch (e) {
      print('Error adding contact: ${e.message}');
      return false;
    }
  }

  /// Update contact
  static Future<bool> updateContact({
    required String contactId,
    required String name,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final bool success = await _channel.invokeMethod('updateContact', {
        'contactId': contactId,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
      });
      return success;
    } on PlatformException catch (e) {
      print('Error updating contact: ${e.message}');
      return false;
    }
  }

  /// Delete contact
  static Future<bool> deleteContact(String contactId) async {
    try {
      final bool success = await _channel.invokeMethod('deleteContact', {
        'contactId': contactId,
      });
      return success;
    } on PlatformException catch (e) {
      print('Error deleting contact: ${e.message}');
      return false;
    }
  }

  /// Check if contact exists
  static Future<bool> contactExists(String phoneNumber) async {
    try {
      final bool exists = await _channel.invokeMethod('contactExists', {
        'phoneNumber': phoneNumber,
      });
      return exists;
    } on PlatformException catch (e) {
      print('Error checking contact existence: ${e.message}');
      return false;
    }
  }

  /// Get contact permissions
  static Future<bool> hasContactPermissions() async {
    try {
      final bool hasPermissions = await _channel.invokeMethod(
        'hasContactPermissions',
      );
      return hasPermissions;
    } on PlatformException catch (e) {
      print('Error checking contact permissions: ${e.message}');
      return false;
    }
  }

  /// Request contact permissions
  static Future<bool> requestContactPermissions() async {
    try {
      final bool granted = await _channel.invokeMethod(
        'requestContactPermissions',
      );
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting contact permissions: ${e.message}');
      return false;
    }
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final bool isDenied = await _channel.invokeMethod(
        'isPermissionPermanentlyDenied',
      );
      return isDenied;
    } on PlatformException catch (e) {
      print('Error checking permission status: ${e.message}');
      return false;
    }
  }

  /// Get contacts with phone numbers
  static Future<List<Map<String, dynamic>>> getContactsWithPhones() async {
    try {
      final List<dynamic> contacts = await _channel.invokeMethod(
        'getContactsWithPhones',
      );
      return contacts.cast<Map<String, dynamic>>();
    } on PlatformException catch (e) {
      print('Error getting contacts with phones: ${e.message}');
      return [];
    }
  }

  /// Get contact diagnostics
  static Future<Map<String, dynamic>> getContactDiagnostics() async {
    try {
      final Map<String, dynamic> diagnostics = await _channel.invokeMethod(
        'getContactDiagnostics',
      );
      return diagnostics;
    } on PlatformException catch (e) {
      print('Error getting contact diagnostics: ${e.message}');
      return {};
    }
  }

  /// Get contact display name
  static String getContactDisplayName(dynamic contact) {
    if (contact is Map<String, dynamic>) {
      final String? firstName = contact['firstName'];
      final String? lastName = contact['lastName'];

      if (firstName != null && lastName != null) {
        return '$firstName $lastName';
      } else if (firstName != null) {
        return firstName;
      } else if (lastName != null) {
        return lastName;
      } else {
        return 'Unknown Contact';
      }
    } else {
      // Handle flutter_contacts Contact type
      try {
        final name = contact.name;
        if (name.first.isNotEmpty && name.last.isNotEmpty) {
          return '${name.first} ${name.last}';
        } else if (name.first.isNotEmpty) {
          return name.first;
        } else if (name.last.isNotEmpty) {
          return name.last;
        } else {
          return 'Unknown Contact';
        }
      } catch (e) {
        return 'Unknown Contact';
      }
    }
  }

  /// Get primary phone number from contact
  static String getPrimaryPhoneNumber(dynamic contact) {
    if (contact is Map<String, dynamic>) {
      final List<dynamic>? phones = contact['phones'];
      if (phones != null && phones.isNotEmpty) {
        return phones.first.toString();
      }
      return '';
    } else {
      // Handle flutter_contacts Contact type
      try {
        final phones = contact.phones;
        if (phones.isNotEmpty) {
          return phones.first.number;
        }
        return '';
      } catch (e) {
        return '';
      }
    }
  }

  /// Format phone number
  static String formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return '';
    }

    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle Kenyan phone numbers
    if (cleaned.startsWith('254')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+254${cleaned.substring(1)}';
    } else if (cleaned.length == 9) {
      return '+254$cleaned';
    } else if (cleaned.startsWith('7')) {
      return '+254$cleaned';
    }

    return phoneNumber;
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      print('Error opening app settings: ${e.message}');
    }
  }

  /// Check if has permission (alias for hasContactPermissions)
  static Future<bool> hasPermission() async {
    return hasContactPermissions();
  }

  /// Request permission (alias for requestContactPermissions)
  static Future<bool> requestPermission() async {
    return requestContactPermissions();
  }
}
