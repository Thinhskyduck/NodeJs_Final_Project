import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart'; // Import CartService
import '../../../layout/footer.dart';
import '../../../layout/header.dart';

// Screens
import '../../2_product/screens/product_detail.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../5_profile/screens/profile_screen.dart';
import '../../2_product/screens/catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color themePrimaryRed = Color(0xFFD70018); // Màu đỏ CellphoneS
  static const Color themePageBackground = Color(0xFFF4F6F8);
  static const Color cpsTextBlack = Color(0xFF333333);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService(); // Thêm service giỏ hàng

  // Data State
  List<Product> _newArrivals = [];
  List<Product> _bestSellers = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Product>> _categoryProducts = {};
  
  // User & Cart State
  bool _isLoading = true;
  Map<String, dynamic>? _currentUserData;
  int _cartItemCount = 0; // Biến lưu số lượng giỏ hàng

  // Banner State
  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  final List<Map<String, dynamic>> _slidingBannersData = [
    
    {
      'image': 'assets/img/banner-1.webp',
      'colors': [Color(0xFFB71C1C), Color(0xFFD32F2F)],
      'title': 'Gaming MSI',
      'sub': 'Chiến game bất tận',
    },
    {
      'image': 'assets/img/banner-2.webp', 
      'colors': [Color(0xFF1A237E), Color(0xFF0D47A1)],
      'title': 'MacBook Pro M3',
      'sub': 'Hiệu năng đỉnh cao',
    },
    {
      'image': 'assets/img/banner-3.webp',
      'colors': [Color(0xFF1B5E20), Color(0xFF388E3C)],
      'title': 'Linh kiện PC',
      'sub': 'Deal ngon giá tốt',
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
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = (_bannerPageController.page!.round() + 1) % _slidingBannersData.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    
    // Gọi song song các API để tiết kiệm thời gian
    try {
      await Future.wait([
        _checkLoginStatus(),
        _fetchCartCount(), // Lấy số lượng giỏ hàng
        _fetchProductData(),
      ]);
    } catch (e) {
      debugPrint("Lỗi tải trang chủ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProductData() async {
    final categories = await _apiService.getCategories();
    final newArrivals = await _apiService.fetchNewArrivals();
    final bestSellers = await _apiService.fetchBestSellers();

    Map<String, List<Product>> catProds = {};
    // Chỉ lấy sản phẩm cho 3 category đầu để demo tránh load lâu
    for (var i = 0; i < categories.length && i < 3; i++) {
      final catId = categories[i]['_id'];
      final products = await _apiService.fetchProductsByCategory(catId);
      if(products.isNotEmpty) {
        catProds[catId] = products;
      }
    }

    if (mounted) {
      setState(() {
        _categories = categories;
        _newArrivals = newArrivals;
        _bestSellers = bestSellers;
        _categoryProducts = catProds;
      });
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

  Future<void> _fetchCartCount() async {
    try {
      final items = await _cartService.getCartItems();
      if (mounted) {
        setState(() {
          _cartItemCount = items.length;
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy giỏ hàng: $e");
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CartScreen())
    ).then((_) {
      // Khi quay lại từ giỏ hàng, cập nhật lại số lượng
      _fetchCartCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb && MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: HomeScreen.themePageBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _categories,
          currentUserData: _currentUserData,
          cartItemCount: _cartItemCount, // Truyền số lượng thực tế
          onCartPressed: _navigateToCart,
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: _initData,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HomeScreen.themePrimaryRed))
          : RefreshIndicator(
              onRefresh: _initData,
              color: HomeScreen.themePrimaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // --- 1. HERO SECTION ---
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        padding: EdgeInsets.only(top: isWeb ? 16 : 0),
                        child: isWeb 
                          ? _buildWebHeroSection() 
                          : _buildMobileHeroSection(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- 2. SẢN PHẨM MỚI ---
                    ProductListSection(
                      title: "SẢN PHẨM MỚI",
                      icon: Icons.new_releases_outlined,
                      headerColor: Colors.blue.shade700,
                      products: _newArrivals,
                    ),

                    const SizedBox(height: 20),

                    // --- 3. HOT SALE / BEST SELLER ---
                    ProductListSection(
                      title: "XU HƯỚNG MUA SẮM",
                      icon: Icons.local_fire_department,
                      headerColor: HomeScreen.themePrimaryRed,
                      products: _bestSellers,
                      isHot: true,
                    ),

                    const SizedBox(height: 20),

                    // --- 4. CATEGORY SECTIONS ---
                    ..._categories.take(3).map((cat) {
                      final catId = cat['_id'];
                      final products = _categoryProducts[catId] ?? [];
                      if (products.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ProductListSection(
                          title: cat['name'].toString().toUpperCase(),
                          icon: Icons.laptop_mac,
                          headerColor: Colors.black87,
                          products: products,
                        ),
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

  // ==========================================
  // WIDGETS UI CHÍNH
  // ==========================================

  Widget _buildWebHeroSection() {
    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sidebar Danh mục (Left)
          Expanded(
            flex: 2,
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(right: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: Colors.white,
              child: _buildCategorySidebar(),
            ),
          ),
          
          // 2. Banner Slider (Center)
          Expanded(
            flex: 6,
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(right: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: PageView.builder(
                controller: _bannerPageController,
                itemCount: _slidingBannersData.length,
                onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                itemBuilder: (context, index) => _buildBannerItem(_slidingBannersData[index]),
              ),
            ),
          ),

          // 3. Right Promo Banners (Thay cho thẻ User cũ)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: _buildPromoBanner(
                    "Ưu đãi Sinh viên", "Giảm thêm 5% tối đa 300k", 
                    const Color(0xFFFEF6E6), Colors.orange, "assets/images/placeholder.png"
                  )
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildPromoBanner(
                    "Thu cũ đổi mới", "Trợ giá lên đời 1 triệu", 
                    const Color(0xFFEDF7ED), Colors.green, "assets/images/placeholder.png"
                  )
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildPromoBanner(
                    "Thanh toán Online", "Giảm thêm 5% qua ví", 
                    const Color(0xFFE3F2FD), Colors.blue, "assets/images/placeholder.png"
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeroSection() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: PageView.builder(
        controller: _bannerPageController,
        itemCount: _slidingBannersData.length,
        itemBuilder: (context, index) => _buildBannerItem(_slidingBannersData[index]),
      ),
    );
  }

  // --- Sub-widgets cho Hero ---

  IconData _getCategoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('laptop')) return Icons.laptop_mac;
  if (n.contains('pc') || n.contains('máy tính')) return Icons.desktop_windows;
  if (n.contains('chuột')) return Icons.mouse;
  if (n.contains('phím')) return Icons.keyboard;
  if (n.contains('tai nghe') || n.contains('âm thanh')) return Icons.headphones;
  if (n.contains('ổ cứng') || n.contains('ssd') || n.contains('hdd')) return Icons.storage;
  if (n.contains('màn hình')) return Icons.monitor;
  return Icons.category; // Icon mặc định
}

  Widget _buildCategorySidebar() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final catName = cat['name'] ?? '';
        
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(categoryId: cat['_id']))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F3F3))),
            ),
            child: Row(
              children: [
                // Sử dụng hàm _getCategoryIcon ở đây
                Icon(_getCategoryIcon(catName), size: 20, color: Colors.black54), 
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    catName, 
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: HomeScreen.cpsTextBlack),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )
                ),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tìm hàm này trong lib/features/1_home/screens/home_screen.dart
  Widget _buildBannerItem(Map<String, dynamic> data) {
    return Container(
      // Bỏ phần decoration gradient nếu muốn ảnh gốc hoàn toàn
      // decoration: BoxDecoration(...), 
      child: ClipRRect( // Thêm ClipRRect để bo góc nếu cần
        borderRadius: BorderRadius.circular(10), // Bo góc cho đẹp
        child: Image.asset(
          data['image'],
          // SỬA Ở ĐÂY: Đổi thành BoxFit.fill để kéo dãn vừa khung 
          // hoặc BoxFit.contain để hiện full ảnh (có thể bị khoảng trắng 2 bên)
          fit: BoxFit.contain, 
        ),
      ),
    );
  }

  Widget _buildPromoBanner(String title, String sub, Color bgColor, Color textColor, String imgPath) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  const SizedBox(height: 4),
                  Text(sub, style: TextStyle(fontSize: 12, color: Colors.black87.withOpacity(0.7))),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(imgPath, fit: BoxFit.cover),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET: DANH SÁCH SẢN PHẨM CÓ NÚT NEXT/PREV
// ==========================================
class ProductListSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color headerColor;
  final List<Product> products;
  final bool isHot; // Biến này quyết định giao diện đỏ rực

  const ProductListSection({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColor,
    required this.products,
    this.isHot = false,
  });

  @override
  State<ProductListSection> createState() => _ProductListSectionState();
}


class _ProductListSectionState extends State<ProductListSection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    // Delay check initial state
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    setState(() {
      _canScrollLeft = _scrollController.position.pixels > 0;
      _canScrollRight = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
    });
  }

  void _scroll(bool isRight) {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;
    // Cuộn một khoảng bằng 3 card + spacing
    const scrollAmount = (190.0 + 12.0) * 3; 
    final target = isRight ? current + scrollAmount : current - scrollAmount;
    
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: widget.isHot ? Border.all(color: HomeScreen.themePrimaryRed, width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.headerColor, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    widget.title,
                    style: GoogleFonts.roboto(
                      fontSize: 20, 
                      fontWeight: FontWeight.w800, 
                      color: HomeScreen.cpsTextBlack
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                    child: const Row(
                      children: [
                        Text("Xem tất cả"),
                        Icon(Icons.keyboard_arrow_right, size: 16)
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content List with Arrows
            SizedBox(
              height: 330, // Chiều cao container list
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: widget.products.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return HoverProductCard(product: widget.products[index]);
                    },
                  ),
                  
                  // Arrow Left
                  if (_canScrollLeft && kIsWeb)
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      child: Center(
                        child: _buildArrowButton(Icons.chevron_left, () => _scroll(false)),
                      ),
                    ),
                  
                  // Arrow Right
                  if (_canScrollRight && kIsWeb)
                    Positioned(
                      right: 0, top: 0, bottom: 0,
                      child: Center(
                        child: _buildArrowButton(Icons.chevron_right, () => _scroll(true)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))
        ]
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black54),
        onPressed: onTap,
        hoverColor: Colors.grey.shade100,
      ),
    );
  }
}

