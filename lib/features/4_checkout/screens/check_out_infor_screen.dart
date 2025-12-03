import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../layout/header.dart'; // Import CustomHeader
import '../../1_home/screens/home_screen.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../5_profile/screens/profile_screen.dart';
import 'check_out_screen.dart'; // Màn hình Payment kế tiếp

// --- Local Style Constants ---
class CheckoutStyle {
  static const Color bg = Color(0xFFF5F5FA);
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

// --- Models Địa chỉ ---
class Province {
  final String code;
  final String name;
  Province({required this.code, required this.name});
  factory Province.fromJson(Map<String, dynamic> json) => 
      Province(code: (json['code'] ?? '').toString(), name: (json['name'] ?? '').toString());
  @override
  String toString() => name;
}

class Ward {
  final String code;
  final String name;
  Ward({required this.code, required this.name});
  factory Ward.fromJson(Map<String, dynamic> json) => 
      Ward(code: (json['code'] ?? '').toString(), name: (json['name'] ?? '').toString());
  @override
  String toString() => name;
}

// --- Main Screen ---
class CheckoutInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUserData;
  final String userId;

  const CheckoutInfoScreen({super.key, this.currentUserData, required this.userId});

  @override
  State<CheckoutInfoScreen> createState() => _CheckoutInfoScreenState();
}

class _CheckoutInfoScreenState extends State<CheckoutInfoScreen> {
  // Services
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  
  // Constants Địa chỉ
  final String _apiBaseUrl = 'https://production.cas.so/address-kit';
  final String _currentApiDateStr = "2025-07-01";

  // Header Data State
  List<Map<String, dynamic>> _headerCategories = [];
  int _cartItemCount = 0;

  // Controllers
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _shippingAddressDetailController = TextEditingController();
  final _noteController = TextEditingController();
  final _couponController = TextEditingController();
  final _loyaltyPointsController = TextEditingController(text: '0');

  // State Variables
  bool _isLoading = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingWards = false;
  String? _errorMessage;
  
  List<Province> _provinces = [];
  Province? _selectedProvince;
  List<Ward> _currentWards = [];
  Ward? _selectedWard;

  String _selectedPaymentMethod = 'Tiền mặt';
  final List<String> _paymentMethods = ['Tiền mặt', 'Thanh toán Online (VNPAY)'];

