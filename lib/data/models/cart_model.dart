import '../../core/constants/app_constants.dart';

class CartItem {
  final String itemId; // _id của item trong mảng items
  final String productId;
  final String variantId;
  final String name;
  final int quantity;
  final int price;
  final String image;

  CartItem({
    required this.itemId,
    required this.productId,
    required this.variantId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Xử lý an toàn cho variantId
    String vId = '';
    if (json['variant'] != null) {
      if (json['variant'] is String) {
        vId = json['variant'];
      } else if (json['variant'] is Map) {
        // Nếu backend đã populate variant thành object, lấy _id từ object đó
        vId = json['variant']['_id'] ?? json['variant']['id'] ?? '';
      }
    }

    // Xử lý an toàn cho productId
    String pId = '';
    if (json['product'] != null) {
      if (json['product'] is String) {
        pId = json['product'];
      } else if (json['product'] is Map) {
        pId = json['product']['_id'] ?? json['product']['id'] ?? '';
      }
    }

    return CartItem(
      itemId: json['_id'] ?? '',
      productId: pId,
      variantId: vId,
      name: json['name'] ?? 'Sản phẩm',
      quantity: json['quantity'] ?? 1,
      price: json['price'] ?? 0,
      image: AppConstants.getFullImageUrl(json['image']),
    );
  }
}

class Cart {
  final String id;
  final List<CartItem> items;
  final int totalPrice; // Backend có thể không trả về tổng, ta tự tính hoặc lấy nếu có

  Cart({required this.id, required this.items, this.totalPrice = 0});

  factory Cart.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<CartItem> cartItems = list.map((i) => CartItem.fromJson(i)).toList();
    
    // Tính tổng tiền client-side cho chắc chắn
    int total = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

    return Cart(
      id: json['_id'] ?? '',
      items: cartItems,
      totalPrice: total,
    );
  }
}