// ==========================================
// WIDGET: CARD SẢN PHẨM CÓ HIỆU ỨNG HOVER
// ==========================================
class HoverProductCard extends StatefulWidget {
  final Product product;
  final bool isHotContext; // Thêm biến này để biết đang ở trong background đỏ hay không

  const HoverProductCard({super.key, required this.product, this.isHotContext = false});

  @override
  State<HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<HoverProductCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: p.id)));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220, // Rộng hơn một chút để chứa thông tin
          transform: _isHovering ? Matrix4.translationValues(0, -5, 0) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            // Viền đỏ nếu hover, không thì viền trắng hoặc không viền
            border: Border.all(
              color: _isHovering ? HomeScreen.themePrimaryRed : Colors.transparent
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 35), // Chừa chỗ cho tag giảm giá/trả góp

                  // 1. ẢNH SẢN PHẨM
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: _buildProductImage(p.thumbnailUrl),
                      ),
                    ),
                  ),

                  // 2. THÔNG SỐ KỸ THUẬT GIẢ LẬP (Giống ảnh)
                  // Vì model Product chưa chắc có field này, ta fix cứng UI demo hoặc lấy từ description
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                    child: const Text("Core i5 • 16GB • 512GB SSD", 
                      style: TextStyle(fontSize: 10, color: Colors.black87), textAlign: TextAlign.center
                    ),
                  ),

                  // 3. THÔNG TIN CHI TIẾT
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tên sản phẩm
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, height: 1.3, color: Color(0xFF333333)
                            ),
                          ),
                          
                          // Giá tiền
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.salePriceText,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HomeScreen.themePrimaryRed),
                              ),
                              Row(
                                children: [
                                  Text(
                                    NumberFormat("#,##0₫", "vi_VN").format(p.displayPrice * 1.2),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          ),
                          
                          // Rating & Tim
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                              const SizedBox(width: 4),
                              Text("${p.averageRating > 0 ? p.averageRating : 4.9}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              // Nút Yêu thích (Tim)
                              Row(
                                children: [
                                  Icon(Icons.favorite_border, size: 16, color: Colors.blue.shade600),
                                  const SizedBox(width: 4),
                                  Text("Yêu thích", style: TextStyle(fontSize: 12, color: Colors.blue.shade600))
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

              // TAG: GIẢM GIÁ (Trái)
              Positioned(
                top: 0, left: 10,
                child: Container(
                  width: 50, height: 26,
                  decoration: const BoxDecoration(
                    color: HomeScreen.themePrimaryRed,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(6))
                  ),
                  alignment: Alignment.center,
                  child: const Text("Giảm 11%", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),

              // TAG: TRẢ GÓP 0% (Phải)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text("Trả góp 0%", style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? url) {
    if (url == null || url.isEmpty) {
      return Image.asset('assets/images/placeholder.png', fit: BoxFit.contain);
    }
    return Image.network(url, fit: BoxFit.contain, errorBuilder: (_,__,___) => Image.asset('assets/images/placeholder.png'));
  }
}