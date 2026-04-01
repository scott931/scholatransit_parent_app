class PinInfo {
  final int id;
  final Map<String, dynamic> student;
  /// Returned for authenticated parent/school users (plain digits).
  final String? pinCode;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int usageCount;
  final int failedAttempts;
  final String? lockedUntil;
  final bool isValid;

  const PinInfo({
    required this.id,
    required this.student,
    this.pinCode,
    required this.isActive,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.usageCount,
    required this.failedAttempts,
    this.lockedUntil,
    required this.isValid,
  });

  factory PinInfo.fromJson(Map<String, dynamic> json) {
    return PinInfo(
      id: json['id'] ?? 0,
      student: json['student'] as Map<String, dynamic>? ?? const {},
      pinCode: json['pin_code']?.toString(),
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'].toString())
          : DateTime.now(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      usageCount: json['usage_count'] ?? 0,
      failedAttempts: json['failed_attempts'] ?? 0,
      lockedUntil: json['locked_until']?.toString(),
      isValid: json['is_valid'] ?? false,
    );
  }
}


