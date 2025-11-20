import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/services/api_service.dart';
import '../../4_checkout/screens/check_out_infor_screen.dart'; 
import '../../4_checkout/screens/checkout_screen.dart'; 
import '../../../data/services/cart_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
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

  Future<void> _removeItem(String itemId) async {
    final success = await _cartService.removeItem(itemId);
    if (success) _fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty // Sửa: Kiểm tra _items thay vì _cart
              ? const Center(child: Text("Giỏ hàng trống"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: _items.length, // Sửa: Dùng _items.length
                        separatorBuilder: (ctx, i) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final item = _items[index]; // Sửa: Lấy từ _items
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
      decoration: const BoxDecoration(
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
                NumberFormat("#,##0₫", "vi_VN").format(_totalPrice), // Sửa: Dùng _totalPrice
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (_items.isNotEmpty) { // Sửa: Kiểm tra _items
                // Truyền danh sách item và tổng tiền sang Checkout
                Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(
                  cartItems: _items, // Sửa: Truyền _items
                  totalPrice: _totalPrice, // Sửa: Truyền _totalPrice
                )));
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