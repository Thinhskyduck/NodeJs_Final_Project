import 'dart:async';
import 'package:cross_platform_mobile_app_development/features/2_product/screens/product_detail.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import các file mới đã refactor
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../layout/footer.dart';
import '../../../layout/header.dart';

// Tạm thời comment dòng import chi tiết sản phẩm để tránh lỗi biên dịch
// import '../../2_product/screens/product_detail.dart'; 
import '../../3_cart/screens/cart_screen.dart';
import '../../5_profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Giữ lại bộ màu sắc cũ của bạn
  static const Color themeBluePrimary = Color(0xFF007BFF);
  static const Color themeBlueDark = Color(0xFF0056b3);
  static const Color cpsTextBlack = Color(0xFF222222);
  static const Color cpsTextGrey = Color(0xFF4A4A4A);
  static const Color cpsSubtleTextGrey = Color(0xFF757575);
  static const Color cpsCardBorderColor = Color(0xFFE0E0E0);
  static const Color cpsStarYellow = Color(0xFFFFC107);
  static const Color themePageBackground = Color(0xFFF0F2F5);
  static const Color themeBlueLight = Color(0xFFE0EFFF);
  static const Color cpsInstallmentBlue = Color(0xFF007AFF);
  
  // Màu cho Profile (giữ lại để không lỗi file khác import)
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
  // --- KHAI BÁO BIẾN MỚI ---
  final ApiService _apiService = ApiService();
  
  // List sản phẩm chính
  List<Product> _products = [];
  bool _isLoading = true;
  
  // Thông tin user
  Map<String, dynamic>? _currentUserData;
  
  // Controller cho Banner
  final PageController _bannerPageController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    _initData(); // Hàm khởi tạo dữ liệu mới
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC LẤY DỮ LIỆU ---
  Future<void> _initData() async {
    setState(() => _isLoading = true);

    // 1. KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP
    // Gọi API profile để xác thực token và lấy thông tin mới nhất
    final user = await _apiService.getUserProfile();
    
    if (mounted) {
      setState(() {
        if (user != null) {
          // Nếu lấy được user -> Đã đăng nhập
          _currentUserData = {
            'full_name': user.fullName,
            'email': user.email,
            'user_id': user.id, // Lưu lại ID để dùng cho Cart
          };
        } else {
          // Nếu không -> Là khách
          _currentUserData = null;
        }
      });
    }

    // 2. TẢI DANH SÁCH SẢN PHẨM (Giữ nguyên code cũ)
    try {
      final products = await _apiService.fetchProducts(limit: 20);
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

  // --- BANNER SLIDER (GIỮ NGUYÊN LOGIC CŨ VÌ NÓ TĨNH) ---
  final List<Map<String, dynamic>> _slidingBannersData = [
    {
      'assetImagePath': 'assets/images/banner_iphone16_titan_bg.png',
      'brandText': 'iPhone 16 Pro Max',
      'mainTitleLine1': 'Thiết kế Titan',
      'mainTitleLine2': 'Tuyệt đẹp.',
      'gradientColors': [Color(0xFFE0F2FF), Color(0xFFF8E2FF)],
      'mainTitleColor': Color(0xFF0071E3),
    },
    {
      'assetImagePath': 'assets/images/banner_s25_ultra_bg.png',
      'brandText': 'Galaxy S25 Ultra',
      'mainTitleLine1': 'Quyền năng AI',
      'mainTitleLine2': 'Bứt phá mọi giới hạn.',
      'gradientColors': [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
      'mainTitleColor': Colors.deepPurple,
    },
  ];

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

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: HomeScreen.themePageBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isWeb ? 60 : 50 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: [], // Tạm thời để rỗng
          currentUserData: _currentUserData,
          cartItemCount: 0, // Chưa xử lý giỏ hàng
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: _initData,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: CustomScrollView(
          slivers: [
            // 1. Banner Slider
            SliverToBoxAdapter(
              child: Container(
                height: isWeb ? 350 : 200,
                margin: const EdgeInsets.all(16),
                child: PageView.builder(
                  controller: _bannerPageController,
                  itemCount: _slidingBannersData.length,
                  itemBuilder: (context, index) {
                    return _buildBannerItem(_slidingBannersData[index]);
                  },
                ),
              ),
            ),

            // 2. Tiêu đề Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.whatshot, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      "GỢI Ý CHO BẠN",
                      style: GoogleFonts.roboto(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: HomeScreen.cpsTextBlack
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Grid Sản phẩm (Quan trọng nhất)
            _isLoading 
            ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())))
            : _products.isEmpty
              ? const SliverToBoxAdapter(child: Center(child: Text("Chưa có sản phẩm nào")))
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWeb ? (screenWidth > 1000 ? 5 : 4) : 2,
                      childAspectRatio: 0.7, // Tỷ lệ khung hình thẻ sản phẩm
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                      childCount: _products.length,
                    ),
                  ),
                ),
                
            // 4. Footer
            const SliverToBoxAdapter(child: AppFooter()),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CON: BANNER ITEM ---
  Widget _buildBannerItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: data['gradientColors']),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20, top: 20, bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data['brandText'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(data['mainTitleLine1'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: data['mainTitleColor'])),
                Text(data['mainTitleLine2'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: data['mainTitleColor'])),
              ],
            ),
          ),
          // Nếu có ảnh thật thì hiển thị ở đây (tạm thời dùng màu gradient)
        ],
      ),
    );
  }

  // --- WIDGET CON: THẺ SẢN PHẨM (PRODUCT CARD) ---
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // TODO: Mở trang chi tiết (Sẽ fix ở bước sau)
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: product.id)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))
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
                    errorBuilder: (c, e, s) => Image.asset('assets/images/placeholder.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            
            // 2. Thông tin
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HomeScreen.cpsTextBlack),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Giá tiền
                        Text(
                          product.salePriceText, // Đã được format trong Model
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        
                        // Rating
                        if (product.averageRating > 0)
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: HomeScreen.cpsStarYellow),
                            SizedBox(width: 4),
                            Text("${product.averageRating}", style: TextStyle(fontSize: 12, color: Colors.grey)),
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