import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các file core/data
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../layout/footer.dart';
import '../../../layout/header.dart';

// Import các màn hình chức năng
import '../../2_product/screens/product_detail.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../5_profile/screens/profile_screen.dart';
import '../../2_product/screens/catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Màu sắc giao diện
  static const Color themeBluePrimary = Color(0xFF007BFF);
  static const Color themePageBackground = Color(0xFFF0F2F5);
  static const Color cpsTextBlack = Color(0xFF222222);
  static const Color cpsStarYellow = Color(0xFFFFC107);
  
  // Các màu phụ trợ (giữ lại để tránh lỗi import từ file khác)
  static const Color themeBlueDark = Color(0xFF0056b3);
  static const Color cpsTextGrey = Color(0xFF4A4A4A);
  static const Color cpsSubtleTextGrey = Color(0xFF757575);
  static const Color cpsCardBorderColor = Color(0xFFE0E0E0);
  static const Color themeBlueLight = Color(0xFFE0EFFF);
  static const Color cpsInstallmentBlue = Color(0xFF007AFF);
  static const Color imageRedAccent = Color(0xFF007BFF);
  static const Color imageLightRedBackground = Color(0xFFFDEBEE);
  static const Color imagePageBackground = Color(0xFFF5F5F5);
  static const Color imageUpdateBannerBlue = Color(0xFFEBF4FF);
  static const Color imageSnullBgColor = Color(0xFFFCE4EC);
  static const Color imageSnullTextBorderColor = Color(0xFF1E88E5);
  static const Color imageSstudentBgColor = Color(0xFFE3F2FD);
  static const Color imageSstudentTextBorderColor = Color(0xFF1E88E5);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  
  // --- DATA STATE ---
  List<Product> _products = [];
  bool _isLoading = true;
  Map<String, dynamic>? _currentUserData;

  // --- FILTER STATE ---
  String _searchKeyword = "";
  String _sortBy = "newest"; // Options: newest, price_asc, price_desc

  // --- BANNER STATE ---
  final PageController _bannerPageController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  // Dữ liệu Banner (Đã sửa thành Laptop/PC)
  final List<Map<String, dynamic>> _slidingBannersData = [
    {
      'assetImagePath': 'assets/images/placeholder.png', // Hãy thay bằng ảnh banner laptop thật
      'brandText': 'Gaming Laptop',
      'mainTitleLine1': 'Sức mạnh RTX 4090',
      'mainTitleLine2': 'Chiến game đỉnh cao.',
      'gradientColors': [Color(0xFF1A237E), Color(0xFF0D47A1)],
      'mainTitleColor': Colors.white,
    },
    {
      'assetImagePath': 'assets/images/placeholder.png',
      'brandText': 'Linh kiện PC',
      'mainTitleLine1': 'Nâng cấp RAM/SSD',
      'mainTitleLine2': 'Hiệu năng vượt trội.',
      'gradientColors': [Color(0xFF004D40), Color(0xFF00695C)],
      'mainTitleColor': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    _initData();
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = (_bannerPageController.page!.round() + 1) % _slidingBannersData.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _initData() async {
    await _checkLoginStatus();
    await _fetchProducts();
  }

  Future<void> _checkLoginStatus() async {
    final user = await _apiService.getUserProfile();
    if (mounted) {
      setState(() {
        if (user != null) {
          _currentUserData = {
            'full_name': user.fullName,
            'email': user.email,
            'user_id': user.id,
          };
        } else {
          _currentUserData = null;
        }
      });
    }
  }

  // Hàm gọi API lấy sản phẩm (Có Filter & Sort & Search)
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // Map giá trị dropdown sang tham số backend
      String? sortParam;
      if (_sortBy == 'price_asc') sortParam = 'price';
      if (_sortBy == 'price_desc') sortParam = '-price';
      // Nếu là 'newest', backend thường mặc định là -createdAt, hoặc có thể truyền '-createdAt'

      final products = await _apiService.fetchProducts(
        limit: 20,
        search: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        sortBy: sortParam, // <-- Đây là chỗ sửa lỗi: truyền tham số sortBy
      );
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải sản phẩm: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: HomeScreen.themePageBackground,
      appBar: PreferredSize(
        // FIX LỖI OVERFLOW: Tăng chiều cao từ 100 lên 140
        preferredSize: Size.fromHeight(isWeb ? 140 : 130 + MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            CustomHeader(
              categories: [],
              currentUserData: _currentUserData,
              cartItemCount: 0,
              onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
              onLogoTap: _initData,
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox( // Bọc TextField trong SizedBox để cố định chiều cao
                height: 45,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Tìm Laptop, VGA, RAM...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (value) {
                    // Khi search -> Chuyển sang trang Catalog
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(initialSearch: value)));
                  },
                ),
              ),
            )
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: SingleChildScrollView( // Dùng SingleChildScrollView thay vì CustomScrollView cho đơn giản
          child: Column(
            children: [
              // 1. Banner
              Container(
                height: isWeb ? 350 : 180, // Giảm chiều cao banner mobile cho đỡ chiếm chỗ
                margin: const EdgeInsets.all(16),
                child: PageView.builder(
                  controller: _bannerPageController,
                  itemCount: _slidingBannersData.length,
                  itemBuilder: (context, index) => _buildBannerItem(_slidingBannersData[index]),
                ),
              ),

              // 2. Header List Sản phẩm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("GỢI Ý CHO BẠN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                         // Chuyển sang trang Catalog
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()));
                      },
                      child: const Text("Xem tất cả >"),
                    )
                  ],
                ),
              ),

              // 3. List ngang (Horizontal List)
              SizedBox(
                height: 280, // Chiều cao cố định cho list ngang
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 180, // Chiều rộng mỗi thẻ
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildProductCard(_products[index]),
                          ),
                        );
                      },
                    ),
              ),
              
              const SizedBox(height: 20),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị Banner
  Widget _buildBannerItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: data['gradientColors']),
      ),
      child: Stack(
        children: [
          // Background placeholder
           Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('/images/placeholder.png', fit: BoxFit.cover),
              // child: Image.network("https://via.placeholder.com/800x400.png?text=COMPUTER+BANNER", fit: BoxFit.cover),
            ),
          ),
          Positioned(
            left: 20, top: 20, bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data['brandText'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 10),
                Text(data['mainTitleLine1'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(data['mainTitleLine2'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị Thẻ sản phẩm (Product Card)
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // Điều hướng đến trang chi tiết, truyền ID sản phẩm
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: product.id)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh sản phẩm
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Image.network(
                    product.thumbnailUrl,
                    fit: BoxFit.contain,
                    // Xử lý khi ảnh lỗi thì hiện placeholder
                    errorBuilder: (c, e, s) => Image.asset('/images/placeholder.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            
            // 2. Thông tin (Tên, Giá, Rating)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tên sản phẩm
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HomeScreen.cpsTextBlack),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Giá tiền
                        Text(
                          product.salePriceText, // Đã được format trong Model
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Rating sao
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: HomeScreen.cpsStarYellow),
                            const SizedBox(width: 4),
                            Text("${product.averageRating > 0 ? product.averageRating : '5.0'}", 
                              style: const TextStyle(fontSize: 12, color: Colors.grey)
                            ),
                            const SizedBox(width: 8),
                            const Text("Đã bán 100+", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}