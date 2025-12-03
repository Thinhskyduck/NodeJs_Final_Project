import 'package:cross_platform_mobile_app_development/core/constants/app_constants.dart';
import 'package:cross_platform_mobile_app_development/data/services/api_service.dart';
import 'package:cross_platform_mobile_app_development/features/1_home/screens/home_screen.dart';
import 'package:cross_platform_mobile_app_development/features/5_profile/screens/order_history_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:cross_platform_mobile_app_development/layout/header.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Local Style Constants ---
class CheckoutStyle {
  static const Color bg = Color(0xFFF5F5FA); // Nền xám xanh nhạt hiện đại
  static const Color white = Colors.white;
  static const Color primary = Color(0xFFD70018); // Đỏ CellphoneS
  static const Color textMain = Color(0xFF222222);
  static const Color textGrey = Color(0xFF666666);
  static const Color border = Color(0xFFEBEBEB);
  
  static TextStyle header = GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w700, color: textMain);
  static TextStyle title = GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600, color: textMain);
  static TextStyle body = GoogleFonts.roboto(fontSize: 14, color: textMain);
  static TextStyle label = GoogleFonts.roboto(fontSize: 13, color: textGrey);
}

class CheckoutPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> previewOrderData;
  final String? guestEmail;
  final String userId;

  const CheckoutPaymentScreen({
    super.key,
    required this.previewOrderData,
    this.guestEmail,
    required this.userId,
  });

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  // Mock Data cho Header
  final List<Map<String, dynamic>> _categories = [
    {'category_id': 1, 'name': 'Điện thoại'},
    {'category_id': 2, 'name': 'Laptop'},
  ];
  Map<String, dynamic>? _currentUserData;

  // Data Getters
  List<dynamic> get _orderItems => widget.previewOrderData['items'] as List? ?? [];
  int get _cartItemCount => _orderItems.length;

  // State Variables
  bool _agreeToTerms = false;
  bool _isLoadingCheckout = false;
  String? _checkoutErrorMessage;

  @override
  void initState() {
    super.initState();
    _currentUserData = {
      'full_name': widget.previewOrderData['recipient_name'] ?? 'Khách hàng',
      'phone': widget.previewOrderData['recipient_phone'] ?? '',
      'email': widget.guestEmail ?? '',
    };
  }

  // --- LOGIC FUNCTIONS (GIỮ NGUYÊN) ---

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
      final ApiService apiService = ApiService();
      final String checkoutApiUrl = '${AppConstants.baseUrl}/orders';
      final String guestCheckoutUrl = '${AppConstants.baseUrl}/orders/guest';

      http.Response response;

      // 1. Dữ liệu giảm giá & điểm
      String couponCode = "";
      if (widget.previewOrderData['applied_coupon'] != null) {
        couponCode = widget.previewOrderData['applied_coupon']['code'];
      }
      int pointsUsed = widget.previewOrderData['loyalty_points_used'] ?? 0;

      // 2. Gửi request tạo đơn
      if (widget.userId.isNotEmpty) {
        // User Checkout
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
            'pointsToUse': pointsUsed,
          }),
        );
      } else {
        // Guest Checkout
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
            'discountCode': couponCode,
          }),
        );
      }

      // 3. Kiểm tra kết quả
      if (!(response.statusCode == 200 || response.statusCode == 201)) {
        final errorData = jsonDecode(response.body);
        setState(() {
          _checkoutErrorMessage = errorData['message'] ?? 'Đặt hàng thất bại';
        });
        return;
      }

      final responseData = jsonDecode(response.body);
      String orderId = "";
      int totalAmount = 0;

      if (responseData['order'] != null) {
        orderId = responseData['order']['_id'];
        totalAmount = responseData['order']['totalPrice'];
      } else if (responseData['_id'] != null) {
        orderId = responseData['_id'];
        totalAmount = responseData['totalPrice'];
      }

      final paymentMethod = widget.previewOrderData['payment_method'].toString().toUpperCase();

      // 4. Xử lý VNPAY
      if (paymentMethod.contains('VNPAY') || paymentMethod.contains('ONLINE')) {
        final paymentUrl = await apiService.createPaymentUrl(
          orderId: orderId,
          amount: totalAmount,
        );

        if (paymentUrl == null) {
          setState(() => _checkoutErrorMessage = "Không thể tạo liên kết thanh toán.");
          return;
        }

        if (!mounted) return;
        if (widget.userId.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('LOCAL_CART_DATA');
        }

        final Uri uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_self');
        } else {
          setState(() => _checkoutErrorMessage = "Không thể mở trang thanh toán.");
        }
        return;
      }

      // 5. COD Thành công
      if (widget.userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('LOCAL_CART_DATA');
      }
      _showSuccessDialog(responseData);

    } catch (e) {
      setState(() => _checkoutErrorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCheckout = false);
    }
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            Text("Thành công!", style: CheckoutStyle.header.copyWith(color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Đơn hàng của bạn đã được khởi tạo.", textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text("Mã đơn: #${orderId.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Về trang chủ"),
          ),
          ElevatedButton(
            onPressed: () {
               Navigator.of(ctx).pop();
               Navigator.of(context).pushAndRemoveUntil(
                 MaterialPageRoute(builder: (_) => const HomeScreen()),
                 (route) => false,
               );
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: CheckoutStyle.primary, foregroundColor: Colors.white),
            child: const Text("Xem đơn hàng"),
          )
        ],
      ),
    );
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;
    
    // Parse Total Amount an toàn
    double totalAmount = 0.0;
    try {
      totalAmount = double.parse(widget.previewOrderData['total_amount'].toString());
    } catch (_) {}

    return Scaffold(
      backgroundColor: CheckoutStyle.bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? (screenWidth > 900 ? 60 : 50) : 45 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _categories,
          currentUserData: _currentUserData,
          cartItemCount: _cartItemCount,
          onCartPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), // Example logic
          onAccountPressed: () {},
          onLogoTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: isDesktop ? (screenWidth - 800) / 2 : 16,
              right: isDesktop ? (screenWidth - 800) / 2 : 16,
              top: 20,
              bottom: 120, // Space for BottomBar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb / Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 24),

                // Title
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text("Xác nhận thanh toán", style: CheckoutStyle.header.copyWith(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 20),

                // Layout chính: Thông tin bên trái, Tóm tắt bên phải (nếu Desktop)
                // Ở đây để đơn giản ta dùng Column, Card xếp dọc
                
                // 1. Thông tin giao hàng & Thanh toán
                _buildSectionCard(
                  title: "THÔNG TIN GIAO HÀNG",
                  icon: Icons.local_shipping_outlined,
                  child: _buildShippingInfo(),
                ),
                const SizedBox(height: 16),

                _buildSectionCard(
                  title: "PHƯƠNG THỨC THANH TOÁN",
                  icon: Icons.payment,
                  child: _buildPaymentMethod(),
                ),
                const SizedBox(height: 16),

                // 2. Danh sách sản phẩm
                _buildSectionCard(
                  title: "DANH SÁCH SẢN PHẨM",
                  icon: Icons.shopping_bag_outlined,
                  child: _buildProductList(),
                ),
                const SizedBox(height: 16),

                // 3. Chi tiết giá (Summary)
                _buildSectionCard(
                  title: "CHI TIẾT THANH TOÁN",
                  icon: Icons.receipt_long,
                  child: _buildOrderSummary(),
                ),
                const SizedBox(height: 16),

                // 4. Điều khoản
                _buildTermsCheckbox(),
                
                // Hiển thị lỗi nếu có
                if (_checkoutErrorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_checkoutErrorMessage!, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Fixed Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 16, 
                bottom: MediaQuery.of(context).padding.bottom + 16
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tổng thanh toán", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            NumberFormat("#,##0₫", "vi_VN").format(totalAmount),
                            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: CheckoutStyle.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_agreeToTerms && !_isLoadingCheckout) ? _finalizeOrder : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CheckoutStyle.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoadingCheckout
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("ĐẶT HÀNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIcon("1", "Thông tin", false),
        Container(width: 40, height: 2, color: CheckoutStyle.primary),
        _buildStepIcon("2", "Thanh toán", true),
        Container(width: 40, height: 2, color: Colors.grey[300]),
        _buildStepIcon("3", "Hoàn tất", false),
      ],
    );
  }

  Widget _buildStepIcon(String step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? CheckoutStyle.primary : (step == "1" ? CheckoutStyle.primary : Colors.grey[200]),
            shape: BoxShape.circle,
          ),
          child: step == "1" 
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(step, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 10),
              Text(title, style: CheckoutStyle.title),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    final name = widget.previewOrderData['recipient_name'] ?? '';
    final phone = widget.previewOrderData['recipient_phone'] ?? '';
    final address = widget.previewOrderData['shipping_address'] ?? '';
    final notes = widget.previewOrderData['notes'] as String?;

    return Column(
      children: [
        _buildInfoRow(Icons.person, "$name ($phone)"),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.location_on, address),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.note_alt, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text("Ghi chú: $notes", style: const TextStyle(fontSize: 13, color: Colors.orange))),
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: CheckoutStyle.textGrey),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: CheckoutStyle.body.copyWith(height: 1.4))),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    final method = widget.previewOrderData['payment_method'] ?? 'Tiền mặt';
    IconData icon = Icons.money;
    if (method.toString().contains("Online") || method.toString().contains("VNPAY")) {
      icon = Icons.credit_card;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.blue[700]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(method, style: CheckoutStyle.title)),
        const Icon(Icons.check_circle, color: Colors.green),
      ],
    );
  }

  Widget _buildProductList() {
    final items = widget.previewOrderData['items'] as List? ?? [];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (ctx, i) {
        final item = items[i];
        final variant = item['variant'] ?? {};
        final price = double.tryParse(item['price_at_purchase'].toString()) ?? 0;
        final qty = item['quantity'] ?? 1;

        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                variant['image_url'] ?? '',
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(variant['name'] ?? 'Sản phẩm', style: CheckoutStyle.body.copyWith(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("${NumberFormat("#,##0", "vi_VN").format(price)}đ  x$qty", style: CheckoutStyle.label),
                ],
              ),
            ),
            Text(
              NumberFormat("#,##0", "vi_VN").format(price * qty) + "đ",
              style: CheckoutStyle.title.copyWith(fontSize: 14),
            )
          ],
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = double.tryParse(widget.previewOrderData['subtotal'].toString()) ?? 0;
    final shipping = double.tryParse(widget.previewOrderData['shipping_fee'].toString()) ?? 0;
    final couponDisc = double.tryParse(widget.previewOrderData['coupon_discount_amount'].toString()) ?? 0;
    final loyaltyDisc = double.tryParse(widget.previewOrderData['loyalty_discount_amount'].toString()) ?? 0;
    final total = double.tryParse(widget.previewOrderData['total_amount'].toString()) ?? 0;

    return Column(
      children: [
        _buildSummaryRow("Tạm tính", subtotal),
        _buildSummaryRow("Phí vận chuyển", shipping),
        if (couponDisc > 0) _buildSummaryRow("Giảm giá Voucher", couponDisc, isMinus: true),
        if (loyaltyDisc > 0) _buildSummaryRow("Giảm giá điểm", loyaltyDisc, isMinus: true),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Tổng cộng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(NumberFormat("#,##0₫", "vi_VN").format(total), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: CheckoutStyle.primary)),
          ],
        )
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isMinus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CheckoutStyle.label),
          Text(
            "${isMinus ? '-' : ''}${NumberFormat("#,##0", "vi_VN").format(value)}đ",
            style: CheckoutStyle.body.copyWith(fontWeight: FontWeight.w500, color: isMinus ? Colors.green : CheckoutStyle.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          activeColor: CheckoutStyle.primary,
          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
        ),
        const Expanded(
          child: Text("Tôi đồng ý với các điều khoản mua hàng và chính sách bảo mật.", style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}