class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final int loyaltyPoints; // Thêm dòng này
  final String? token;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.loyaltyPoints = 0, // Mặc định là 0
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'User',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      // Parse an toàn cho số nguyên
      loyaltyPoints: int.tryParse(json['loyaltyPoints']?.toString() ?? '0') ?? 0,
      token: json['token'],
    );
  }
}