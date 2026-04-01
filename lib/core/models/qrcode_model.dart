class QrCodeInfo {
  final int id;
  final Map<String, dynamic> student;
  final String qrCodeData;
  final String qrCodeImage;
  final String qrCodeUrl;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QrCodeInfo({
    required this.id,
    required this.student,
    required this.qrCodeData,
    required this.qrCodeImage,
    required this.qrCodeUrl,
    required this.isActive,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QrCodeInfo.fromJson(Map<String, dynamic> json) {
    return QrCodeInfo(
      id: json['id'] ?? 0,
      student: json['student'] as Map<String, dynamic>? ?? const {},
      qrCodeData: json['qr_code_data']?.toString() ?? '',
      qrCodeImage: json['qr_code_image']?.toString() ?? '',
      qrCodeUrl: json['qr_code_url']?.toString() ?? '',
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'].toString())
          : DateTime.now(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }
}


