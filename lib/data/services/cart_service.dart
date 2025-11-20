import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/cart_model.dart';

class CartService {
  final ApiService _apiService = ApiService();
  static const String _localCartKey = 'LOCAL_CART_DATA';

  // 1. Lấy giỏ hàng (Tự động chọn nguồn: API hoặc Local)
  Future<List<CartItem>> getCartItems() async {
    final user = await _apiService.getUserProfile();
    if (user != null) {
      // Đã đăng nhập -> Gọi API
      final cart = await _apiService.getCart();
      return cart?.items ?? [];
    } else {
      // Khách -> Lấy từ Local Storage
      return await _getLocalCart();
    }
  }

  // 2. Thêm vào giỏ hàng
  Future<bool> addToCart(String productId, String variantId, int quantity, 
      {required String name, required int price, required String image}) async {
    final user = await _apiService.getUserProfile();
    
    if (user != null) {
      // Đã đăng nhập -> Gọi API
      return await _apiService.addToCart(productId, variantId, quantity);
    } else {
      // Khách -> Lưu Local
      return await _addToLocalCart(productId, variantId, quantity, name, price, image);
    }
  }

  // 3. Xóa khỏi giỏ hàng
  Future<bool> removeItem(String itemId, {String? variantId}) async {
    final user = await _apiService.getUserProfile();
    if (user != null) {
      return await _apiService.removeCartItem(itemId);
    } else {
      // Với khách, itemId chính là variantId hoặc ta dùng logic tìm variantId
      return await _removeFromLocalCart(variantId ?? itemId);
    }
  }

  // --- LOGIC LOCAL STORAGE (CHO KHÁCH) ---
  Future<List<CartItem>> _getLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_localCartKey);
    if (cartJson == null) return [];

    List<dynamic> decoded = jsonDecode(cartJson);
    return decoded.map((item) => CartItem(
      itemId: item['variantId'], // Với local, dùng variantId làm ID tạm
      productId: item['productId'],
      variantId: item['variantId'],
      name: item['name'],
      quantity: item['quantity'],
      price: item['price'],
      image: item['image'],
    )).toList();
  }

  Future<bool> _addToLocalCart(String pId, String vId, int qty, String name, int price, String img) async {
    final prefs = await SharedPreferences.getInstance();
    List<CartItem> currentItems = await _getLocalCart();

    // Kiểm tra trùng
    int index = currentItems.indexWhere((i) => i.variantId == vId);
    if (index != -1) {
      // Đã có -> Tăng số lượng
      // (Logic đơn giản: xóa cũ thêm mới với qty tăng)
      int newQty = currentItems[index].quantity + qty;
      currentItems[index] = CartItem(itemId: vId, productId: pId, variantId: vId, name: name, quantity: newQty, price: price, image: img);
    } else {
      // Chưa có -> Thêm mới
      currentItems.add(CartItem(itemId: vId, productId: pId, variantId: vId, name: name, quantity: qty, price: price, image: img));
    }

    // Lưu lại
    List<Map<String, dynamic>> encoded = currentItems.map((i) => {
      'productId': i.productId,
      'variantId': i.variantId,
      'name': i.name,
      'quantity': i.quantity,
      'price': i.price,
      'image': i.image
    }).toList();
    
    await prefs.setString(_localCartKey, jsonEncode(encoded));
    return true;
  }

  Future<bool> _removeFromLocalCart(String variantId) async {
    final prefs = await SharedPreferences.getInstance();
    List<CartItem> currentItems = await _getLocalCart();
    
    currentItems.removeWhere((item) => item.variantId == variantId);
    
    List<Map<String, dynamic>> encoded = currentItems.map((i) => {
      'productId': i.productId,
      'variantId': i.variantId,
      'name': i.name,
      'quantity': i.quantity,
      'price': i.price,
      'image': i.image
    }).toList();
    
    await prefs.setString(_localCartKey, jsonEncode(encoded));
    return true;
  }
}