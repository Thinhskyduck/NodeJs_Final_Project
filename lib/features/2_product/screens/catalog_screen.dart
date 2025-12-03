import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import các file core/data
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../layout/header.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../5_profile/screens/profile_screen.dart';
import 'product_detail.dart';
import '../../1_home/screens/home_screen.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialSearch;
  final String? categoryId;

  const CatalogScreen({super.key, this.initialSearch, this.categoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();

  late TextEditingController _searchController;

  // --- DATA STATE ---
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _currentUserData;
  int _cartItemCount = 0;

  bool _isLoading = true;

  // --- PAGINATION (UPDATED LIMIT = 15) ---
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _limit = 15; // <--- Đã sửa thành 15

  // --- FILTER & SORT STATE ---
  String _sortBy = "-createdAt";
  // Range giá mặc định (0 -> 100 triệu)
  RangeValues _priceRange = const RangeValues(0, 100000000); 
  final double _maxPriceLimit = 100000000;
  
  String? _selectedBrand;
  String? _selectedCategoryId;

  // Hover state cho Web
  int? _hoveredIndex;

  final List<String> _brandsList = [
    "Apple", "Asus", "Lenovo", "MSI", "Acer", "HP", "Dell", "LG", "Gigabyte", "Samsung"
  ];

  // --- THEME COLORS ---
  static const Color _cpsRedPrimary = Color(0xFFD70018);
  static const Color _bgGray = Color(0xFFF4F6F8);
  static const Color _textBlack = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch ?? "");
    if (widget.categoryId != null) {
      _selectedCategoryId = widget.categoryId;
    }
    _initAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAllData() async {
    setState(() => _isLoading = true);
    await _fetchHeaderData();
    await _fetchProducts();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchHeaderData() async {
    try {
      final categories = await _apiService.getCategories();
      final user = await _apiService.getUserProfile();
      Map<String, dynamic>? userData;
      if (user != null) {
        userData = {
          'full_name': user.fullName,
          'email': user.email,
          'user_id': user.id,
        };
      }
      final cartItems = await _cartService.getCartItems();

      if (mounted) {
        setState(() {
          _categories = categories;
          _currentUserData = userData;
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      debugPrint("Lỗi header data: $e");
    }
  }

  Future<void> _fetchProducts() async {
    try {
      // Gọi API với đầy đủ tham số lọc
      final result = await _apiService.fetchProductsForCatalog(
        limit: _limit,
        page: _currentPage,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        categoryId: _selectedCategoryId,
        sortBy: _sortBy,
        // Chỉ gửi min/max price nếu user đã thay đổi slider khác mặc định (hoặc gửi luôn cũng được tùy backend)
        minPrice: _priceRange.start, 
        maxPrice: _priceRange.end,
        brand: _selectedBrand == "MacBook" ? "Apple" : _selectedBrand,
      );

      if (mounted) {
        setState(() {
          if (result['products'] != null) {
            _products = (result['products'] as List).cast<Product>().toList();
          } else {
            _products = [];
          }
          _totalPages = result['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint("Lỗi catalog: $e");
    }
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _searchController.text = query;
      _currentPage = 1;
    });
    _fetchProducts();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchProducts();
  }

  // Helper để map Icon cho danh mục (Vì API trả về tên, ta tự map icon cho đẹp)
  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('laptop')) return Icons.laptop_mac;
    if (n.contains('pc') || n.contains('máy tính')) return Icons.computer;
    if (n.contains('màn')) return Icons.monitor;
    if (n.contains('chuột')) return Icons.mouse;
    if (n.contains('phím')) return Icons.keyboard;
    if (n.contains('nghe')) return Icons.headphones;
    if (n.contains('in')) return Icons.print;
    return Icons.grid_view; // Mặc định
  }

  // ================= UI WIDGETS =================

  // --- 1. GIAO DIỆN DANH MỤC MỚI (GIỐNG ẢNH) ---
  Widget _buildCategoryHeader() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    // Thêm mục "Tất cả" vào đầu list để render
    final List<Map<String, dynamic>> renderList = [
      {'_id': null, 'name': 'Tất cả'},
      ..._categories
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      width: double.infinity,
      height: 60, // Chiều cao cố định cho thanh bar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300), // Viền bo ngoài
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: renderList.length,
        itemBuilder: (context, index) {
          final cat = renderList[index];
          final bool isSelected = _selectedCategoryId == cat['_id'];
          final IconData icon = _getCategoryIcon(cat['name']);

          return Row(
            children: [
              // Item danh mục
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = cat['_id'];
                    _currentPage = 1;
                  });
                  _fetchProducts();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  // Nếu chọn: nền đỏ nhạt, viền đỏ. Nếu không: nền trắng
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFEE2E2) : Colors.transparent, // Đỏ rất nhạt
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                        ? Border.all(color: _cpsRedPrimary, width: 1.5) // Viền đỏ khi chọn
                        : null, 
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Margin để không dính sát viền container cha
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon, 
                        size: 20, 
                        color: isSelected ? _cpsRedPrimary : Colors.black87
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['name'],
                        style: TextStyle(
                          color: isSelected ? _cpsRedPrimary : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Vách ngăn (Divider) giữa các item
              // Chỉ hiện vách ngăn nếu không phải item cuối cùng
              if (index != renderList.length - 1)
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- 2. THANH FILTER & SORT ---
  Widget _buildUnifiedFilterBar() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Nút Bộ Lọc (Mở Drawer)
          InkWell(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: const [
                  Icon(Icons.filter_list_alt, size: 18, color: _textBlack),
                  SizedBox(width: 8),
                  Text("Bộ lọc", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Các chip Sort
          _buildSortChip("Mới nhất", "-createdAt"),
          const SizedBox(width: 8),
          _buildSortChip("Giá tăng dần", "price"),
          const SizedBox(width: 8),
          _buildSortChip("Giá giảm dần", "-price"),
          const SizedBox(width: 8),
          _buildSortChip("Tên A-Z", "name"), // Sort tên tăng
          const SizedBox(width: 8),
          _buildSortChip("Tên Z-A", "-name"), // Sort tên giảm
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String sortValue) {
    final isSelected = _sortBy == sortValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: _cpsRedPrimary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? _cpsRedPrimary : Colors.black54,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? _cpsRedPrimary : Colors.grey.shade300)
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _sortBy = sortValue;
            _currentPage = 1;
          });
          _fetchProducts();
        }
      },
    );
  }

  // --- 3. FILTER DRAWER (FIXED LOGIC) ---
  Widget _buildFilterDrawer() {
     return Drawer(
      width: 340,
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Drawer
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            color: _cpsRedPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("BỘ LỌC TÌM KIẾM", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                )
              ],
            ),
          ),
          
          // Body Drawer
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("KHOẢNG GIÁ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 10),
                  
                  // Slider Giá
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: _maxPriceLimit,
                    activeColor: _cpsRedPrimary,
                    inactiveColor: Colors.grey.shade200,
                    divisions: 100, // Chia nhỏ bước nhảy
                    labels: RangeLabels(
                      NumberFormat.compact().format(_priceRange.start),
                      NumberFormat.compact().format(_priceRange.end),
                    ),
                    onChanged: (RangeValues values) {
                      setState(() => _priceRange = values);
                    },
                  ),
                  
                  // Hiển thị số tiền cụ thể
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(NumberFormat("#,##0đ").format(_priceRange.start), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(NumberFormat("#,##0đ").format(_priceRange.end), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 40),
                  
                  const Text("THƯƠNG HIỆU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _brandsList.map((brand) {
                      return FilterChip(
                        label: Text(brand),
                        selected: _selectedBrand == brand,
                        selectedColor: _cpsRedPrimary.withOpacity(0.1),
                        checkmarkColor: _cpsRedPrimary,
                        labelStyle: TextStyle(color: _selectedBrand == brand ? _cpsRedPrimary : Colors.black87, fontWeight: FontWeight.w600),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedBrand = selected ? brand : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset filter về mặc định
                      setState(() {
                        _priceRange = const RangeValues(0, 100000000);
                        _selectedBrand = null;
                      });
                    }, 
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    child: const Text("Thiết lập lại", style: TextStyle(color: Colors.black54)),
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Đóng Drawer
                      Navigator.pop(context);
                      // Reset về trang 1 và gọi API lại với params mới
                      setState(() => _currentPage = 1);
                      _fetchProducts(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cpsRedPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Xem kết quả", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 4. PRODUCT CARD ---
  Widget _buildProductCard(Product product, {required int index}) {
    final isHovered = _hoveredIndex == index && index != -1;
    final int originalPrice = (product.displayPrice * 1.1).round();

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: product.id))),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: isHovered 
              ? (Matrix4.identity()..translate(0, -5, 0)) 
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isHovered ? _cpsRedPrimary.withOpacity(0.5) : Colors.transparent),
            boxShadow: isHovered
              ? [BoxShadow(color: _cpsRedPrimary.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Image.asset(
                      product.thumbnailUrl, 
                      fit: BoxFit.contain,
                      errorBuilder: (c,e,s) => Image.asset('assets/images/placeholder.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              // Thông tin
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis, 
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: 13, 
                          height: 1.3, 
                          color: _textBlack
                        )
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.salePriceText, 
                            style: GoogleFonts.roboto(color: _cpsRedPrimary, fontWeight: FontWeight.w800, fontSize: 15)
                          ),
                          Row(
                            children: [
                              Text(
                                NumberFormat("#,##0₫", "vi_VN").format(originalPrice),
                                style: GoogleFonts.roboto(color: Colors.grey.shade400, decoration: TextDecoration.lineThrough, fontSize: 11)
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(2)),
                                child: const Text("-10%", style: TextStyle(fontSize: 9, color: _cpsRedPrimary, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ],
                      ),
                      Row(children: [
                         const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                         const SizedBox(width: 4),
                         Text("${product.averageRating > 0 ? product.averageRating : 5.0}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                         Text(" (${product.numReviews})", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ])
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. PAGINATION ---
  Widget _buildPaginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
          ),
          Wrap(
            spacing: 8,
            children: List.generate(_totalPages, (index) {
              final page = index + 1;
              final isCurrent = page == _currentPage;
              
              if (_totalPages > 7 && !isCurrent && (page > _currentPage + 2 || page < _currentPage - 2) && page != 1 && page != _totalPages) {
                  if (page == _currentPage + 3 || page == _currentPage - 3) {
                    return const Padding(padding: EdgeInsets.only(top: 8), child: Text("...", style: TextStyle(color: Colors.grey)));
                  }
                  return const SizedBox.shrink();
              }

              return InkWell(
                onTap: () => _onPageChanged(page),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? _cpsRedPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isCurrent ? _cpsRedPrimary : Colors.grey.shade300)
                  ),
                  child: Text(
                    "$page",
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.black54,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWebDesktop = kIsWeb && MediaQuery.of(context).size.width > 800;

    return Scaffold(
      key: _scaffoldKey, // Key để mở Drawer
      backgroundColor: _bgGray,
      endDrawer: _buildFilterDrawer(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _categories,
          currentUserData: _currentUserData,
          cartItemCount: _cartItemCount,
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
          onSearchSubmitted: _onSearchSubmitted,
        ),
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _cpsRedPrimary))
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb giả lập
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: const [
                            Icon(Icons.home, size: 16, color: Colors.grey),
                            SizedBox(width: 5),
                            Text("Trang chủ", style: TextStyle(color: Colors.grey)),
                            Text(" / ", style: TextStyle(color: Colors.grey)),
                            Text("Sản phẩm", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // DANH MỤC NGANG (STYLE MỚI)
                      _buildCategoryHeader(),

                      // FILTER BAR & SORT
                      _buildUnifiedFilterBar(),

                      const SizedBox(height: 10),

                      _products.isEmpty
                          ? Container(
                              height: 300,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text("Không tìm thấy sản phẩm phù hợp.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: isWebDesktop ? 230 : 200,
                                childAspectRatio: 0.62,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (ctx, i) => _buildProductCard(_products[i], index: i),
                            ),
                      
                      _buildPaginationBar(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}