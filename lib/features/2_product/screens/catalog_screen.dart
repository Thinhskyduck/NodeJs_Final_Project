import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import 'product_detail.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialSearch;
  final String? categoryId;

  const CatalogScreen({super.key, this.initialSearch, this.categoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;

  // --- PAGINATION STATE ---
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _limit = 12; // Số sản phẩm mỗi trang

  // --- FILTER STATE ---
  String _sortBy = "-createdAt";
  RangeValues _priceRange = const RangeValues(0, 50000000);
  final double _maxPriceLimit = 100000000;
  final List<String> _brands = ["Acer", "Asus", "Dell", "HP", "Apple", "Samsung", "MSI", "Lenovo"];
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // Gọi hàm MỚI hỗ trợ trả về totalPages
      final result = await _apiService.fetchProductsForCatalog(
        limit: _limit,
        page: _currentPage, // Truyền trang hiện tại
        search: widget.initialSearch,
        categoryId: widget.categoryId,
        sortBy: _sortBy,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        brand: _selectedBrand,
      );

      if (mounted) {
        setState(() {
          _products = result['products'];
          _totalPages = result['totalPages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi catalog: $e");
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fetchProducts();
  }

  // Widget hiển thị thanh phân trang
  Widget _buildPaginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
        ),
        // Hiển thị các số trang
        Wrap(
          children: List.generate(_totalPages, (index) {
            final page = index + 1;
            final isCurrent = page == _currentPage;
            return InkWell(
              onTap: () => _onPageChanged(page),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$page",
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
        ),
      ],
    );
  }

  // ... (Giữ nguyên _buildFilterDrawer và _buildProductCard cũ) ...
  Widget _buildFilterDrawer() {
     // ... Copy code Drawer cũ vào đây ...
     // (Để ngắn gọn tôi không paste lại đoạn Drawer, bạn giữ nguyên code cũ)
     return Drawer(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("BỘ LỌC TÌM KIẾM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const Text("Khoảng giá:", style: TextStyle(fontWeight: FontWeight.bold)),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: _maxPriceLimit,
              divisions: 20,
              labels: RangeLabels(
                NumberFormat.compact().format(_priceRange.start),
                NumberFormat.compact().format(_priceRange.end),
              ),
              onChanged: (RangeValues values) {
                setState(() => _priceRange = values);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(NumberFormat("#,##0").format(_priceRange.start)),
                Text(NumberFormat("#,##0").format(_priceRange.end)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Thương hiệu:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _brands.map((brand) {
                return FilterChip(
                  label: Text(brand),
                  selected: _selectedBrand == brand,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedBrand = selected ? brand : null;
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _currentPage = 1; // Reset về trang 1 khi lọc
                  _fetchProducts();
                },
                child: const Text("ÁP DỤNG"),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductCard(Product product) {
      // ... Copy code Card cũ vào đây ...
      return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: product.id))),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Image.network(
                    product.thumbnailUrl, 
                    fit: BoxFit.contain,
                    errorBuilder: (c,e,s) => const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.salePriceText, 
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                     const Icon(Icons.star, size: 14, color: Colors.amber),
                     Text(" ${product.averageRating.toStringAsFixed(1)}"),
                  ])
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildFilterDrawer(),
      appBar: AppBar(
        title: const Text("Danh sách sản phẩm"),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              tooltip: "Bộ lọc",
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _sortBy,
            dropdownColor: Colors.black,
            underline: Container(),
            icon: const Icon(Icons.sort, color: Colors.white),
            style: const TextStyle(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                   _sortBy = newValue;
                   _currentPage = 1; // Reset về trang 1 khi sort
                });
                _fetchProducts();
              }
            },
            selectedItemBuilder: (BuildContext context) {
              return [
                const Center(child: Text("Mới nhất", style: TextStyle(color: Colors.white))),
                const Center(child: Text("Giá tăng dần", style: TextStyle(color: Colors.white))),
                const Center(child: Text("Giá giảm dần", style: TextStyle(color: Colors.white))),
                const Center(child: Text("Tên A-Z", style: TextStyle(color: Colors.white))),
                const Center(child: Text("Tên Z-A", style: TextStyle(color: Colors.white))),
              ];
            },
            items: const [
              DropdownMenuItem(value: '-createdAt', child: Text("Mới nhất")),
              DropdownMenuItem(value: 'price', child: Text("Giá tăng dần")),
              DropdownMenuItem(value: '-price', child: Text("Giá giảm dần")),
              DropdownMenuItem(value: 'name', child: Text("Tên A-Z")),
              DropdownMenuItem(value: '-name', child: Text("Tên Z-A")),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _products.isEmpty
                      ? const Center(child: Text("Không tìm thấy sản phẩm nào."))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
                        ),
                ),
                // THANH PHÂN TRANG Ở ĐÂY
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  color: Colors.white,
                  child: _buildPaginationBar(),
                )
              ],
            ),
    );
  }
}