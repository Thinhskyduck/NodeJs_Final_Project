import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

class OrderItem {
  final String name;
  final int quantity;
  final int price;
  final String image;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? 'Sản phẩm',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      image: AppConstants.getFullImageUrl(json['image']),
    );
  }
}

class OrderModel {
  final String id;
  final int totalPrice;
  final String status; // pending, confirmed, shipping, delivered...
  final String date;
  final List<OrderItem> items;
  final String address;

  OrderModel({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.date,
    required this.items,
    required this.address,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var listItems = json['orderItems'] as List? ?? [];
    List<OrderItem> parsedItems = listItems.map((i) => OrderItem.fromJson(i)).toList();
    
    // Xử lý địa chỉ (Backend trả về object shippingAddress)
    String addrString = '';
    if (json['shippingAddress'] != null) {
      final addr = json['shippingAddress'];
      addrString = "${addr['addressLine']}, ${addr['city']}";
    }

    return OrderModel(
      id: json['_id'] ?? '',
      totalPrice: json['totalPrice'] ?? 0,
      status: json['status'] ?? 'pending',
      date: json['createdAt'] ?? DateTime.now().toString(),
      items: parsedItems,
      address: addrString,
    );
  }
  
  // Helper format ngày
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  // Helper format tiền
  String get formattedTotal => NumberFormat("#,##0₫", "vi_VN").format(totalPrice);
}