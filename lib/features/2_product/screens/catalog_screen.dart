import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';
import 'product_detail.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialSearch;
  final int? categoryId;

  const CatalogScreen({super.key, this.initialSearch, this.categoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;
  
  // State cho Filter & Sort
  String _sortBy = "newest"; 
  
  // State cho Pagination
  int _currentPage = 1;
  final int _limit = 10; // Giới hạn 10 sp/trang để dễ test phân trang
  bool _hasMore = true; // Biến kiểm tra xem còn dữ liệu không (nếu API không trả về totalPages)

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Khi thay đổi bộ lọc hoặc trang, gọi lại hàm này
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      String? sortParam;
      // Mapping theo yêu cầu backend
      switch (_sortBy) {
        case 'price_asc': sortParam = 'price'; break;
        case 'price_desc': sortParam = '-price'; break;
        case 'name_asc': sortParam = 'name'; break; // Giả sử backend hỗ trợ sort name
        case 'name_desc': sortParam = '-name'; break;
        default: sortParam = '-createdAt'; // Mặc định là mới nhất
      }

      final products = await _apiService.fetchProducts(
        limit: _limit,
        page: _currentPage, // Truyền trang hiện tại
        search: widget.initialSearch,
        sortBy: sortParam,
        categoryId: widget.categoryId,
      );
      
      if (mounted) {
        setState(() {
          _products = products;
          // Logic kiểm tra đơn giản: nếu số lượng trả về < limit thì là hết trang
          _hasMore = products.length == _limit; 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changePage(int newPage) {
    if (newPage < 1) return;
    setState(() {
      _currentPage = newPage;
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tất cả sản phẩm"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Dropdown Sort mở rộng thêm Name A-Z, Z-A
          DropdownButton<String>(
            dropdownColor: Colors.blue,
            value: _sortBy,
            icon: const Icon(Icons.sort, color: Colors.white),
            underline: Container(),
            style: const TextStyle(color: Colors.white),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _sortBy = newValue;
                  _currentPage = 1; // Reset về trang 1 khi sort lại
                });
                _fetchProducts();
              }
            },
            items: const [
              DropdownMenuItem(value: 'newest', child: Text("Mới nhất")),
              DropdownMenuItem(value: 'price_asc', child: Text("Giá tăng dần")),
              DropdownMenuItem(value: 'price_desc', child: Text("Giá giảm dần")),
              DropdownMenuItem(value: 'name_asc', child: Text("Tên A-Z")),
              DropdownMenuItem(value: 'name_desc', child: Text("Tên Z-A")),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Danh sách sản phẩm
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text("Không tìm thấy sản phẩm"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Trên Web có thể tăng lên 4 hoặc 5 tùy màn hình
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
                      ),
          ),
          
          // Thanh Phân Trang (Pagination Bar)
          if (!_isLoading && _products.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(5)
                    ),
                    child: Text(
                      "Trang $_currentPage",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _hasMore ? () => _changePage(_currentPage + 1) : null,
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen2(productId: product.id))),
      child: Card(
        elevation: 2,
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}