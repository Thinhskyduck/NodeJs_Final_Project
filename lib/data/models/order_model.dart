import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';

// Class con để lưu lịch sử trạng thái
class OrderStatusHistory {
  final String status;
  final String updatedAt;

  OrderStatusHistory({required this.status, required this.updatedAt});

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status'] ?? '',
      updatedAt: json['updatedAt'] ?? DateTime.now().toString(),
    );
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(updatedAt).toLocal(); // Chuyển sang giờ địa phương
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return updatedAt;
    }
  }
  
  // Helper để hiển thị tiếng Việt
  String get statusVietnamese {
    switch (status.toLowerCase()) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'shipping': return 'Đang giao hàng';
      case 'delivered': return 'Đã giao hàng';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}

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
  final String status;
  final String date;
  final List<OrderItem> items;
  final String address;
  final List<OrderStatusHistory> statusHistory; // <--- MỚI THÊM

  OrderModel({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.date,
    required this.items,
    required this.address,
    required this.statusHistory, // <--- MỚI THÊM
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var listItems = json['orderItems'] as List? ?? [];
    List<OrderItem> parsedItems = listItems.map((i) => OrderItem.fromJson(i)).toList();
    
    // Parse status history
    var listHistory = json['statusHistory'] as List? ?? [];
    List<OrderStatusHistory> parsedHistory = listHistory.map((h) => OrderStatusHistory.fromJson(h)).toList();
    
    // Sắp xếp lịch sử: Mới nhất lên đầu (Reverse chronological order)
    parsedHistory.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

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
      statusHistory: parsedHistory, // <--- MỚI THÊM
    );
  }
  
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  String get formattedTotal => NumberFormat("#,##0₫", "vi_VN").format(totalPrice);
}