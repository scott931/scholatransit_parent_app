import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentAuthState = ref.watch(parentAuthProvider);
    final authState = ref.watch(authProvider);

    // Determine which provider is active based on state
    final isParentOtp = parentAuthState.otpId != null;
    final isDriverRegistrationOtp = authState.registrationEmail != null &&
        authState.otpId != null &&
        !authState.isAuthenticated;
    final isDriverLoginOtp = authState.otpId != null &&
        authState.registrationEmail == null;

    // Determine loading state from the active provider
    final isLoading = isParentOtp
        ? parentAuthState.isLoading
        : (authState.isLoading);

    // Listen for successful authentication and errors from parent auth provider
    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      // Check for successful authentication
      if (next.isAuthenticated && next.parent != null && mounted) {
        // Only navigate if we weren't already authenticated (to avoid duplicate navigations)
        if (previous == null || !previous.isAuthenticated || previous.parent == null) {
          print(
            '📱 DEBUG: Parent authentication successful, navigating to parent dashboard',
          );
          print('📱 DEBUG: Previous auth: ${previous?.isAuthenticated}, Next auth: ${next.isAuthenticated}');
          print('📱 DEBUG: Previous parent: ${previous?.parent?.id}, Next parent: ${next.parent?.id}');
          // Use a small delay to ensure state is fully settled
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              context.go('/parent/dashboard');
            }
          });
        }
        return;
      }
      // Show error messages
      if (next.error != null && next.error != previous?.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    // Listen for successful authentication and errors from driver auth provider
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Check for successful authentication
      if (next.isAuthenticated && next.driver != null && mounted) {
        // Only navigate if we weren't already authenticated (to avoid duplicate navigations)
        if (previous == null || !previous.isAuthenticated || previous.driver == null) {
          print(
            '📱 DEBUG: Driver authentication successful, navigating to driver dashboard',
          );
          print('📱 DEBUG: Previous auth: ${previous?.isAuthenticated}, Next auth: ${next.isAuthenticated}');
          print('📱 DEBUG: Previous driver: ${previous?.driver?.id}, Next driver: ${next.driver?.id}');
          // Use a small delay to ensure state is fully settled
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              context.go('/driver/dashboard');
            }
          });
        }
        return;
      }
      // Show error messages
      if (next.error != null && next.error != previous?.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'Verify your email',
                style: GoogleFonts.poppins(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A), // Dark blue
                ),
              ),

              SizedBox(height: 16.h),

              // Instructions
              Text(
                'Enter code we\'ve sent to your inbox',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'We\'ve sent a one-time password to your registered contact.',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 48.h),

              // OTP Input Fields
              Form(
                key: _formKey,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 52.w,
                      height: 64.h,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // We'll validate the complete OTP
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 32.h),

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t get the code? ',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend it.',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: isLoading
                            ? Colors.grey[400]
                            : const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 48.h),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryColor, // Professional blue (#0052cc)
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Collect all OTP digits
    String otpCode = '';
    for (var controller in _otpControllers) {
      otpCode += controller.text;
    }

    // Validate that all fields are filled
    if (otpCode.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Get current state from both providers
    final parentAuthState = ref.read(parentAuthProvider);
    final authState = ref.read(authProvider);

    // Decision logic: Determine which OTP provider to use based on state
    bool success = false;

    // Priority 1: Parent login OTP
    if (parentAuthState.otpId != null) {
      print('🔐 DEBUG: Using parent login OTP verification');
      success = await ref
          .read(parentAuthProvider.notifier)
          .verifyOtp(otpCode.trim());
    }
    // Priority 2: Driver registration OTP
    else if (authState.registrationEmail != null &&
        authState.otpId != null &&
        !authState.isAuthenticated) {
      print('🔐 DEBUG: Using driver registration OTP verification');
      // Try completeEmailRegistration first, then fallback to verifyRegisterOtp
      success = await ref
          .read(authProvider.notifier)
          .completeEmailRegistration(otpCode: otpCode.trim());
      
      if (!success && mounted) {
        // Fallback to verifyRegisterOtp if completeEmailRegistration fails
        print('🔐 DEBUG: completeEmailRegistration failed, trying verifyRegisterOtp');
        success = await ref
            .read(authProvider.notifier)
            .verifyRegisterOtp(otpCode: otpCode.trim());
      }
    }
    // Priority 3: Driver login OTP
    else if (authState.otpId != null && authState.registrationEmail == null) {
      print('🔐 DEBUG: Using driver login OTP verification');
      success = await ref
          .read(authProvider.notifier)
          .verifyLoginOtp(otpCode: otpCode.trim());
    }
    // No valid OTP state found
    else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active OTP session found. Please start the registration or login process again.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Handle success/failure
    if (!mounted) return;

    if (success) {
      // Check authentication state and navigate
      final updatedParentAuthState = ref.read(parentAuthProvider);
      final updatedAuthState = ref.read(authProvider);

      // Priority 1: Parent authentication
      if (updatedParentAuthState.isAuthenticated &&
          updatedParentAuthState.parent != null) {
        print('🔐 DEBUG: Parent OTP verified successfully, navigating to dashboard');
        // Small delay to ensure state is fully updated
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/parent/dashboard');
        }
        return;
      }
      // Priority 2: Driver authentication
      else if (updatedAuthState.isAuthenticated &&
          updatedAuthState.driver != null) {
        print('🔐 DEBUG: Driver OTP verified successfully, navigating to dashboard');
        // Small delay to ensure state is fully updated
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/driver/dashboard');
        }
        return;
      } else {
        // Success but not authenticated yet - wait a bit and check again
        print('⚠️ DEBUG: OTP verified but authentication state not updated yet');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          final finalParentAuthState = ref.read(parentAuthProvider);
          final finalAuthState = ref.read(authProvider);
          
          if (finalParentAuthState.isAuthenticated &&
              finalParentAuthState.parent != null) {
            context.go('/parent/dashboard');
          } else if (finalAuthState.isAuthenticated &&
              finalAuthState.driver != null) {
            context.go('/driver/dashboard');
          } else {
            print('❌ DEBUG: OTP verified but authentication state still not set');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'OTP verified but login failed. Please try again.',
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    } else {
      // Show error message if verification failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP code. Please check and try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// Resend OTP to the user's email
  Future<void> _resendOtp() async {
    if (!mounted) return;

    // Get current state from both providers
    final parentAuthState = ref.read(parentAuthProvider);
    final authState = ref.read(authProvider);

    // Determine which provider to use based on state
    final isParentOtp = parentAuthState.otpId != null;
    final isDriverRegistrationOtp = authState.registrationEmail != null &&
        authState.otpId != null &&
        !authState.isAuthenticated;
    final isDriverLoginOtp = authState.otpId != null &&
        authState.registrationEmail == null;

    // Priority 1: Parent login OTP
    if (isParentOtp) {
      final email = parentAuthState.registrationEmail;
      final otpId = parentAuthState.otpId;

      if (email == null || email.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email not found. Please start the login process again.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      print('🔐 DEBUG: Resending OTP for parent login');
      print('🔐 DEBUG: Email: $email');
      print('🔐 DEBUG: OTP ID: $otpId');

      // Call resend OTP API
      final success = await ref.read(parentAuthProvider.notifier).resendOtp(
            email: email,
            otpId: otpId?.toString(),
          );

      if (!mounted) return;

      if (success) {
        // Clear OTP input fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        // Focus on first field
        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP has been resent to your email. Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Error message is already shown by the provider listener
        // But we can show a generic message if needed
        final error = parentAuthState.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'Failed to resend OTP. Please try again.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
    // Priority 2: Driver registration OTP
    else if (isDriverRegistrationOtp) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Resend OTP for driver registration is not yet implemented.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    // Priority 3: Driver login OTP
    else if (isDriverLoginOtp) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Resend OTP for driver login is not yet implemented.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    // No valid OTP state found
    else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active OTP session found. Please start the login process again.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
