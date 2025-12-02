import 'package:cross_platform_mobile_app_development/core/constants/app_constants.dart';
import 'package:cross_platform_mobile_app_development/data/services/api_service.dart';
import 'package:cross_platform_mobile_app_development/features/1_home/screens/home_screen.dart';
import 'package:cross_platform_mobile_app_development/features/5_profile/screens/order_history_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Nếu cần gọi API /checkout
import 'package:intl/intl.dart';
import 'dart:convert'; // Nếu cần gọi API /checkout

import 'package:cross_platform_mobile_app_development/layout/header.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../services/api_service.dart'; // Nếu có service cho API /checkout

// Giữ AppColors ở đây hoặc chuyển ra file riêng
class AppColors {
  static const Color themePageBackground = Color(0xFFF0F2F5);
  static const Color primaryRed = Color(0xFF007BFF); // Đã đổi màu
  static const Color textBlack = Color(0xFF222222);
  static const Color textGrey = Color(0xFF4A4A4A);
  static const Color textLightGrey = Color(0xFF757575);
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color lightGreyBackground = Color(0xFFF8F8F8);
  static const Color sNullTagBackground = Color(0xFFFFE0E6); // Giữ màu cũ hoặc đổi
  static const Color sNullTagText = Color(0xFFD32F2F); // Giữ màu cũ hoặc đổi
  static const Color linkBlue = Color(0xFF007AFF);
}

class CheckoutPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> previewOrderData; // Nhận response từ /preview
  final String? guestEmail; // Nhận từ CheckoutInfoScreen
  final String userId;
  // Nhận từ CheckoutInfoScreen

  // final String paymentMethodForCheckout; // Nếu cần truyền riêng
  // final String notesForCheckout; // Nếu cần
  // final String couponCodeForCheckout; // Nếu cần
  // final int loyaltyPointsUsedForCheckout; // Nếu cần


  const CheckoutPaymentScreen({
    super.key,
    required this.previewOrderData,
    this.guestEmail,
    required this.userId,
    // required this.paymentMethodForCheckout,
    // required this.notesForCheckout,
    // required this.couponCodeForCheckout,
    // required this.loyaltyPointsUsedForCheckout,
  });

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'category_id': 1, 'name': 'Điện thoại'},
    {'category_id': 2, 'name': 'Laptop'},
  ];
  Map<String, dynamic>? _currentUserData; // Sẽ lấy một phần từ previewOrderData
  
  // Các thông tin đơn hàng sẽ lấy từ widget.previewOrderData
  // late Map<String, dynamic> _orderSummary;
  // late Map<String, dynamic> _shippingInfo;

  List<dynamic> get _orderItems => widget.previewOrderData['items'] as List? ?? [];
  List<Map<String, dynamic>> _detailedOrderItems = []; // Sẽ chứa product_name
  bool _isLoadingProductNames = true; // Trạng thái loading cho tên sản phẩm
  int get _cartItemCount => _detailedOrderItems.length; // Dùng _detailedOrderItems

  // String _discountCode = ""; // Sẽ lấy từ previewOrderData nếu có
  bool _agreeToTerms = false;
  bool _isLoadingCheckout = false; // State cho việc gọi API /checkout
  String? _checkoutErrorMessage;


  @override
  void initState() {
    super.initState();
    _currentUserData = {
      'full_name': widget.previewOrderData['recipient_name'] ?? 'Khách hàng',
      'phone': widget.previewOrderData['recipient_phone'] ?? '',
      'email': widget.guestEmail ?? '',
    };
    // KHÔNG gọi API load tên sản phẩm nữa vì dữ liệu đã có đủ
  }

  Future<void> _initializeOrderItemsWithProductNames() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProductNames = true;
    });

    final rawOrderItems = widget.previewOrderData['items'] as List<dynamic>? ?? [];
    List<Map<String, dynamic>> tempDetailedItems = [];

    for (var rawItem in rawOrderItems) {
      if (rawItem is Map<String, dynamic>) {
        final variantId = rawItem['variant_id'] as int?;
        String? productName;
        String variantName = (rawItem['variant'] as Map<String, dynamic>?)?['variant_name'] ?? 'N/A';

        if (variantId != null) {
          try {
            // Gọi API lấy chi tiết variant (bao gồm product_name)
            final response = await http.get(
              Uri.parse('${AppConstants.baseUrl}/variants/$variantId/price'),
              headers: {'accept': 'application/json'},
            ).timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              productName = data['product_name'] as String?;
              // Cập nhật variant_name nếu API trả về (để đảm bảo đồng nhất)
              // variantName = data['variant_name'] as String? ?? variantName;
            } else {
              print('Failed to fetch product name for variant $variantId: ${response.statusCode}');
            }
          } catch (e) {
            print('Error fetching product name for variant $variantId: $e');
          }
        }
        // Tạo item mới với product_name
        tempDetailedItems.add({
          ...rawItem, // Giữ lại các trường cũ từ previewOrderData
          'product_name': productName ?? 'Sản phẩm không có tên', // Thêm product_name
          // 'display_name': productName != null ? '$productName - $variantName' : variantName, // Tên để hiển thị
        });
      }
    }

    if (mounted) {
      setState(() {
        _detailedOrderItems = tempDetailedItems;
        _isLoadingProductNames = false;
      });
    }
  }

  void _navigateToCatalog(int categoryId, String categoryName) {
    print('Payment: Navigating to category: $categoryName (ID: $categoryId)');
  }

  void _onCartPressed() {
    // Có thể quay lại màn hình Cart nếu cần, hoặc không làm gì
    int count = 0;
    Navigator.of(context).popUntil((_) => count++ >= 2); // Quay lại 2 màn hình
  }

  void _onAccountPressed() {
    print('Payment: Account pressed');
  }

  // Bỏ _applyDiscountCode vì mã giảm giá đã được áp dụng ở API /preview
  // void _applyDiscountCode() { ... }  

  Future<void> _finalizeOrder() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản sử dụng.')),
      );
      return;
    }

    setState(() {
      _isLoadingCheckout = true;
      _checkoutErrorMessage = null;
    });

    try {
      final String checkoutApiUrl = '${AppConstants.baseUrl}/orders'; // API User
      final String guestCheckoutUrl = '${AppConstants.baseUrl}/orders/guest'; // API Guest
      
      http.Response response;
      
      // 1. Lấy mã giảm giá và điểm
      String couponCode = "";
      if (widget.previewOrderData['applied_coupon'] != null) {
        couponCode = widget.previewOrderData['applied_coupon']['code'];
      }
      int pointsUsed = widget.previewOrderData['loyalty_points_used'] ?? 0;

      // 2. Logic gọi API
      if (widget.userId.isNotEmpty) { 
         // --- USER CHECKOUT ---
         final prefs = await SharedPreferences.getInstance();
         final token = prefs.getString(AppConstants.tokenKey);

         response = await http.post(
            Uri.parse(checkoutApiUrl),
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'shippingAddress': {
                'addressLine': widget.previewOrderData['shipping_address'],
                'city': 'Vietnam', 
                'postalCode': '70000',
                'country': 'Vietnam'
              },
              'paymentMethod': widget.previewOrderData['payment_method'],
              'discountCode': couponCode,
              
              // [SỬA 1]: Gửi số điểm cụ thể, đổi tên key thành pointsToUse
              'pointsToUse': pointsUsed, 
            }),
         );
      } else {
         // --- GUEST CHECKOUT ---
         List<dynamic> rawItems = widget.previewOrderData['items'];
         List<Map<String, dynamic>> guestItems = rawItems.map((item) => {
            "product": item['product_id'],
            "variant": item['variant_id'],
            "quantity": item['quantity'],
            "price": item['price_at_purchase'],
            "name": item['variant']['name'], 
            "image": item['variant']['image_url'] 
         }).toList();

         response = await http.post(
            Uri.parse(guestCheckoutUrl),
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fullName': widget.previewOrderData['recipient_name'],
              'email': widget.guestEmail,
              'shippingAddress': {
                'addressLine': widget.previewOrderData['shipping_address'],
                'city': 'Vietnam', 
                'postalCode': '70000',
                'country': 'Vietnam'
              },
              'paymentMethod': widget.previewOrderData['payment_method'],
              'cartItems': guestItems,
              
              // [SỬA 2]: Bổ sung gửi mã giảm giá cho Guest (nếu có)
              'discountCode': couponCode, 
            }),
         );
      }

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Xóa giỏ hàng local nếu là guest
          if (widget.userId.isEmpty) {
             final prefs = await SharedPreferences.getInstance();
             await prefs.remove('LOCAL_CART_DATA');
          }
          
          final responseData = jsonDecode(response.body);
          _showSuccessDialog(responseData); 

        } else {
          final errorData = jsonDecode(response.body);
          setState(() {
            _checkoutErrorMessage = errorData['message'] ?? 'Đặt hàng thất bại';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkoutErrorMessage = 'Lỗi kết nối: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCheckout = false;
        });
      }
    }
  }

  // Hiển thị dialog thành công và thông tin đơn hàng
  void _showSuccessDialog(dynamic responseData) {
    String orderId = "Unknown";
    if (responseData is Map) {
       if (responseData['order'] != null) orderId = responseData['order']['_id'] ?? "";
       else if (responseData['_id'] != null) orderId = responseData['_id'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Đặt hàng thành công!", style: TextStyle(color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Mã đơn hàng: #${orderId.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)), // Rút gọn mã cho đẹp
            const SizedBox(height: 10),
            const Text("Cảm ơn bạn đã mua sắm.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst); // Về trang chủ
            },
            child: const Text("Về trang chủ"),
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.of(ctx).pop(); // Đóng dialog
               
               // Reset stack về Home rồi đẩy History lên (để user bấm Back từ History sẽ về Home chứ ko về Checkout)
               Navigator.of(context).pushAndRemoveUntil(
                 MaterialPageRoute(builder: (_) => const HomeScreen()),
                 (route) => false,
               );
               
               // Chuyển tới lịch sử đơn hàng
               Navigator.of(context).push(
                 MaterialPageRoute(builder: (_) => const OrderHistoryScreen())
               );
            },
            child: const Text("Xem đơn hàng"),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.themePageBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          kIsWeb ? (screenWidth > 900 ? 60 : 50) : 45 + MediaQuery.of(context).padding.top,
        ),
        child: CustomHeader(
          categories: _categories,
          currentUserData: _currentUserData, // Dùng _currentUserData đã khởi tạo
          cartItemCount: _cartItemCount,
          onCartPressed: _onCartPressed,
          onAccountPressed: _onAccountPressed,
          onCategorySelected: (Map<String, dynamic> selectedCategory) {
            final categoryId = selectedCategory['category_id'] as int?;
            final categoryName = selectedCategory['name'] as String?;
            if (categoryId != null && categoryName != null) {
              _navigateToCatalog(categoryId, categoryName);
            }
          },
          onLogoTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          onSearchSubmitted: (value) {
            print('Payment: Search submitted: $value');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: isDesktop ? 800 : double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row( // Nút Back và Tiêu đề
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
                      onPressed: () => Navigator.of(context).pop(), // Quay lại CheckoutInfoScreen
                    ),
                    Expanded(
                      child: Text(
                        "Xác nhận thanh toán", // Hoặc "Xác nhận đơn hàng"
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Để cân bằng IconButton
                  ],
                ),
                const SizedBox(height: 16),
                _buildStepIndicator(),
                const SizedBox(height: 24),
                _buildSectionTitle("DANH SÁCH SẢN PHẨM"),
                _buildOrderItemsList(),
                const SizedBox(height: 24),
                _buildSectionTitle("TÓM TẮT ĐƠN HÀNG"),
                _buildOrderSummaryCard(),
                const SizedBox(height: 24),
                _buildSectionTitle("THÔNG TIN THANH TOÁN"),
                _buildPaymentMethodDisplayCard(),
                const SizedBox(height: 24),
                _buildSectionTitle("THÔNG TIN NHẬN HÀNG"),
                _buildShippingInfoCard(),
                const SizedBox(height: 24),
                _buildTermsAndConditionsCheckbox(),
                const SizedBox(height: 32),
                _buildFinalizeOrderSection(), // Nút "Thanh toán" / "Đặt hàng"
                if (_checkoutErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _checkoutErrorMessage!,
                      style: GoogleFonts.montserrat(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildScrollToTopButton(),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem("1. THÔNG TIN", isActive: false),
          Container(
            width: 60,
            height: 1,
            color: AppColors.primaryRed, // Line active
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStepItem("2. THANH TOÁN", isActive: true),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, {required bool isActive}) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primaryRed : AppColors.textGrey,
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(width: 80, height: 2, color: AppColors.primaryRed),
        ]
      ],
    );
  }

  Widget _buildOrderItemsList() {
    if (_orderItems.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Không có sản phẩm.")));
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.lightGreyBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderItems.length,
          itemBuilder: (context, index) {
            final item = _orderItems[index];
            // Dữ liệu 'variant' được tạo bên CheckoutInfoScreen: {'name': ..., 'image_url': ...}
            final variantInfo = item['variant'] as Map<String, dynamic>?;
            final itemName = variantInfo?['name'] ?? "Sản phẩm";
            final imageUrl = variantInfo?['image_url'] ?? "";
            final price = double.tryParse(item['price_at_purchase']?.toString() ?? '0') ?? 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Image.asset(
                    imageUrl,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => const Icon(Icons.image, size: 60),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat("#,##0₫", "vi_VN").format(price),
                          style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text("x${item['quantity']}", style: GoogleFonts.montserrat(fontSize: 13)),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const Divider(),
        ),
      ),
    );
  }


  Widget _buildOrderSummaryCard() {
    String formatCurrency(double amount, {bool showSign = false}) {
      String sign = "";
      if (showSign && amount > 0) {
        sign = "-"; // Chỉ thêm dấu trừ nếu có giảm giá
      }
      String value = amount.abs().toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      return "$sign${value}đ";
    }

    final subtotal = double.tryParse(widget.previewOrderData['subtotal']?.toString() ?? '0') ?? 0.0;
    final shippingFee = double.tryParse(widget.previewOrderData['shipping_fee']?.toString() ?? '0') ?? 0.0;
    
    // <--- MỚI: Lấy thông tin giảm giá chi tiết
    final couponDiscount = double.tryParse(widget.previewOrderData['coupon_discount_amount']?.toString() ?? '0') ?? 0.0;
    final loyaltyDiscount = double.tryParse(widget.previewOrderData['loyalty_discount_amount']?.toString() ?? '0') ?? 0.0;
    
    final totalAmount = double.tryParse(widget.previewOrderData['total_amount']?.toString() ?? '0') ?? 0.0;
    final String? appliedCouponCode = (widget.previewOrderData['applied_coupon'] as Map<String, dynamic>?)?['code'] as String?;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.lightGreyBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow("Số lượng sản phẩm", _cartItemCount.toString()),
            _buildSummaryRow("Tiền hàng (tạm tính)", formatCurrency(subtotal)),
            _buildSummaryRow(
                "Phí vận chuyển",
                shippingFee == 0.0 ? "Miễn phí" : formatCurrency(shippingFee)),

            // <--- MỚI: Hiển thị dòng giảm giá Coupon
            if (couponDiscount > 0.0)
              _buildSummaryRow(
                "Mã giảm giá ${appliedCouponCode != null ? '($appliedCouponCode)' : ''}",
                formatCurrency(couponDiscount, showSign: true),
                valueColor: Colors.green, // Màu xanh cho giảm giá
              ),
              
            // <--- MỚI: Hiển thị dòng giảm giá Điểm
            if (loyaltyDiscount > 0.0)
              _buildSummaryRow(
                "Tiêu điểm tích lũy",
                formatCurrency(loyaltyDiscount, showSign: true),
                valueColor: Colors.green, // Màu xanh cho giảm giá
              ),
              
            const Divider(height: 20),
            _buildSummaryRow(
              "Tổng tiền",
              formatCurrency(totalAmount),
              isTotal: true,
              subtitle: "(đã gồm VAT)",
            ),
            
            // Hiển thị điểm nhận được
            if (widget.previewOrderData['items'] != null) ...[
               const SizedBox(height: 8),
               // Tính tạm điểm nhận được (Backend tính: itemsPrice / 10000)
               // Ở đây ta hiển thị ước tính
                _buildSummaryRow(
                "Điểm tích lũy nhận được",
                "+${(subtotal / 10000).floor()} điểm",
                valueColor: Colors.orange[700],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? valueColor, bool isTotal = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: isTotal ? 14 : 13,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textGrey,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AppColors.textLightGrey,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? (isTotal ? AppColors.primaryRed : AppColors.textBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textBlack,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDisplayCard() {
    final paymentMethod = widget.previewOrderData['payment_method'] as String? ?? "Chưa chọn";
    // Icon có thể dựa trên paymentMethod
    String paymentIconAsset = 'assets/images/payment_icon.png'; // default
    if (paymentMethod.toLowerCase().contains('tiền mặt')) {
      paymentIconAsset = 'assets/images/cash_icon.png'; // Cần có icon này
    } else if (paymentMethod.toLowerCase().contains('chuyển khoản')) {
      paymentIconAsset = 'assets/images/bank_transfer_icon.png'; // Cần có icon này
    } else if (paymentMethod.toLowerCase().contains('thẻ')) {
      paymentIconAsset = 'assets/images/card_icon.png'; // Cần có icon này
    }


    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.lightGreyBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Image.asset( // Hoặc Icon
              paymentIconAsset,
              width: 32,
              height: 32,
              errorBuilder: (c, e, s) => Icon(Icons.payment, size: 32, color: AppColors.primaryRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paymentMethod,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed),
                  ),
                  // Text( // Thông tin thêm nếu có
                  //   "Giảm thêm tới 1.000.000đ",
                  //   style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textGrey),
                  // ),
                ],
              ),
            ),
            // Không cần Icon chevron_right nếu đây chỉ là hiển thị
            // const Icon(Icons.chevron_right, color: AppColors.textLightGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    // Lấy thông tin từ widget.previewOrderData
    final String name = widget.previewOrderData['recipient_name'] ?? 'N/A';
    final String phone = widget.previewOrderData['recipient_phone'] ?? 'N/A';
    final String email = widget.guestEmail ?? (widget.previewOrderData['guest_email_from_api_if_any'] ?? 'N/A'); // Sử dụng guestEmail
    final String address = widget.previewOrderData['shipping_address'] ?? 'N/A';
    // Xác định deliveryType dựa trên shipping_address
    // Đây là ví dụ, bạn cần logic cụ thể hơn nếu địa chỉ cửa hàng có format đặc biệt
    final bool isStorePickup = address.toLowerCase().contains("cửa hàng") || address.toLowerCase().contains("store");
    final String deliveryTypeLabel = isStorePickup ? 'Nhận hàng tại' : 'Giao hàng đến';


    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.lightGreyBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShippingInfoRow("Khách hàng", name, isName: true,/* widget.previewOrderData['s_member_rank'] ?? '' */),
            _buildShippingInfoRow("Số điện thoại", phone),
            _buildShippingInfoRow("Email", email),
            _buildShippingInfoRow(deliveryTypeLabel, address),
            if (widget.previewOrderData['notes'] != null && (widget.previewOrderData['notes'] as String).isNotEmpty)
              _buildShippingInfoRow("Ghi chú", widget.previewOrderData['notes'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoRow(String label, String value,
      {bool isName = false, String? sMemberRank}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Điều chỉnh nếu cần
            child: Text(
              label,
              style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey),
            ),
          ),
          Expanded(
            child: Row( // Sử dụng Row để sMemberRank nằm cùng dòng
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded( // Text value có thể dài
                  child: Text(
                    value,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textBlack,
                        fontWeight: isName ? FontWeight.w600 : FontWeight.normal),
                  ),
                ),
                if (isName && sMemberRank != null && sMemberRank.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sNullTagBackground, // Cần định nghĩa
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sMemberRank,
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sNullTagText), // Cần định nghĩa
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (bool? value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: AppColors.primaryRed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textGrey, height: 1.4),
              children: [
                const TextSpan(text: "Hoàn thành kiểm tra thông tin?"),
                // const TextSpan(text: " của CellphoneS.\nVới các giao dịch trên 10 triệu..."), // Phần này có thể không cần ở đây nữa
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalizeOrderSection() {
    final totalAmount = double.tryParse(widget.previewOrderData['total_amount']?.toString() ?? '0') ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng thanh toán:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(NumberFormat("#,##0₫", "vi_VN").format(totalAmount), style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_agreeToTerms && !_isLoadingCheckout) ? _finalizeOrder : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _isLoadingCheckout 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text("XÁC NHẬN ĐẶT HÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToTopButton() {
    return FloatingActionButton(
      onPressed: () { /* Cần ScrollController */ },
      mini: true,
      backgroundColor: AppColors.primaryRed.withOpacity(0.9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
          Text("Lên đầu", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 7)),
        ],
      ),
      elevation: 4,
    );
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return "0đ";
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

// Helper để format tiền tệ, bạn có thể đã có trong intl
// Hoặc dùng NumberFormat như trong CartScreen cũ
NumberFormat get _currencyFormatter {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
}