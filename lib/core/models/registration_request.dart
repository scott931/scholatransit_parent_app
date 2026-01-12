class RegistrationRequest {
  final String username;
  final String email;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;
  final String userType;
  final String phoneNumber;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String source;
  final DeviceInfo deviceInfo;
  // Optional student linking fields for auto-matching
  final String? studentId;
  final String? studentEmail;
  final String? studentPhone;

  const RegistrationRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.phoneNumber,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.source,
    required this.deviceInfo,
    this.studentId,
    this.studentEmail,
    this.studentPhone,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'phone_number': phoneNumber,
      'address': address,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'source': source,
      'device_info': deviceInfo.toJson(),
    };
    
    // Add optional student linking fields if provided
    // These will be used by the backend for auto-matching
    final studentIdValue = studentId;
    if (studentIdValue != null && studentIdValue.isNotEmpty) {
      json['student_id'] = studentIdValue;
    }
    final studentEmailValue = studentEmail;
    if (studentEmailValue != null && studentEmailValue.isNotEmpty) {
      json['student_email'] = studentEmailValue;
    }
    final studentPhoneValue = studentPhone;
    if (studentPhoneValue != null && studentPhoneValue.isNotEmpty) {
      json['student_phone'] = studentPhoneValue;
    }
    
    return json;
  }

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    return RegistrationRequest(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      passwordConfirm: json['password_confirm'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      userType: json['user_type'] as String,
      phoneNumber: json['phone_number'] as String,
      address: json['address'] as String,
      emergencyContactName: json['emergency_contact_name'] as String,
      emergencyContactPhone: json['emergency_contact_phone'] as String,
      source: json['source'] as String,
      deviceInfo: DeviceInfo.fromJson(
        json['device_info'] as Map<String, dynamic>,
      ),
      studentId: json['student_id'] as String?,
      studentEmail: json['student_email'] as String?,
      studentPhone: json['student_phone'] as String?,
    );
  }
}

class DeviceInfo {
  final String userAgent;
  final String deviceType;

  const DeviceInfo({required this.userAgent, required this.deviceType});

  Map<String, dynamic> toJson() {
    return {'user_agent': userAgent, 'device_type': deviceType};
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      userAgent: json['user_agent'] as String,
      deviceType: json['device_type'] as String,
    );
  }
}
