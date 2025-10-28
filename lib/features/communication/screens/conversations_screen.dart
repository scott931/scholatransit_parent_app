import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/whatsapp_service_with_logging.dart';
import '../../../core/services/phone_call_service.dart';
import '../../../core/services/simple_communication_log_service.dart';
import '../../../core/services/contact_service.dart';
import '../../../core/widgets/contact_picker_widget.dart';
import '../../../core/models/communication_log_model.dart';
import 'communication_log_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with TickerProviderStateMixin {
  bool _isCreating = false;
  final TextEditingController _parentPhoneController = TextEditingController();
  List<CommunicationLog> _recentLogs = [];
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecentLogs();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _parentPhoneController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentLogs() async {
    try {
      // Ensure service is initialized
      if (!SimpleCommunicationLogService.isInitialized) {
        await SimpleCommunicationLogService.init();
      }

      // Force reload from storage
      await SimpleCommunicationLogService.reloadLogs();
      final recentLogs = SimpleCommunicationLogService.getRecentLogs(limit: 5);

      if (mounted) {
        setState(() {
          _recentLogs = recentLogs;
        });
      }
    } catch (e) {
      print('Error loading recent logs: $e');
    }
  }

  Future<void> _createChatWithParent() async {
    if (_isCreating) return;

    // Show dialog to input parent phone number
    final phoneNumber = await _showParentPhoneDialog();
    if (phoneNumber == null) return; // User cancelled

    setState(() => _isCreating = true);
    await _launchWhatsAppWithParentPhone(phoneNumber);
    setState(() => _isCreating = false);
  }

  Future<String?> _showParentPhoneDialog() async {
    _parentPhoneController.clear();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Parent',
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter parent\'s phone number to start WhatsApp chat',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Phone input field with contact picker
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _parentPhoneController,
                                keyboardType: TextInputType.phone,
                                onChanged: (value) {
                                  // Auto-add +254 prefix for Kenyan numbers
                                  if (value.isNotEmpty &&
                                      !value.startsWith('+')) {
                                    if (value.startsWith('254')) {
                                      _parentPhoneController.text = '+$value';
                                      _parentPhoneController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _parentPhoneController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    } else if (value.startsWith('0') &&
                                        value.length > 1) {
                                      // Convert 07xxxxxxxx to +2547xxxxxxxx
                                      String newValue =
                                          '+254${value.substring(1)}';
                                      _parentPhoneController.text = newValue;
                                      _parentPhoneController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _parentPhoneController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    } else if (value.length >= 9 &&
                                        !value.startsWith('+')) {
                                      // Auto-add +254 for 9+ digit numbers
                                      String newValue = '+254$value';
                                      _parentPhoneController.text = newValue;
                                      _parentPhoneController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _parentPhoneController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    }
                                  }
                                },
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g., 0712345678 or +254712345678',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Container(
                                    padding: EdgeInsets.all(12.w),
                                    child: Icon(
                                      Icons.phone_outlined,
                                      color: const Color(0xFF10B981),
                                      size: 20.w,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Contact picker button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _showContactPicker,
                              icon: const Icon(
                                Icons.contacts,
                                color: Colors.white,
                              ),
                              tooltip: 'Pick from contacts',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Help text
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF0EA5E9),
                              size: 16.w,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Enter phone number manually or tap the contacts button to pick from your contacts.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF0369A1),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Action buttons with modern design
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final phone = _parentPhoneController.text
                                      .trim();
                                  if (phone.isNotEmpty) {
                                    Navigator.of(context).pop(phone);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat, size: 18.w),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Start Chat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCallParentDialog() async {
    _parentPhoneController.clear();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Call Parent',
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter parent\'s phone number to make a call',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Phone input field with contact picker
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _parentPhoneController,
                                keyboardType: TextInputType.phone,
                                onChanged: (value) {
                                  // Auto-add +254 prefix for Kenyan numbers
                                  if (value.isNotEmpty &&
                                      !value.startsWith('+')) {
                                    if (value.startsWith('254')) {
                                      _parentPhoneController.text = '+$value';
                                      _parentPhoneController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _parentPhoneController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    } else if (value.startsWith('0') &&
                                        value.length > 1) {
                                      // Convert 07xxxxxxxx to +2547xxxxxxxx
                                      String newValue =
                                          '+254${value.substring(1)}';
                                      _parentPhoneController.text = newValue;
                                      _parentPhoneController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _parentPhoneController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    } else if (value.length >= 9 &&
                                        !value.startsWith('+')) {
                                      // Auto-add +254 for 9+ digit numbers
                                      String newValue = '+254$value';
                                      _parentPhoneController.text = newValue;
                                      _parentPhoneController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _parentPhoneController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    }
                                  }
                                },
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'e.g., 0712345678 or +254712345678',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  labelStyle: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Container(
                                    padding: EdgeInsets.all(12.w),
                                    child: Icon(
                                      Icons.phone_outlined,
                                      color: const Color(0xFF10B981),
                                      size: 20.w,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Contact picker button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _showContactPicker,
                              icon: const Icon(
                                Icons.contacts,
                                color: Colors.white,
                              ),
                              tooltip: 'Pick from contacts',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Help text
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF0EA5E9),
                              size: 16.w,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Enter phone number manually or tap the contacts button to pick from your contacts.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF0369A1),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Action buttons with modern design
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final phone = _parentPhoneController.text
                                      .trim();
                                  if (phone.isNotEmpty) {
                                    Navigator.of(context).pop(phone);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone, size: 18.w),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Make Call',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((phoneNumber) {
      if (phoneNumber != null) {
        _makePhoneCall(phoneNumber);
      }
    });
  }

  void _showContactPicker() {
    showDialog(
      context: context,
      builder: (context) => ContactPickerWidget(
        title: 'Select Contact',
        hintText: 'Search contacts...',
        onContactSelected: (Map<String, dynamic> contactData) {
          // Handle contact selection
          final phoneNumber = contactData['phone'] ?? '';
          final formattedPhone = ContactService.formatPhoneNumber(phoneNumber);
          _parentPhoneController.text = formattedPhone;
        },
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      if (!PhoneCallService.isValidPhoneNumber(phoneNumber)) {
        _showInvalidPhoneDialog();
        return;
      }

      final success = await PhoneCallService.makePhoneCall(
        phoneNumber: phoneNumber,
        contactName: 'Parent',
        studentName: 'Student',
      );

      if (!success && mounted) {
        _showPhoneCallErrorDialog();
      } else if (success) {
        // Refresh recent logs after successful call
        _loadRecentLogs();
      }
    } catch (e) {
      if (mounted) {
        _showPhoneCallErrorDialog();
      }
    }
  }

  void _showPhoneCallErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Make Call'),
        content: const Text(
          'There was an error making the phone call. Please make sure your device supports phone calls and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsAppWithParentPhone(String phoneNumber) async {
    try {
      String message =
          'Hello! this is Go Drop Parents app regarding your child';

      if (!WhatsAppService.isValidPhoneNumber(phoneNumber)) {
        _showInvalidPhoneDialog();
        return;
      }

      // Skip availability check and try to launch directly

      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: phoneNumber,
        message: message,
        contactName: 'Parent',
        studentName: 'Student',
      );

      if (!success && mounted) {
        // Show a more helpful error message
        _showWhatsAppLaunchErrorDialog();
      } else if (success) {
        print('WhatsApp launched successfully');
      }
    } catch (e) {
      if (mounted) {
        _showWhatsAppLaunchErrorDialog();
      }
    }
  }

  Future<void> _createChatWithAdmin() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    // Launch WhatsApp with admin instead of creating a chat
    await _launchWhatsAppWithAdmin();

    setState(() => _isCreating = false);
  }

  Future<void> _launchWhatsAppWithAdmin() async {
    try {
      // Use admin phone number
      String phoneNumber = WhatsAppService.getDefaultAdminPhone();
      String message = 'Hello! this is Go Drop Parents app';

      // Check if phone number is valid
      if (!WhatsAppService.isValidPhoneNumber(phoneNumber)) {
        _showInvalidPhoneDialog();
        return;
      }

      // Launch WhatsApp
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (!success && mounted) {
        _showWhatsAppErrorDialog();
      }
    } catch (e) {
      if (mounted) {
        _showWhatsAppErrorDialog();
      }
    }
  }

  void _showInvalidPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Phone Number'),
        content: const Text(
          'The parent\'s phone number is not available or invalid. Please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp Not Available'),
        content: const Text(
          'WhatsApp is not installed on this device. Please install WhatsApp to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppLaunchErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Launch WhatsApp'),
        content: const Text(
          'There was an error launching WhatsApp. Please make sure WhatsApp is installed on your device and try again. If WhatsApp is installed, try restarting the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverToBoxAdapter(child: _buildBody()),
          ),
        ],
      ),
      floatingActionButton: _buildModernFloatingActionButton(),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 220.h,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.1),
                const Color(0xFF1E40AF).withOpacity(0.05),
                const Color(0xFF1E3A8A).withOpacity(0.02),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          color: const Color(0xFF3B82F6),
                          size: 32.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Messages',
                              style: GoogleFonts.poppins(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Stay connected with parents and admin',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'ONLINE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _buildFilterChips(),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunicationLogScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history, color: Color(0xFF3B82F6)),
            tooltip: 'View Communication Log',
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/contact-demo');
            },
            icon: const Icon(Icons.contacts, color: Color(0xFF10B981)),
            tooltip: 'Contact Picker Demo',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
      {'key': 'parents', 'label': 'Parents', 'icon': Icons.family_restroom},
      {'key': 'admin', 'label': 'Admin', 'icon': Icons.admin_panel_settings},
      {'key': 'recent', 'label': 'Recent', 'icon': Icons.schedule},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Container(
              margin: EdgeInsets.only(right: 8.w),
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                },
                label: Text(
                  filter['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                avatar: Icon(
                  filter['icon'] as IconData,
                  size: 16.w,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF3B82F6),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModernFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showNewMessageOptions,
        backgroundColor: const Color(0xFF3B82F6),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 28.w),
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 80.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions Section
              _buildQuickActionsSection(),
              SizedBox(height: 24.h),

              // Recent Communications Section
              if (_recentLogs.isNotEmpty) ...[
                _buildRecentCommunicationsSection(),
                SizedBox(height: 24.h),
              ],

              // Communication Channels
              _buildCommunicationChannels(),
              SizedBox(height: 24.h),

              // Contact Options
              _buildContactOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildModernActionCard(
                icon: Icons.family_restroom,
                title: 'Contact Parent',
                subtitle: 'WhatsApp or Call',
                color: const Color(0xFF10B981),
                onTap: _createChatWithParent,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildModernActionCard(
                icon: Icons.admin_panel_settings,
                title: 'Contact Admin',
                subtitle: 'Support & Help',
                color: const Color(0xFF3B82F6),
                onTap: _createChatWithAdmin,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildModernActionCard(
                icon: Icons.phone,
                title: 'Make Call',
                subtitle: 'Direct Phone Call',
                color: const Color(0xFF8B5CF6),
                onTap: _showCallParentDialog,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildModernActionCard(
                icon: Icons.emergency,
                title: 'Emergency',
                subtitle: 'Urgent Contact',
                color: const Color(0xFFFF6B6B),
                onTap: _showEmergencyDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreating ? null : onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.w),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (_isCreating) ...[
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunicationChannels() {
    final channels = [
      {
        'type': 'whatsapp',
        'label': 'WhatsApp',
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF25D366),
        'description': 'Quick messaging with parents and admin',
      },
      {
        'type': 'phone',
        'label': 'Phone Call',
        'icon': Icons.phone_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'Direct voice communication',
      },
      {
        'type': 'email',
        'label': 'Email',
        'icon': Icons.email_rounded,
        'color': const Color(0xFF8B5CF6),
        'description': 'Formal communication channel',
      },
      {
        'type': 'sms',
        'label': 'SMS',
        'icon': Icons.sms_rounded,
        'color': const Color(0xFFFFB347),
        'description': 'Text messaging service',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Channels',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.8,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return _buildCommunicationChannelCard(
              context: context,
              type: channel['type'] as String,
              label: channel['label'] as String,
              icon: channel['icon'] as IconData,
              color: channel['color'] as Color,
              description: channel['description'] as String,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunicationChannelCard({
    required BuildContext context,
    required String type,
    required String label,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return GestureDetector(
      onTap: () => _handleChannelTap(context, type),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 16.w),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOptions() {
    final contacts = [
      {
        'icon': Icons.directions_bus_rounded,
        'label': 'Driver',
        'number': '+254 712 345 678',
        'color': const Color(0xFF3B82F6),
        'type': 'driver',
      },
      {
        'icon': Icons.admin_panel_settings_rounded,
        'label': 'School Admin',
        'number': '+254 723 456 789',
        'color': const Color(0xFFFFB347),
        'type': 'admin',
      },
      {
        'icon': Icons.school_rounded,
        'label': 'School Office',
        'number': '+254 734 567 890',
        'color': const Color(0xFF8B5CF6),
        'type': 'office',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Options',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 16.h),
        ...contacts.map(
          (contact) => _buildContactItem(
            icon: contact['icon'] as IconData,
            label: contact['label'] as String,
            number: contact['number'] as String,
            color: contact['color'] as Color,
            type: contact['type'] as String,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String number,
    required Color color,
    required String type,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _handleContactTap(type),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: color,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.phone, color: Colors.white, size: 18.w),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleContactTap(String type) {
    switch (type) {
      case 'driver':
        _createChatWithParent();
        break;
      case 'admin':
        _createChatWithAdmin();
        break;
      case 'office':
        _showCallParentDialog();
        break;
    }
  }

  Widget _buildRecentCommunicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunicationLogScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ..._recentLogs.take(3).map((log) => _buildSimpleLogCard(log)),
      ],
    );
  }

  Widget _buildSimpleLogCard(CommunicationLog log) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: _getTypeColor(log.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(log.type.icon, style: TextStyle(fontSize: 12.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.contactName,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _formatDateTime(log.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: log.success
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(CommunicationType type) {
    switch (type) {
      case CommunicationType.call:
        return const Color(0xFF10B981);
      case CommunicationType.whatsapp:
        return const Color(0xFF25D366);
      case CommunicationType.sms:
        return const Color(0xFF3B82F6);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleChannelTap(BuildContext context, String type) {
    switch (type) {
      case 'whatsapp':
        _showWhatsAppOptions(context);
        break;
      case 'phone':
        _showPhoneOptions(context);
        break;
      case 'email':
        _showEmailOptions(context);
        break;
      case 'sms':
        _showSMSOptions(context);
        break;
    }
  }

  void _showNewMessageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start New Conversation',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20.h),
            _buildModalOption(
              context,
              'Contact Parent',
              Icons.family_restroom,
              const Color(0xFF10B981),
              () {
                Navigator.pop(context);
                _createChatWithParent();
              },
            ),
            SizedBox(height: 12.h),
            _buildModalOption(
              context,
              'Contact Admin',
              Icons.admin_panel_settings,
              const Color(0xFF3B82F6),
              () {
                Navigator.pop(context);
                _createChatWithAdmin();
              },
            ),
            SizedBox(height: 12.h),
            _buildModalOption(
              context,
              'Make Phone Call',
              Icons.phone,
              const Color(0xFF8B5CF6),
              () {
                Navigator.pop(context);
                _showCallParentDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 20.w),
              ),
              SizedBox(width: 16.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWhatsAppOptions(BuildContext context) {
    _showNewMessageOptions();
  }

  void _showPhoneOptions(BuildContext context) {
    _showCallParentDialog();
  }

  void _showEmailOptions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email feature coming soon'),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showSMSOptions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('SMS feature coming soon'),
        backgroundColor: const Color(0xFFFFB347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.emergency_rounded,
              color: const Color(0xFFFF6B6B),
              size: 24.w,
            ),
            SizedBox(width: 12.w),
            Text(
              'Emergency Contact',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'This will immediately contact emergency services and school administration.',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Emergency contact initiated'),
                  backgroundColor: const Color(0xFFFF6B6B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('Contact Emergency'),
          ),
        ],
      ),
    );
  }
}
