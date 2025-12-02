import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/models/registration_request.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:io' show Platform;

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController(); // For digits after +254
  final _addressController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyPhoneNumberController = TextEditingController(); // For digits after +254
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  final String _userType = 'parent';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyPhoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(parentAuthProvider);

    // Listen for errors
    ref.listen<ParentAuthState>(parentAuthProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              // Title and Description
              Text(
                'Register your account!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create your account to start using Go Drop Parents and track your child\'s transportation',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),

              SizedBox(height: 32.h),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username Field
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // First Name Field
                    _buildInputField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Last Name Field
                    _buildInputField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Phone Number Field
                    _buildPhoneInputField(
                      controller: _phoneNumberController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      hintText: 'e.g. 712345678',
                      validator: (value) {
                        if (value == null || value.isEmpty || value == '+254') {
                          return 'Please enter your phone number';
                        }
                        if (!value.startsWith('+254')) {
                          return 'Phone number must start with +254';
                        }
                        // Check if there are at least 9 digits after +254 (Kenyan format)
                        final digits = value.replaceAll('+254', '').replaceAll(' ', '');
                        if (digits.length < 9) {
                          return 'Please enter a valid 9-digit phone number';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
                          return 'Phone number must contain only digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Address Field
                    _buildInputField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      keyboardType: TextInputType.streetAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Emergency Contact Name Field
                    _buildInputField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      icon: Icons.emergency_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter emergency contact name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Emergency Contact Phone Field
                    _buildPhoneInputField(
                      controller: _emergencyPhoneNumberController,
                      label: 'Emergency Contact Phone',
                      icon: Icons.phone_outlined,
                      hintText: 'e.g. 712345678',
                      validator: (value) {
                        if (value == null || value.isEmpty || value == '+254') {
                          return 'Please enter emergency contact phone';
                        }
                        if (!value.startsWith('+254')) {
                          return 'Phone number must start with +254';
                        }
                        // Check if there are at least 9 digits after +254 (Kenyan format)
                        final digits = value.replaceAll('+254', '').replaceAll(' ', '');
                        if (digits.length < 9) {
                          return 'Please enter a valid 9-digit phone number';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
                          return 'Phone number must contain only digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Password Field
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(
                          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
                        ).hasMatch(value)) {
                          return 'Password must contain uppercase, lowercase, number and special character';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Confirm Password Field
                    _buildInputField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),

                    // Terms and Conditions (Required)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Make the checkbox highly visible and easier to tap
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: _agreeToTerms
                                  ? AppTheme.primaryColor
                                  : AppTheme.errorColor,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'By creating an account, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_agreeToTerms)
                      Padding(
                        padding: EdgeInsets.only(left: 40.w, top: 4.h),
                        child: Text(
                          'You must accept the terms and conditions to continue',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.errorColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    SizedBox(height: 24.h),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: (authState.isLoading || !_agreeToTerms)
                            ? null
                            : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          elevation: 0,
                        ),
                        child: authState.isLoading
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
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Footer
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
      ),
    );
  }

  Widget _buildPhoneInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Icon
              Padding(
                padding: EdgeInsets.only(left: 16.w),
                child: Icon(icon, color: Colors.grey[600]),
              ),
              SizedBox(width: 12.w),
              // Fixed +254 prefix (non-editable)
              Text(
                '+254',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              // Phone number input (digits only)
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9), // Max 9 digits for Kenyan format
                  ],
                  validator: (value) {
                    // Combine +254 with the input value for validation
                    final fullNumber = '+254${value ?? ''}';
                    return validator?.call(fullNumber);
                  },
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    // Terms and conditions are mandatory - button is disabled if not accepted
    // This check is redundant but kept for extra safety
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must accept the Terms and Conditions to create an account',
          ),
          backgroundColor: AppTheme.errorColor,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Combine +254 prefix with phone number digits
      final phoneNumber = '+254${_phoneNumberController.text.trim()}';
      final emergencyPhone = '+254${_emergencyPhoneNumberController.text.trim()}';
      
      final registrationRequest = RegistrationRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _confirmPasswordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        userType: _userType,
        phoneNumber: phoneNumber,
        address: _addressController.text.trim(),
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: emergencyPhone,
        source: 'mobile',
        deviceInfo: DeviceInfo(
          userAgent: 'Flutter (${Platform.operatingSystem})',
          deviceType: 'mobile',
        ),
      );

      final success = await ref
          .read(parentAuthProvider.notifier)
          .registerWithOtp(registrationRequest);

      if (mounted) {
        if (success) {
          context.go('/otp');
        }
      }
    }
  }
}
