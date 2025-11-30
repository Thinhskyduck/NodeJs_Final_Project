import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../../data/services/cart_service.dart';
import '../widgets/review_section.dart'; // <--- Import Widget mới
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket _socket; // Khai báo socket

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initSocket();
  }

  // Hàm load dữ liệu (gọi lại khi submit review xong)
  Future<void> _fetchData() async {
    final product = await _apiService.getProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  // Hàm khởi tạo kết nối Socket.IO
  void _initSocket() {
    // Thay URL bằng địa chỉ server của bạn
    String socketUrl = AppConstants.baseUrl.replaceAll('/api', '');
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to Socket.IO');
    });

    // Lắng nghe sự kiện 'new_review' từ Backend
    _socket.on('new_review', (data) {
      if (mounted && data != null) {
        // Kiểm tra xem review mới có thuộc về sản phẩm đang xem không
        if (data['productId'] == widget.productId) {
          print("Nhận được review mới real-time!");
          // Reload lại dữ liệu để hiển thị review mới
          _fetchData(); 
          
          // Hoặc nếu muốn mượt hơn, bạn có thể parse `data['review']` 
          // rồi add trực tiếp vào list `_product.reviews` mà không cần gọi API lại.
        }
      }
    });
  }

  // Ngắt kết nối khi thoát màn hình  
  @override
  void dispose() {
    _socket.disconnect(); // Ngắt kết nối khi thoát màn hình
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_product == null || _product!.variants.isEmpty) return;
    
    String productId = _product!.id;
    String variantId = _product!.variants[_selectedVariantIndex].id;
    
    String name = _product!.name + " - " + _product!.variants[_selectedVariantIndex].name;
    int price = _product!.variants[_selectedVariantIndex].price;
    String image = _product!.thumbnailUrl;

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
              child: Image.network(
                p.thumbnailUrl, 
                fit: BoxFit.contain,
                errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. Tên & Giá & Rating Tổng quan
            Text(p.name, style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(displayPrice, style: GoogleFonts.roboto(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 20),
                Text(" ${p.averageRating.toStringAsFixed(1)} (${p.numReviews} đánh giá)", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 3. Chọn Variant
            if (p.variants.isNotEmpty) ...[
              const Text("Chọn phiên bản:", style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Divider(),
            
            // 4. Mô tả
            const Text("Mô tả sản phẩm:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p.description ?? "Đang cập nhật...", style: const TextStyle(fontSize: 14, height: 1.5)),
            
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // 5. PHẦN ĐÁNH GIÁ (REVIEW SECTION) - MỚI THÊM
            ReviewSection(
              productId: p.id,
              reviews: p.reviews,
              onReviewSubmitted: _fetchData, // Reload lại trang khi submit xong
            ),
            
            const SizedBox(height: 80), // Khoảng trống bottom cho nút Add to Cart
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 15)
          ),
          child: const Text("THÊM VÀO GIỎ HÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}