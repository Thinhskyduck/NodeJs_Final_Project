import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/services/api_service.dart';
import '../features/2_product/screens/product_detail.dart';

class CustomHeader extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? currentUserData;
  final int cartItemCount;
  final VoidCallback? onCartPressed;
  final VoidCallback? onAccountPressed;
  final VoidCallback? onLogoTap; // Thêm callback này
  
  const CustomHeader({
    super.key,
    required this.categories,
    this.currentUserData,
    this.cartItemCount = 0,
    this.onCartPressed,
    this.onAccountPressed,
    this.onLogoTap,
    dynamic onCategorySelected, // Chấp nhận dynamic để không lỗi
    dynamic onSearchSubmitted, // Chấp nhận dynamic
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  final ApiService _apiService = ApiService();
  
  @override
  Widget build(BuildContext context) {
    // Giao diện Header đơn giản hóa để chạy được
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onLogoTap,
            child: const Text("BlueStore", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.white), onPressed: widget.onCartPressed),
          IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: widget.onAccountPressed),
        ],
      ),
    );
  }
}