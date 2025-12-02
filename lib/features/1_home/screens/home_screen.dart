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

  // --- DATA STATE CHO CÁC SECTION ---
  List<Product> _newArrivals = [];
  List<Product> _bestSellers = [];
  
  // Ví dụ 2 danh mục cụ thể (bạn cần thay ID thật từ MongoDB của bạn vào đây hoặc lấy động)
  // Tạm thời mình sẽ để list rỗng và load động sau
  List<Map<String, dynamic>> _categories = []; 
  Map<String, List<Product>> _categoryProducts = {}; // Map lưu sp theo category id

  bool _isLoading = true;
  Map<String, dynamic>? _currentUserData;

  // --- BANNER STATE (Giữ nguyên) ---
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  // ... (Giữ nguyên list _slidingBannersData) ...


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
    setState(() => _isLoading = true);
    await _checkLoginStatus(); // Giữ nguyên hàm này cũ của bạn

    try {
      // 1. Load danh mục trước
      final categories = await _apiService.getCategories();
      
      // 2. Load New Arrivals & Best Sellers song song
      final newArrivals = await _apiService.fetchNewArrivals();
      final bestSellers = await _apiService.fetchBestSellers();

      // 3. Load sản phẩm cho 3 danh mục đầu tiên (nếu có)
      Map<String, List<Product>> catProds = {};
      // Lấy 3 danh mục đầu để hiển thị trang chủ (Ví dụ: Laptop, PC, Màn hình...)
      for (var i = 0; i < categories.length; i++) {
        final catId = categories[i]['_id'];
        final products = await _apiService.fetchProductsByCategory(catId);
        catProds[catId] = products;
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _newArrivals = newArrivals;
          _bestSellers = bestSellers;
          _categoryProducts = catProds;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải trang chủ: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
  // Future<void> _fetchProducts() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     // Map giá trị dropdown sang tham số backend
  //     String? sortParam;
  //     if (_sortBy == 'price_asc') sortParam = 'price';
  //     if (_sortBy == 'price_desc') sortParam = '-price';
  //     // Nếu là 'newest', backend thường mặc định là -createdAt, hoặc có thể truyền '-createdAt'

  //     final products = await _apiService.fetchProducts(
  //       limit: 20,
  //       search: _searchKeyword.isNotEmpty ? _searchKeyword : null,
  //       sortBy: sortParam, // <-- Đây là chỗ sửa lỗi: truyền tham số sortBy
  //     );
      
  //     if (mounted) {
  //       setState(() {
  //         _products = products;
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("Lỗi tải sản phẩm: $e");
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb && MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: HomeScreen.themePageBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isWeb ? 80 : 60 + MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            CustomHeader(
              categories: _categories, // Truyền danh mục vào Header
              currentUserData: _currentUserData,
              cartItemCount: 0, 
              onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
              onLogoTap: _initData,
            ),
          ],
        ),
      ),
      
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _initData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 1. Banner (Giữ nguyên)
                Container(
                  height: isWeb ? 350 : 180,
                  margin: const EdgeInsets.all(16),
                  child: PageView.builder(
                    controller: _bannerPageController,
                    itemCount: _slidingBannersData.length, // Sửa lại biến này lấy từ code cũ của bạn
                    itemBuilder: (context, index) => _buildBannerItem(_slidingBannersData[index]),
                  ),
                ),

                // 2. SECTION: SẢN PHẨM MỚI (NEW ARRIVALS)
                _buildSectionTitle("SẢN PHẨM MỚI VỀ", icon: Icons.new_releases, color: Colors.blue),
                _buildHorizontalProductList(_newArrivals),

                const SizedBox(height: 20),

                // 3. SECTION: BÁN CHẠY (BEST SELLERS)
                _buildSectionTitle("BÁN CHẠY NHẤT", icon: Icons.local_fire_department, color: Colors.red),
                _buildHorizontalProductList(_bestSellers),

                const SizedBox(height: 20),

                // 4. CÁC SECTION DANH MỤC CỤ THỂ
                // Lặp qua 3 danh mục đầu tiên để hiển thị
                ..._categories.take(3).map((cat) {
                  final catId = cat['_id'];
                  final products = _categoryProducts[catId] ?? [];
                  if (products.isEmpty) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _buildSectionTitle(cat['name'].toString().toUpperCase(), icon: Icons.computer, color: Colors.black87),
                      _buildHorizontalProductList(products),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),

                const SizedBox(height: 40),
                const AppFooter(),
              ],
            ),
          ),
        ),
    );
  }

  // Widget Tiêu đề Section đẹp hơn
  Widget _buildSectionTitle(String title, {required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title, 
            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: HomeScreen.cpsTextBlack)
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()));
            },
            child: const Text("Xem tất cả >"),
          )
        ],
      ),
    );
  }

  // Widget List ngang tái sử dụng
  Widget _buildHorizontalProductList(List<Product> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("Chưa có sản phẩm nào."),
      );
    }
    return SizedBox(
      height: 290, // Tăng chiều cao xíu để thẻ ko bị lỗi overflow
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: products.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 180,
            child: _buildProductCard(products[index]), // Hàm cũ của bạn
          );
        },
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
                  child: Image.asset(
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