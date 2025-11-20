import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import 'product_detail.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialSearch;
  final int? categoryId; // Nếu muốn lọc theo danh mục

  const CatalogScreen({super.key, this.initialSearch, this.categoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _sortBy = "newest"; 

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      String? sortParam;
      if (_sortBy == 'price_asc') sortParam = 'price';
      if (_sortBy == 'price_desc') sortParam = '-price';

      final products = await _apiService.fetchProducts(
        limit: 50, // Lấy nhiều hơn
        search: widget.initialSearch,
        sortBy: sortParam,
        categoryId: widget.categoryId,
      );
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tất cả sản phẩm"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Nút Sort trên AppBar
          DropdownButton<String>(
            dropdownColor: Colors.blue,
            value: _sortBy,
            icon: const Icon(Icons.sort, color: Colors.white),
            underline: Container(),
            style: const TextStyle(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _sortBy = newValue);
                _fetchProducts();
              }
            },
            items: const [
              DropdownMenuItem(value: 'newest', child: Text("Mới nhất")),
              DropdownMenuItem(value: 'price_asc', child: Text("Giá tăng dần")),
              DropdownMenuItem(value: 'price_desc', child: Text("Giá giảm dần")),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text("Không tìm thấy sản phẩm"))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
                ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: product.id))),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.network(
                  product.thumbnailUrl, 
                  fit: BoxFit.contain,
                  errorBuilder: (c,e,s) => const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(product.salePriceText, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}