import 'package:cross_platform_mobile_app_development/layout/header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Nếu chưa có, hãy thêm vào pubspec.yaml hoặc dùng TextStyle thường

import '../../../core/constants/app_constants.dart'; // Để dùng AppConstants.getFullImageUrl nếu cần
import '../../../data/models/cart_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../4_checkout/screens/check_out_infor_screen.dart';
import '../../5_profile/screens/profile_screen.dart'; // Để link tới Profile

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  List<CartItem> _items = [];
  bool _isLoading = true;
  int _totalPrice = 0;
  final ApiService _apiService = ApiService(); // Thêm service để lấy user info
  // Var cho Header
  Map<String, dynamic>? _currentUserData;
  final List<Map<String, dynamic>> _headerCategories = [{'name': 'Laptop', 'id': 'laptop'}, {'name': 'PC', 'id': 'pc'}];

  // Màu chủ đạo giống CellphoneS
  final Color _primaryRed = const Color(0xFFD70018);
  final Color _bgGray = const Color(0xFFF4F6F8);

  @override
  void initState() {
    super.initState();
    _fetchCart();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final user = await _apiService.getUserProfile();
    if (mounted && user != null) {
      setState(() => _currentUserData = {'full_name': user.fullName});
    }
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    // Giả lập delay nhẹ để tránh giật UI nếu load quá nhanh
    // await Future.delayed(const Duration(milliseconds: 300)); 
    
    final items = await _cartService.getCartItems();
    int total = items.fold(0, (sum, i) => sum + (i.price * i.quantity));

    if (mounted) {
      setState(() {
        _items = items;
        _totalPrice = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItem item, int change) async {
    // Gọi service update (dùng logic cũ: thêm 1 hoặc -1)
    await _cartService.addToCart(
      item.productId,
      item.variantId,
      change,
      name: item.name,
      price: item.price,
      image: item.image,
    );
    _fetchCart(); // Load lại để cập nhật giá tổng
  }

  Future<void> _removeItem(String itemId) async {
    // Show confirm dialog cho chuyên nghiệp
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa sản phẩm?"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _cartService.removeItem(itemId);
      if (success) _fetchCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _headerCategories,
          currentUserData: _currentUserData,
          cartItemCount: _items.length,
          onCartPressed: () {}, // Đang ở Cart rồi thì không làm gì
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryRed))
          : _items.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    // --- LIST ITEM ---
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          return _buildCartItemCard(_items[index]);
                        },
                      ),
                    ),
                    // --- BOTTOM BAR ---
                    _buildBottomBar(),
                  ],
                ),
    );
  }

  // Widget hiển thị khi giỏ hàng trống
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "Giỏ hàng của bạn đang trống",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Tiếp tục mua sắm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Widget hiển thị từng Item trong giỏ (Style Card hiện đại)
  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ảnh sản phẩm
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.white,
              child: _buildImage(item.image), // Hàm helper xử lý ảnh
            ),
          ),
          const SizedBox(width: 12),

          // 2. Thông tin chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tên & Nút xóa
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3),
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeItem(item.itemId),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Icon(Icons.close, size: 20, color: Colors.grey),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // Giá tiền
                Text(
                  NumberFormat("#,##0₫", "vi_VN").format(item.price),
                  style: TextStyle(color: _primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Bộ điều chỉnh số lượng
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: item.quantity > 1 ? () => _updateQuantity(item, -1) : null,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        "${item.quantity}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () => _updateQuantity(item, 1),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nút tăng giảm số lượng nhỏ gọn
  Widget _buildQuantityButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey[100] : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : Colors.black87),
      ),
    );
  }

  // Helper xử lý ảnh (Network hoặc Asset)
  Widget _buildImage(String url) {
    // Kích thước chuẩn cho thumbnail
    const double size = 90;
    
    if (url.startsWith('http')) {
      return Image.network(
        url, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset('assets/images/placeholder.png', width: size, height: size, fit: BoxFit.cover),
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset('assets/images/placeholder.png', width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/placeholder.png', width: size, height: size, fit: BoxFit.cover);
  }

  // Thanh thanh toán dưới cùng
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 16, 
        bottom: 16 + MediaQuery.of(context).padding.bottom
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dòng tổng tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng tạm tính:", style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(
                NumberFormat("#,##0₫", "vi_VN").format(_totalPrice),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryRed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nút Thanh toán Full Width
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (_items.isNotEmpty) {
                  final apiService = ApiService();
                  // Show loading nhẹ nếu cần
                  final user = await apiService.getUserProfile();

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutInfoScreen(
                        userId: user?.id ?? "",
                        currentUserData: user != null
                            ? {
                                'full_name': user.fullName,
                                'email': user.email,
                                'phone': '', 
                              }
                            : null,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giỏ hàng trống")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "TIẾN HÀNH ĐẶT HÀNG",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}