  // Calculation State
  int _userLoyaltyPoints = 0;
  int _calculatedCouponDiscount = 0;
  int _estimatedCartTotal = 0;
  String? _couponError;
  String? _pointsError;
  bool _isCouponApplied = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
    _fetchHeaderData(); // Tải danh mục cho Header
    _loadUserInfoAndCart(); // Tải user info và cart
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _emailController.dispose();
    _shippingAddressDetailController.dispose();
    _noteController.dispose();
    _couponController.dispose();
    _loyaltyPointsController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _fetchHeaderData() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _headerCategories = categories;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh mục header: $e");
    }
  }

  Future<void> _loadUserInfoAndCart() async {
    // 1. Điền thông tin User vào Form
    _recipientNameController.text = widget.currentUserData?['full_name'] ?? '';
    _recipientPhoneController.text = widget.currentUserData?['phone'] ?? '';
    _emailController.text = widget.currentUserData?['email'] ?? '';

    // 2. Load giỏ hàng để tính tạm tính & cập nhật badge trên Header
    final items = await _cartService.getCartItems();
    int total = items.fold(0, (sum, item) => sum + (item.price * item.quantity));

    if (mounted) {
      setState(() {
        _estimatedCartTotal = total;
        _cartItemCount = items.length; // Cập nhật badge header
      });
    }

    // 3. Load điểm tích lũy và địa chỉ mặc định (nếu có user ID)
    if (widget.userId.isNotEmpty) {
      try {
        if (_provinces.isEmpty) await _fetchProvinces();
        final userProfile = await _apiService.getUserProfile();
        
        if (mounted && userProfile != null) {
          setState(() => _userLoyaltyPoints = userProfile.loyaltyPoints);
          
          if (_provinces.isNotEmpty && userProfile.addresses.isNotEmpty) {
            final defaultAddr = userProfile.addresses.firstWhere((a) => a.isDefault, orElse: () => userProfile.addresses.first);
            _autoFillAddress(defaultAddr.city, defaultAddr.addressLine);
          }
        }
      } catch (e) {
        debugPrint("Lỗi load profile: $e");
      }
    }
  }

  Future<void> _autoFillAddress(String dbCity, String dbAddressLine) async {
    Province? matchedProvince;
    try {
      matchedProvince = _provinces.firstWhere((p) => 
        p.name.toLowerCase().contains(dbCity.toLowerCase()) || dbCity.toLowerCase().contains(p.name.toLowerCase())
      );
    } catch (_) {}

    if (matchedProvince != null) {
      setState(() => _selectedProvince = matchedProvince);
      await _fetchWardsDirectly(matchedProvince.code);
      if (!mounted) return;
      
      try {
        final matchedWard = _currentWards.firstWhere((w) => dbAddressLine.toLowerCase().contains(w.name.toLowerCase()));
        setState(() {
          _selectedWard = matchedWard;
          // Clean address detail logic
          String clean = dbAddressLine
              .replaceAll(matchedProvince!.name, "")
              .replaceAll(dbCity, "")
              .replaceAll(matchedWard.name, "")
              .replaceAll(RegExp(r'(Tỉnh|Thành phố|Xã|Phường|Thị trấn)'), "")
              .replaceAll(",", "")
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ');
          _shippingAddressDetailController.text = clean;
        });
      } catch (_) {
        setState(() => _shippingAddressDetailController.text = dbAddressLine);
      }
    } else {
      setState(() => _shippingAddressDetailController.text = dbAddressLine);
    }
  }

  Future<void> _fetchProvinces() async {
    if (!mounted) return;
    setState(() => _isLoadingProvinces = true);
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/$_currentApiDateStr/provinces'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && mounted) {
        final listData = jsonDecode(utf8.decode(response.bodyBytes))['provinces'] ?? [];
        setState(() => _provinces = listData.map<Province>((json) => Province.fromJson(json)).toList());
      }
    } catch (_) {} 
    finally { if (mounted) setState(() => _isLoadingProvinces = false); }
  }

  Future<void> _fetchWardsDirectly(String provinceCode) async {
    if (!mounted) return;
    setState(() { _isLoadingWards = true; _currentWards = []; _selectedWard = null; });
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/$_currentApiDateStr/provinces/$provinceCode/communes'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && mounted) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final listData = json['communes'] ?? json['wards'] ?? [];
        setState(() => _currentWards = listData.map<Ward>((json) => Ward.fromJson(json)).toList());
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoadingWards = false); }
  }

  Future<void> _checkCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) { setState(() => _couponError = "Vui lòng nhập mã"); return; }
    setState(() { _isLoading = true; _couponError = null; _calculatedCouponDiscount = 0; _isCouponApplied = false; });

    try {
      final result = await _apiService.validateDiscount(code, _estimatedCartTotal);
      if (mounted) {
        setState(() {
          if (result['valid'] == true) {
            _calculatedCouponDiscount = (result['discountAmount'] as num).toInt();
            _isCouponApplied = true;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Áp dụng mã thành công: -${NumberFormat('#,##0').format(_calculatedCouponDiscount)}đ"), backgroundColor: Colors.green));
          } else {
            _couponError = result['message'];
          }
        });
      }
    } catch (e) { if (mounted) setState(() => _couponError = "Lỗi: $e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _proceedToPaymentScreen() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    // Validate
    if (_recipientNameController.text.isEmpty || _recipientPhoneController.text.isEmpty || _shippingAddressDetailController.text.isEmpty || _selectedProvince == null || _selectedWard == null) { 
      setState(() { _errorMessage = "Vui lòng điền đầy đủ thông tin giao hàng (*)"; _isLoading = false; }); return;
    }

    int pointsToUse = int.tryParse(_loyaltyPointsController.text) ?? 0;
    if (pointsToUse > _userLoyaltyPoints) {
      setState(() { _pointsError = "Bạn chỉ có $_userLoyaltyPoints điểm"; _isLoading = false; }); return;
    }

    String fullAddress = "${_shippingAddressDetailController.text}, ${_selectedWard!.name}, ${_selectedProvince!.name}";
    
    try {
      final items = await _cartService.getCartItems();
      if (items.isEmpty) { setState(() { _errorMessage = "Giỏ hàng trống."; _isLoading = false; }); return; }

      int itemsPrice = items.fold(0, (sum, i) => sum + (i.price * i.quantity));
      int shippingFee = itemsPrice > 500000 ? 0 : 30000;
      int loyaltyDiscount = pointsToUse * 1000;
      int remainingTotal = itemsPrice + shippingFee - _calculatedCouponDiscount;
      if (loyaltyDiscount > remainingTotal) loyaltyDiscount = remainingTotal;
      int totalAmount = itemsPrice + shippingFee - _calculatedCouponDiscount - loyaltyDiscount;
      if (totalAmount < 0) totalAmount = 0;

      final previewData = {
        'items': items.map((e) => {
          'product_id': e.productId, 'variant_id': e.variantId, 'quantity': e.quantity, 'price_at_purchase': e.price,
          'variant': { 'name': e.name, 'image_url': e.image }
        }).toList(),
        'subtotal': itemsPrice, 
        'shipping_fee': shippingFee,
        'coupon_discount_amount': _calculatedCouponDiscount, 
        'loyalty_discount_amount': loyaltyDiscount,
        'total_amount': totalAmount,
        'recipient_name': _recipientNameController.text, 
        'recipient_phone': _recipientPhoneController.text,
        'shipping_address': fullAddress, 
        'notes': _noteController.text, 
        'payment_method': _selectedPaymentMethod,
        'applied_coupon': _isCouponApplied ? {'code': _couponController.text} : null,
        'loyalty_points_used': pointsToUse, 
        'guest_email_from_api_if_any': _emailController.text
      };

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPaymentScreen(
          previewOrderData: previewData, 
          guestEmail: _emailController.text.isNotEmpty ? _emailController.text : null, 
          userId: widget.userId
        )));
      }
    } catch (e) { setState(() => _errorMessage = "Lỗi xử lý: $e"); } 
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // --- UI CONSTRUCTION ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: CheckoutStyle.bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _headerCategories,
          currentUserData: widget.currentUserData,
          cartItemCount: _cartItemCount, 
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: isDesktop ? (screenWidth - 800) / 2 : 16,
              right: isDesktop ? (screenWidth - 800) / 2 : 16,
              top: 20,
              bottom: 120, // Space for Bottom Bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text("Thông tin giao hàng", style: CheckoutStyle.header.copyWith(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. User Information
                _buildSectionCard(
                  title: "THÔNG TIN NGƯỜI NHẬN",
                  icon: Icons.person_outline,
                  child: Column(
                    children: [
                      _buildTextField("Họ và tên *", _recipientNameController, Icons.account_circle_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField("Số điện thoại *", _recipientPhoneController, Icons.phone_android_outlined, type: TextInputType.phone)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField("Email (nhận hóa đơn)", _emailController, Icons.email_outlined, type: TextInputType.emailAddress)),
                        ],
                      ),
                    ],
                  )
                ),
                const SizedBox(height: 16),

                // 2. Address
                _buildSectionCard(
                  title: "ĐỊA CHỈ GIAO HÀNG",
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<Province>(
                              "Tỉnh / Thành phố", 
                              _selectedProvince, 
                              _provinces, 
                              (v) {
                                if (v == null) return;
                                setState(() { _selectedProvince = v; _selectedWard = null; _currentWards = []; });
                                _fetchWardsDirectly(v.code);
                              }, 
                              isLoading: _isLoadingProvinces
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown<Ward>(
                              "Xã / Phường", 
                              _selectedWard, 
                              _currentWards, 
                              (v) => setState(() => _selectedWard = v), 
                              isLoading: _isLoadingWards
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField("Địa chỉ chi tiết (Số nhà, tên đường...) *", _shippingAddressDetailController, Icons.home_outlined),
                      const SizedBox(height: 12),
                      _buildTextField("Ghi chú cho shipper (Tùy chọn)", _noteController, Icons.note_alt_outlined),
                    ],
                  )
                ),
                const SizedBox(height: 16),

                // 3. Payment & Offers
                _buildSectionCard(
                  title: "THANH TOÁN & ƯU ĐÃI",
                  icon: Icons.confirmation_number_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: CheckoutStyle.body))).toList(),
                        onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                        decoration: _inputDeco("Phương thức thanh toán", Icons.payment),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                      const SizedBox(height: 20),
                      
                      const Text("Mã giảm giá", style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildTextField("Nhập mã voucher", _couponController, null, error: _couponError)),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _checkCoupon,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CheckoutStyle.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0
                              ),
                              child: const Text("Áp dụng", style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Loyalty Points Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.stars, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text("Điểm tích lũy: ${NumberFormat('#,##0').format(_userLoyaltyPoints)}", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 8),
                            _buildTextField("Sử dụng điểm (1đ = 1.000đ)", _loyaltyPointsController, Icons.redeem, type: TextInputType.number, error: _pointsError),
                          ],
                        ),
                      )
                    ],
                  )
                ),

                if (_errorMessage != null) 
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                    ]),
                  )
              ],
            ),
          ),

          // Sticky Bottom Bar
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
                          const Text("Tạm tính", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            NumberFormat("#,##0₫", "vi_VN").format(_estimatedCartTotal),
                            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: CheckoutStyle.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _proceedToPaymentScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CheckoutStyle.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("TIẾP TỤC", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        _buildStepIcon("1", "Thông tin", true),
        Container(width: 40, height: 2, color: Colors.grey[300]),
        _buildStepIcon("2", "Thanh toán", false),
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
            color: isActive ? CheckoutStyle.primary : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Text(step, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? CheckoutStyle.primary : CheckoutStyle.textGrey)),
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
          const Divider(height: 24, color: CheckoutStyle.border),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData? icon, {TextInputType type = TextInputType.text, String? error}) {
    return TextFormField(
      controller: controller, keyboardType: type,
      style: CheckoutStyle.body,
      decoration: _inputDeco(label, icon).copyWith(errorText: error),
    );
  }

  Widget _buildDropdown<T>(String label, T? value, List<T> items, ValueChanged<T?> onChanged, {bool isLoading = false}) {
    return DropdownButtonFormField<T>(
      value: value, 
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString(), style: CheckoutStyle.body, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: isLoading ? null : onChanged,
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      isExpanded: true,
      decoration: _inputDeco(isLoading ? "Đang tải dữ liệu..." : label, null),
    );
  }

  InputDecoration _inputDeco(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: CheckoutStyle.textGrey),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey[400]) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      fillColor: Colors.grey[50], filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CheckoutStyle.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CheckoutStyle.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CheckoutStyle.primary)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}