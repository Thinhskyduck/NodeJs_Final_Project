// lib/features/2_product/screens/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import 'product_detail.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialSearch;
  final String? categoryId; // Sửa thành String cho đúng MongoDB ID

  const CatalogScreen({super.key, this.initialSearch, this.categoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;
  
  // State cho bộ lọc
  String _sortBy = "-createdAt"; // Mặc định: Mới nhất
  RangeValues _priceRange = const RangeValues(0, 50000000); // 0 - 50 triệu
  final double _maxPriceLimit = 100000000; // Max slider 100 triệu
  
  // Danh sách brand để lọc (Nên lấy từ API nếu có, ở đây hardcode demo)
  final List<String> _brands = ["Acer", "Asus", "Dell", "HP", "Apple", "Samsung"];
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.fetchProducts(
        limit: 12,
        page: 1, // Tạm thời page 1
        search: widget.initialSearch,
        categoryId: widget.categoryId,
        sortBy: _sortBy,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        brand: _selectedBrand,
      );
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi catalog: $e");
    }
  }
  
  // Widget hiển thị Panel bộ lọc
  Widget _buildFilterDrawer() {
    return Drawer(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("BỘ LỌC TÌM KIẾM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            
            // 1. Lọc theo giá
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
            
            // 2. Lọc theo Brand
            const Text("Thương hiệu:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _brands.map((brand) {
                return FilterChip(
                  label: Text(brand),
                  selected: _selectedBrand == brand,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedBrand = selected ? brand : null; // Chọn hoặc bỏ chọn
                    });
                  },
                );
              }).toList(),
            ),
            
            const Spacer(),
            
            // Nút Áp dụng
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng drawer
                  _fetchProducts(); // Gọi API lại
                },
                child: const Text("ÁP DỤNG"),
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
      endDrawer: _buildFilterDrawer(), // Drawer lọc bên phải
      appBar: AppBar(
        title: const Text("Danh sách sản phẩm"),
        actions: [
          // Nút mở bộ lọc
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              tooltip: "Bộ lọc",
            ),
          ),
          const SizedBox(width: 10),
          // Dropdown Sắp xếp
          DropdownButton<String>(
            value: _sortBy,
            dropdownColor: Colors.white,
            underline: Container(),
            icon: const Icon(Icons.sort, color: Colors.white),
            style: const TextStyle(color: Colors.black), // Sửa lại màu chữ nếu AppBar màu xanh
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _sortBy = newValue);
                _fetchProducts();
              }
            },
            selectedItemBuilder: (BuildContext context) {
              return [
                const Center(child: Text("Mới nhất", style: TextStyle(color: Colors.white))),
                const Center(child: Text("Giá tăng dần", style: TextStyle(color: Colors.white))),
                const Center(child: Text("Giá giảm dần", style: TextStyle(color: Colors.white))),
              ];
            },
            items: const [
              DropdownMenuItem(value: '-createdAt', child: Text("Mới nhất")),
              DropdownMenuItem(value: 'price', child: Text("Giá tăng dần")),
              DropdownMenuItem(value: '-price', child: Text("Giá giảm dần")),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _products.isEmpty 
          ? const Center(child: Text("Không tìm thấy sản phẩm nào."))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250, // Responsive cho Web
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
            ),
    );
  }

  // Card sản phẩm giữ nguyên logic cũ, chỉ chỉnh sửa UI một chút
  Widget _buildProductCard(Product product) {
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
}