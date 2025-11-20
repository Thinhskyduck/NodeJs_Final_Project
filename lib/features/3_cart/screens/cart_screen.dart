import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/services/api_service.dart';
import '../../4_checkout/screens/check_out_infor_screen.dart'; // Để điều hướng sau này
import '../../4_checkout/screens/checkout_screen.dart'; // File mới tạo ở bước 3

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  Cart? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    final cart = await _apiService.getCart();
    if (mounted) {
      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(String itemId) async {
    final success = await _apiService.removeCartItem(itemId);
    if (success) {
      _fetchCart(); // Load lại giỏ sau khi xóa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa sản phẩm")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi khi xóa sản phẩm")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.items.isEmpty
              ? const Center(child: Text("Giỏ hàng trống"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _cart!.items.length,
                        separatorBuilder: (ctx, i) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final item = _cart!.items[index];
                          return ListTile(
                            leading: Image.network(
                              item.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.image),
                            ),
                            title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              "${NumberFormat("#,##0₫", "vi_VN").format(item.price)} x ${item.quantity}",
                              style: const TextStyle(color: Colors.red),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () => _removeItem(item.itemId),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tổng cộng:", style: TextStyle(fontSize: 14)),
              Text(
                NumberFormat("#,##0₫", "vi_VN").format(_cart?.totalPrice ?? 0),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
               // SỬA LẠI: Chuyển sang CheckoutScreen mới
               if (_cart != null && _cart!.items.isNotEmpty) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giỏ hàng trống")));
               }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text("THANH TOÁN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}