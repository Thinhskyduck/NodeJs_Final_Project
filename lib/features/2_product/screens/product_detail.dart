import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../layout/header.dart'; // Import CustomHeader
import '../../1_home/screens/home_screen.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../5_profile/screens/profile_screen.dart';
import 'catalog_screen.dart';
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
  int _selectedImageIndex = 0;
  late IO.Socket _socket;

  // --- HEADER STATE ---
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _currentUserData;
  int _cartItemCount = 0;

  // Màu sắc chủ đạo & Style
  static const Color _primaryRed = Color(0xFFD70018); 
  static const Color _bgLight = Color(0xFFF9FAFB);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const double _webMaxWidth = 1200; 

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initHeaderData(); // Tải dữ liệu cho Header
    _initSocket();
  }

  // Tải dữ liệu Header (User, Cart, Categories)
  Future<void> _initHeaderData() async {
    try {
      final categories = await _apiService.getCategories();
      final user = await _apiService.getUserProfile();
      final cartItems = await _cartService.getCartItems();

      Map<String, dynamic>? userData;
      if (user != null) {
        userData = {
          'full_name': user.fullName,
          'email': user.email,
          'user_id': user.id,
        };
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _currentUserData = userData;
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      debugPrint("Header load error: $e");
    }
  }

  Future<void> _fetchData() async {
    try {
      final product = await _apiService.getProductDetail(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
          _selectedImageIndex = 0;
          _selectedVariantIndex = 0; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initSocket() {
    String socketUrl = AppConstants.baseUrl.replaceAll('/api', '');
    try {
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      _socket.connect();
      _socket.on('new_review', (data) {
        if (mounted && data != null && data['productId'] == widget.productId) {
          _fetchData();
        }
      });
    } catch (e) {
      debugPrint("Socket error: $e");
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _addToCart({bool isBuyNow = false}) async {
    if (_product == null || _product!.variants.isEmpty) return;
    final selectedVariant = _product!.variants[_selectedVariantIndex];

    if (selectedVariant.stockQuantity <= 0) {
      _showToast("Sản phẩm tạm hết hàng", isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: _primaryRed)),
    );

    bool success = await _cartService.addToCart(
      _product!.id,
      selectedVariant.id,
      1,
      name: "${_product!.name} (${selectedVariant.name})",
      price: selectedVariant.price,
      image: _product!.thumbnailUrl,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (success) {
        // Cập nhật lại số lượng giỏ hàng trên Header ngay lập tức
        _initHeaderData(); 

        if (isBuyNow) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
        } else {
          _showToast("Đã thêm vào giỏ hàng thành công!");
        }
      } else {
        _showToast("Có lỗi xảy ra, vui lòng thử lại!", isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        width: 400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: _primaryRed)));
    if (_product == null) return const Scaffold(body: Center(child: Text("Sản phẩm không tìm thấy")));

    return Scaffold(
      backgroundColor: _bgLight,
      // Thay AppBar cũ bằng CustomHeader
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _categories,
          currentUserData: _currentUserData,
          cartItemCount: _cartItemCount,
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
          onSearchSubmitted: (query) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(initialSearch: query)));
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: _webMaxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumbs(),
                const SizedBox(height: 20),
                
                // --- PHẦN TRÊN: 2 CỘT (ẢNH | THÔNG TIN) ---
                _buildMainContentWeb(),
                
                const SizedBox(height: 40),
                
                // --- PHẦN DƯỚI: THÔNG TIN CHI TIẾT & REVIEW ---
                _buildDescriptionAndSpecs(),
                
                const SizedBox(height: 40),
                
                // Review Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  padding: const EdgeInsets.all(24),
                  child: ReviewSection(
                    productId: _product!.id,
                    reviews: _product!.reviews,
                    onReviewSubmitted: _fetchData,
                  ),
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
          child: const Icon(Icons.home, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 5),
        const Text(" / ", style: TextStyle(color: Colors.grey)),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
          child: Text(_product!.categoryName ?? "Sản phẩm", style: const TextStyle(color: Colors.grey)),
        ),
        const Text(" / ", style: TextStyle(color: Colors.grey)),
        Text(_product!.brand, style: const TextStyle(color: Colors.grey)),
        const Text(" / ", style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            _product!.name, 
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContentWeb() {
    final p = _product!;
    final List<String> images = p.images.isNotEmpty ? p.images : [p.thumbnailUrl];

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobileWidth = constraints.maxWidth < 800;

        Widget imageSection = _buildGalleryWeb(images);
        Widget infoSection = _buildProductInfoWeb();

        if (isMobileWidth) {
          return Column(children: [imageSection, const SizedBox(height: 20), infoSection]);
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: imageSection),
              const SizedBox(width: 30),
              Expanded(flex: 7, child: infoSection),
            ],
          );
        }
      },
    );
  }

  Widget _buildGalleryWeb(List<String> images) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 400,
            width: double.infinity,
            alignment: Alignment.center,
            child: Image.asset(
              AppConstants.getFullImageUrl(images[_selectedImageIndex]),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => 
                  Image.asset('assets/images/placeholder.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          if (images.length > 1)
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  bool isSelected = _selectedImageIndex == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedImageIndex = index),
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? _primaryRed : Colors.grey.shade300, 
                          width: isSelected ? 2 : 1
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        AppConstants.getFullImageUrl(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.zoom_in, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text("Rê chuột để phóng to", style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProductInfoWeb() {
    final p = _product!;
    final variant = p.variants.isNotEmpty ? p.variants[_selectedVariantIndex] : null;
    final int price = variant?.price ?? 0;
    final int oldPrice = (price * 1.2).round();
    final int stock = variant?.stockQuantity ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            RatingBarIndicator(
              rating: p.averageRating > 0 ? p.averageRating : 5,
              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 18.0,
            ),
            const SizedBox(width: 8),
            Text("${p.numReviews} đánh giá", style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            Container(margin: const EdgeInsets.symmetric(horizontal: 10), width: 1, height: 16, color: Colors.grey),
            Text("Thương hiệu: ${p.brand}", style: const TextStyle(color: Colors.black54)),
          ],
        ),

        const Divider(height: 32, color: _borderColor),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat("#,##0₫", "vi_VN").format(price),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _primaryRed),
            ),
            const SizedBox(width: 16),
            Text(
              NumberFormat("#,##0₫", "vi_VN").format(oldPrice),
              style: const TextStyle(fontSize: 18, decoration: TextDecoration.lineThrough, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: const Text("-20%", style: TextStyle(color: _primaryRed, fontWeight: FontWeight.bold)),
            )
          ],
        ),

        const SizedBox(height: 24),

        const Text("Chọn phiên bản:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(p.variants.length, (index) {
            final v = p.variants[index];
            bool isSelected = index == _selectedVariantIndex;
            return InkWell(
              onTap: () => setState(() => _selectedVariantIndex = index),
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _bgLight,
                  border: Border.all(color: isSelected ? _primaryRed : _borderColor, width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(v.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(height: 4),
                    Text(NumberFormat("#,##0₫", "vi_VN").format(v.price), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.card_giftcard, color: _primaryRed, size: 20),
                SizedBox(width: 8),
                Text("KHUYẾN MÃI ĐẶC BIỆT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
              ]),
              const Divider(height: 20),
              _buildPromoRow("Giảm thêm 5% tối đa 500k qua VNPAY."),
              _buildPromoRow("Thu cũ đổi mới trợ giá ngay 15%."),
              _buildPromoRow("Tặng gói bảo hành vàng 12 tháng."),
            ],
          ),
        ),

        const SizedBox(height: 30),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: stock > 0 ? () => _addToCart(isBuyNow: true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("MUA NGAY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(stock > 0 ? "Giao hàng tận nơi hoặc nhận tại cửa hàng" : "Liên hệ khi có hàng", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: stock > 0 ? () => _addToCart(isBuyNow: false) : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_shopping_cart, color: _primaryRed),
                      SizedBox(height: 4),
                      Text("Thêm vào giỏ", style: TextStyle(color: _primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildDescriptionAndSpecs() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Column(children: [ _buildSpecsBox(), const SizedBox(height: 20), _buildDescriptionBox()]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 8, child: _buildDescriptionBox()),
          const SizedBox(width: 30),
          Expanded(flex: 4, child: _buildSpecsBox()),
        ],
      );
    });
  }

  Widget _buildDescriptionBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Đặc điểm nổi bật", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            _product!.description,
            style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Thông số kỹ thuật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSpecItem("Thương hiệu", _product!.brand),
          _buildSpecItem("Danh mục", _product!.categoryName ?? ""),
          _buildSpecItem("Bảo hành", "12 tháng"),
          
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {}, 
              child: const Text("Xem cấu hình chi tiết >"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(flex: 6, child: Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}