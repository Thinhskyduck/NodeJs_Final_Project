import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';

class ProductVariant {
  final String id;
  final String name; // VD: "8GB/256GB"
  final int price;
  final int stockQuantity;

  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] is int)
          ? json['price']
          : int.tryParse(json['price'].toString()) ?? 0,
      stockQuantity: (json['stockQuantity'] is int)
          ? json['stockQuantity']
          : int.tryParse(json['stockQuantity'].toString()) ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String brand;
  final String categoryName;
  final List<String> images;
  final List<ProductVariant> variants;
  final double averageRating;
  final int numReviews;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.brand,
    required this.categoryName,
    required this.images,
    required this.variants,
    required this.averageRating,
    required this.numReviews,
  });

  // Helper lấy giá hiển thị (từ variant đầu tiên)
  int get displayPrice => variants.isNotEmpty ? variants[0].price : 0;

  String get salePriceText =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(displayPrice);

  // Helper lấy ảnh đại diện (xử lý qua AppConstants)
  String get thumbnailUrl => images.isNotEmpty
      ? AppConstants.getFullImageUrl(images[0])
      : AppConstants.getFullImageUrl(null);

  factory Product.fromJson(Map<String, dynamic> json) {
    // Xử lý category populate
    String catName = 'Khác';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        catName = json['category']['name'] ?? '';
      } else if (json['category'] is String) {
        catName = 'Danh mục'; // Trường hợp chưa populate
      }
    }

    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Sản phẩm',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '', // Backend bạn lưu brand là String
      categoryName: catName,
      images: List<String>.from(json['images'] ?? []),
      variants: (json['variants'] as List? ?? [])
          .map((v) => ProductVariant.fromJson(v))
          .toList(),
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      numReviews: int.tryParse(json['numReviews']?.toString() ?? '0') ?? 0,
    );
  }
}
