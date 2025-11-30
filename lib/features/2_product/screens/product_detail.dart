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
    
    // 1. Lấy biến thể đang được chọn
    final selectedVariant = _product!.variants[_selectedVariantIndex];

    // 2. Kiểm tra tồn kho (Yêu cầu đồ án)
    if (selectedVariant.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sản phẩm này tạm hết hàng!"), backgroundColor: Colors.red),
      );
      return;
    }
    
    // 3. Gọi Service thêm vào giỏ
    // Lưu ý: selectedVariant.id lúc này đã được Model fix (lấy _id) nên sẽ chính xác
    bool success = await _cartService.addToCart(
      _product!.id, 
      selectedVariant.id, 
      1, 
      name: "${_product!.name} (${selectedVariant.name})", // Ghép tên biến thể cho rõ
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
    // Lấy biến thể hiện tại để hiển thị giá và kho
    final currentVariant = p.variants.isNotEmpty ? p.variants[_selectedVariantIndex] : null;
    
    final String displayPrice = currentVariant != null 
        ? NumberFormat("#,##0₫", "vi_VN").format(currentVariant.price)
        : "Liên hệ";
        
    final int stock = currentVariant?.stockQuantity ?? 0;

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
            
            // Tên & Giá
            Text(p.name, style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // HIỂN THỊ GIÁ THEO BIẾN THỂ
            Text(displayPrice, style: GoogleFonts.roboto(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
            
            // HIỂN THỊ TỒN KHO (Yêu cầu đồ án)
            Text("Kho: $stock sản phẩm", style: TextStyle(color: stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),
            
            // CHỌN BIẾN THỂ (Chips)
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
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue.shade900 : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedVariantIndex = index);
                    },
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
          // Disable nút nếu hết hàng
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