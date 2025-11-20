import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart'; // Nhớ import CartModel
import '../models/order_model.dart'; // Import OrderModel

// Class hỗ trợ cho Search UI (Auto complete)
class ProductListItem {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String price;
  ProductListItem({required this.id, required this.name, required this.thumbnailUrl, required this.price});
}

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- AUTH ---
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/login'),
        headers: await _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final user = UserModel.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        if (user.token != null) {
          await prefs.setString(AppConstants.tokenKey, user.token!);
          await prefs.setString(AppConstants.userIdKey, user.id);
          await prefs.setString('user_fullName', user.fullName);
          await prefs.setString('user_email', user.email);
        }
        return user;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    // Code register cũ...
    return true; 
  }

  // --- PRODUCTS ---
  Future<List<Product>> fetchProducts({int limit = 20, String? search, String? sortBy, int? categoryId }) async {
    try {
      String query = 'limit=$limit';
      if (search != null) query += '&keyword=$search';
      if (sortBy != null) query += '&sort=$sortBy';
      if (categoryId != null) query += '&categoryId=$categoryId';
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products?$query'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> list = [];
        if (data is Map && data.containsKey('products')) list = data['products'];
        else if (data is List) list = data;
        return list.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch products error: $e');
      return [];
    }
  }

  Future<Product?> getProductDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/products/$id'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get detail error: $e');
      return null;
    }
  }

  // --- SUPPORT METHODS CHO CODE CŨ (Fix lỗi biên dịch) ---
  Future<List<Product>> fetchNewestProducts({int limit = 10}) => fetchProducts(limit: limit);
  Future<List<Product>> fetchBestSellingProducts({int limit = 10}) => fetchProducts(limit: limit);
  Future<List<Product>> fetchPromotionalProducts({int limit = 10}) => fetchProducts(limit: limit);
  
  Future<List<ProductListItem>> fetchProductSuggestions(String query, {int limit = 5}) async {
    final products = await fetchProducts(search: query, limit: limit);
    return products.map((p) => ProductListItem(
      id: p.id, 
      name: p.name, 
      thumbnailUrl: p.thumbnailUrl ?? '', 
      price: p.salePriceText
    )).toList();
  }

  Future<List<dynamic>> getProductReviews(String productId) async {
    return []; // Trả về list rỗng
  }
  // --- USER PROFILE ---
  // Hàm này dùng để kiểm tra token còn hạn không và lấy thông tin user
  Future<UserModel?> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      // Kiểm tra xem có token chưa, nếu chưa có thì return null luôn (Khách)
      if (!headers.containsKey('Authorization')) return null;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserModel.fromJson(data);
      } else {
        // Token hết hạn hoặc lỗi -> Xóa token để logout
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); 
        return null;
      }
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // Hàm đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  // 1. Lấy giỏ hàng
  Future<Cart?> getCart() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/cart'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Backend trả về object Cart trực tiếp hoặc { items: [], ... }
        return Cart.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get cart error: $e');
      return null;
    }
  }

  // 2. Thêm vào giỏ (hoặc cập nhật số lượng)
  Future<bool> addToCart(String productId, String variantId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/cart'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'productId': productId, // Backend yêu cầu productId
          'variantId': variantId, // Backend yêu cầu variantId
          'quantity': quantity
        }),
      );
      
      // Backend trả về 200 hoặc 201 đều OK
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Add cart error: $e');
      return false;
    }
  }

  // 3. Xóa sản phẩm khỏi giỏ
  Future<bool> removeCartItem(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/cart/items/$itemId'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Remove item error: $e');
      return false;
    }
  }
  
  // 1. Tạo đơn hàng
  Future<bool> createOrder({
    required String addressLine, 
    required String city, 
    required String phone,
    String paymentMethod = 'COD'
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'shippingAddress': {
          'addressLine': addressLine,
          'city': city,
          'postalCode': '70000', // Hardcode hoặc cho nhập
          'country': 'Vietnam'
        },
        'paymentMethod': paymentMethod,
        // Backend có thể cần discountCode hoặc useLoyaltyPoints, tạm thời để default
        'useLoyaltyPoints': false
      });

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/orders'),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Create order error: $e');
      return false;
    }
  }

  // 2. Lấy danh sách đơn hàng
  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/orders/myorders'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Backend trả về List trực tiếp
        if (data is List) {
          return data.map((e) => OrderModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get my orders error: $e');
      return [];
    }
  }

  // --- GUEST CHECKOUT ---
  Future<bool> createGuestOrder({
    required String fullName,
    required String email,
    required String addressLine,
    required String city,
    required String phone,
    required List<Map<String, dynamic>> cartItems, // Frontend tự truyền list item
    String paymentMethod = 'COD',
  }) async {
    try {
      // Vì khách chưa đăng nhập nên không có headers chứa Token
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

      final body = jsonEncode({
        'fullName': fullName,
        'email': email,
        'shippingAddress': {
          'addressLine': addressLine,
          'city': city,
          'postalCode': '700000', // Hardcode hoặc cho nhập
          'country': 'Vietnam'
        },
        'paymentMethod': paymentMethod,
        'cartItems': cartItems, // [ { product: "id", variant: "id", quantity: 1, price: 10000 }, ... ]
      });

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/orders/guest'),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Create guest order error: $e');
      return false;
    }
  }
}