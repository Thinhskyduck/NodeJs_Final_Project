import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../widgets/review_section.dart';

class ProductDetailsScreen2 extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen2({super.key, required this.productId});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen2> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  Product? _product;
  bool _isLoading = true;
  int _selectedVariantIndex = 0;
  
  // STATE MỚI: Để quản lý ảnh đang chọn
  int _selectedImageIndex = 0;
  
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initSocket();
  }

  Future<void> _fetchData() async {
    final product = await _apiService.getProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
        // Reset về ảnh đầu tiên khi load xong
        _selectedImageIndex = 0; 
      });
    }
  }

  void _initSocket() {
    // URL Socket
    String socketUrl = AppConstants.baseUrl.replaceAll('/api', '');
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();
    _socket.on('new_review', (data) {
      if (mounted && data != null) {
        if (data['productId'] == widget.productId) {
          _fetchData(); 
        }
      }
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_product == null || _product!.variants.isEmpty) return;
    
    final selectedVariant = _product!.variants[_selectedVariantIndex];

    if (selectedVariant.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sản phẩm này tạm hết hàng!"), backgroundColor: Colors.red),
      );
      return;
    }
    
    bool success = await _cartService.addToCart(
      _product!.id, 
      selectedVariant.id, 
      1, 
      name: "${_product!.name} (${selectedVariant.name})",
      price: selectedVariant.price, 
      image: _product!.thumbnailUrl
    );
    
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
    final int stock = currentVariant?.stockQuantity ?? 0;

    // Lấy danh sách ảnh (Nếu rỗng thì fallback về thumbnail)
    List<String> displayImages = p.images.isNotEmpty ? p.images : [p.thumbnailUrl];

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. KHỐI HIỂN THỊ ẢNH (MỚI) ---
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.network(
                  // Helper xử lý full URL
                  AppConstants.getFullImageUrl(displayImages[_selectedImageIndex]), 
                  fit: BoxFit.contain,
                  errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // --- LIST ẢNH THUMBNAIL ---
            if (displayImages.length > 1)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayImages.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedImageIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = index),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300, 
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            AppConstants.getFullImageUrl(displayImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // ----------------------------------

            const SizedBox(height: 20),
            
            // Tên & Giá
            Text(p.name, style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Text(displayPrice, style: GoogleFonts.roboto(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
            Text("Kho: $stock sản phẩm", style: TextStyle(color: stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),
            
            // CHỌN BIẾN THỂ
            if (p.variants.isNotEmpty) ...[
              const Text("Cấu hình:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: List.generate(p.variants.length, (index) {
                  final variant = p.variants[index];
                  final isSelected = _selectedVariantIndex == index;
                  return ChoiceChip(
                    label: Text(variant.name),
                    selected: isSelected,
                    selectedColor: Colors.blue.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _selectedVariantIndex = index);
                    },
                  );
                }),
              )
            ],

            const SizedBox(height: 20),
            const Divider(),
            
            const Text("Mô tả sản phẩm:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p.description, style: const TextStyle(fontSize: 14, height: 1.5)),
            
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // REVIEW SECTION
            ReviewSection(
              productId: p.id,
              reviews: p.reviews,
              onReviewSubmitted: _fetchData, 
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: stock > 0 ? _addToCart : null, 
          style: ElevatedButton.styleFrom(
            backgroundColor: stock > 0 ? Colors.blue : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 15)
          ),
          child: Text(
            stock > 0 ? "THÊM VÀO GIỎ HÀNG" : "TẠM HẾT HÀNG", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
}