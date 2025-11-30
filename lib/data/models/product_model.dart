import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

// 1. Thêm Class Review
class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final String createdAt;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String name = 'Khách';
    
    // Ưu tiên lấy tên từ guestName (Backend mới thêm)
    if (json['guestName'] != null) {
        name = json['guestName'];
    }
    
    // Nếu có user object (đã populate) thì lấy fullName
    if (json['user'] != null) {
      if (json['user'] is Map) {
        name = json['user']['fullName'] ?? name;
      }
    }

    return Review(
      id: json['_id'] ?? '',
      userName: name,
      // Rating có thể null với khách
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 0.0 : 0.0, 
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
  
  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final date = DateTime.parse(createdAt);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '';
    }
  }
}

class ProductVariant {
  final String id;
  final String name; 
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
      // SỬA Ở ĐÂY: Ưu tiên lấy _id, nếu không có thì lấy id, cuối cùng là chuỗi rỗng
      id: json['_id'] ?? json['id'] ?? '', 
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
  final List<Review> reviews; // <--- Thêm trường này

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
    required this.reviews, // <--- Thêm vào constructor
  });

  int get displayPrice => variants.isNotEmpty ? variants[0].price : 0;

  String get salePriceText =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(displayPrice);

  String get thumbnailUrl => images.isNotEmpty
      ? AppConstants.getFullImageUrl(images[0])
      : AppConstants.getFullImageUrl(null);

  factory Product.fromJson(Map<String, dynamic> json) {
    String catName = 'Khác';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        catName = json['category']['name'] ?? '';
      } else if (json['category'] is String) {
        catName = 'Danh mục'; 
      }
    }

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Sản phẩm',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      categoryName: catName,
      images: List<String>.from(json['images'] ?? []),
      variants: (json['variants'] as List? ?? [])
          .map((v) => ProductVariant.fromJson(v))
          .toList(),
      averageRating: double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0,
      numReviews: int.tryParse(json['numReviews']?.toString() ?? '0') ?? 0,
      // Map list reviews từ JSON
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => Review.fromJson(r))
          .toList(),
    );
  }
}