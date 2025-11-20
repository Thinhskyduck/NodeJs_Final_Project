import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../../data/services/cart_service.dart';

class ProductDetailsScreen2 extends StatefulWidget {
  final String productId; // Đã đổi từ int sang String
  const ProductDetailsScreen2({super.key, required this.productId});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen2> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService(); // Thêm cái này
  Product? _product;
  bool _isLoading = true;
  int _selectedVariantIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final product = await _apiService.getProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_product == null || _product!.variants.isEmpty) return;
    
    String productId = _product!.id;
    String variantId = _product!.variants[_selectedVariantIndex].id;
    
    // Dữ liệu phụ cho giỏ hàng Offline (Local Storage)
    String name = _product!.name + " - " + _product!.variants[_selectedVariantIndex].name;
    int price = _product!.variants[_selectedVariantIndex].price;
    String image = _product!.thumbnailUrl;

    // Gọi qua CartService
    bool success = await _cartService.addToCart(productId, variantId, 1, 
        name: name, price: price, image: image);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Đã thêm vào giỏ hàng" : "Lỗi thêm vào giỏ"),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_product == null) return const Scaffold(body: Center(child: Text("Sản phẩm không tồn tại")));

    final p = _product!;
    final currentVariant = p.variants.isNotEmpty ? p.variants[_selectedVariantIndex] : null;
    final String displayPrice = currentVariant != null 
        ? NumberFormat("#,##0₫", "vi_VN").format(currentVariant.price)
        : "Liên hệ";

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh
            SizedBox(
              height: 300,
              width: double.infinity,
              child: p.thumbnailUrl != null
                  ? Image.network(p.thumbnailUrl!, fit: BoxFit.contain)
                  : Image.asset('/assets/img/placeholder.png'),
            ),
            const SizedBox(height: 20),
            
            // 2. Tên & Giá
            Text(p.name, style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(displayPrice, style: GoogleFonts.roboto(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 20),
            
            // 3. Chọn Variant (Nếu có)
            if (p.variants.isNotEmpty) ...[
              Text("Chọn phiên bản:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: List.generate(p.variants.length, (index) {
                  final variant = p.variants[index];
                  final isSelected = _selectedVariantIndex == index;
                  return ChoiceChip(
                    label: Text("${variant.name} - ${NumberFormat("#,##0").format(variant.price)}"),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedVariantIndex = index),
                  );
                }),
              )
            ],

            const SizedBox(height: 20),
            
            // 4. Mô tả
            Text("Mô tả sản phẩm:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(p.description ?? "Đang cập nhật..."),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 15)
          ),
          child: Text("THÊM VÀO GIỎ HÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}