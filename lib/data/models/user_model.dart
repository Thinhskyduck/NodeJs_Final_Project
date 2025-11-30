class UserAddress {
  final String id;
  final String addressLine;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.addressLine,
    required this.city,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['_id'] ?? '',
      addressLine: json['addressLine'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final int loyaltyPoints;
  final String? token;
  final List<UserAddress> addresses; // <--- Đã thêm trường này

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.loyaltyPoints = 0,
    this.token,
    this.addresses = const [], // <--- Mặc định là mảng rỗng
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'User',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      loyaltyPoints: int.tryParse(json['loyaltyPoints']?.toString() ?? '0') ?? 0,
      token: json['token'],
      // Parse mảng địa chỉ từ JSON
      addresses: (json['addresses'] as List? ?? [])
          .map((item) => UserAddress.fromJson(item))
          .toList(),
    );
  }
}