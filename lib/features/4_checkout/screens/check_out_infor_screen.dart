// Trong file: CheckoutInfoScreen.dart

import 'package:cross_platform_mobile_app_development/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/services/cart_service.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/services/api_service.dart';

import 'check_out_screen.dart';
import 'package:cross_platform_mobile_app_development/layout/header.dart';

// --- Models cho API Địa chỉ (Cấu trúc 2 cấp: Tỉnh -> Xã) ---

class Province {
  final String code; // Dữ liệu trả về là "code": "01"
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
  @override
  String toString() => name;
}

class Ward {
  final String code;
  final String name;
  
  Ward({required this.code, required this.name});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
  @override
  String toString() => name;
}

// --- Kết thúc Models ---

class CheckoutInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? currentUserData;
  final String userId;

  const CheckoutInfoScreen({
    super.key,
    this.currentUserData,
    required this.userId,
  });

  @override
  State<CheckoutInfoScreen> createState() => _CheckoutInfoScreenState();
}

class _CheckoutInfoScreenState extends State<CheckoutInfoScreen> {
  final ApiService _apiService = ApiService();
  
  // Base URL của API mới (Lưu ý: Bạn có thể cần thay đổi ngày trong URL nếu API update version)
  final String _apiBaseUrl = 'https://production.cas.so/address-kit'; 

  final List<Map<String, dynamic>> _categories = [
    {'category_id': 1, 'name': 'Linh kiện'},
    {'category_id': 2, 'name': 'Laptop'},
  ];

  int get _cartItemCount => 0; // Thay bằng logic lấy số lượng thực tế nếu cần

  bool _isLoading = false;
  String? _errorMessage;

  // State cho địa chỉ (Chỉ còn 2 cấp)
  List<Province> _provinces = [];
  Province? _selectedProvince;
  bool _isLoadingProvinces = false;

  List<Ward> _currentWards = [];
  Ward? _selectedWard;
  bool _isLoadingWards = false;

  String _selectedPaymentMethod = 'Tiền mặt';

  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _recipientPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _shippingAddressDetailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _loyaltyPointsController = TextEditingController(text: '0');

  final List<String> _paymentMethods = ['Tiền mặt', 'Thanh toán Online (VNPAY)'];

  // State Coupon & Points
  int _userLoyaltyPoints = 0;
  int _calculatedCouponDiscount = 0;
  int _estimatedCartTotal = 0;
  String? _couponError;
  String? _pointsError;
  bool _isCouponApplied = false;

  @override
  void initState() {
    super.initState();
    _fetchProvinces(); // Load Tỉnh ngay khi vào
    _loadUserInfo();
  }

  // --- API HELPER: Lấy ngày hiện tại để gắn vào URL (theo format YYYY-MM-DD) ---
  // API Cas.so yêu cầu version date, dùng date hiện tại hoặc hardcode ngày release mới nhất
  String get _currentApiDateStr => "2025-07-01"; // Hardcode theo link mẫu bạn đưa

  Future<void> _loadUserInfo() async {
    // 1. Điền thông tin text cơ bản
    _recipientNameController.text = widget.currentUserData?['full_name'] ?? '';
    _recipientPhoneController.text = widget.currentUserData?['phone'] ?? '';
    _emailController.text = widget.currentUserData?['email'] ?? '';

    if (widget.userId.isNotEmpty) {
      try {
        // B1: Đảm bảo đã tải danh sách tỉnh
        if (_provinces.isEmpty) {
          await _fetchProvinces();
        }

        final userProfile = await _apiService.getUserProfile();
        
        if (mounted && userProfile != null && _provinces.isNotEmpty) {
          setState(() {
            _userLoyaltyPoints = userProfile.loyaltyPoints;

            if (userProfile.addresses.isNotEmpty) {
              // Lấy địa chỉ mặc định
              final defaultAddr = userProfile.addresses.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => userProfile.addresses.first
              );

              // Dữ liệu từ DB:
              // addressLine: "71, Ấp Rạch Đập, Xã Nhị Long"
              // city: "Vĩnh Long"
              String dbAddressLine = defaultAddr.addressLine; 
              String dbCity = defaultAddr.city; 

              // --- LOGIC TÌM TỈNH (Sửa lại: Dựa vào field 'city') ---
              Province? matchedProvince;
              
              try {
                // Tìm trong API xem có tỉnh nào tên giống dbCity không
                // API: "Tỉnh Vĩnh Long" vs DB: "Vĩnh Long" -> Contains sẽ khớp
                matchedProvince = _provinces.firstWhere(
                  (p) => p.name.toLowerCase().contains(dbCity.toLowerCase()) || 
                         dbCity.toLowerCase().contains(p.name.toLowerCase())
                );
              } catch (_) {
                 print("Không tìm thấy tỉnh khớp với city: $dbCity. Thử tìm trong addressLine...");
                 // Fallback: Nếu field city rỗng hoặc sai, thử tìm trong addressLine như cũ
                 try {
                   matchedProvince = _provinces.firstWhere(
                    (p) => dbAddressLine.toLowerCase().contains(p.name.toLowerCase())
                   );
                 } catch (_) {}
              }

              if (matchedProvince != null) {
                _selectedProvince = matchedProvince;

                // --- LOGIC TÌM XÃ (Dựa vào field 'addressLine') ---
                // Gọi API lấy xã
                _fetchWardsDirectly(matchedProvince.code).then((_) {
                   if (!mounted) return;
                   
                   try {
                     // Tìm xã trong list API khớp với chuỗi "71, Ấp Rạch Đập, Xã Nhị Long"
                     // API Ward: "Xã Nhị Long"
                     final matchedWard = _currentWards.firstWhere(
                       (w) => dbAddressLine.toLowerCase().contains(w.name.toLowerCase())
                     );
                     
                     setState(() {
                       _selectedWard = matchedWard;
                       
                       // --- LÀM SẠCH CHUỖI ---
                       String cleanAddr = dbAddressLine;
                       
                       // 1. Xóa tên Tỉnh (nếu lỡ có trong addressLine)
                       cleanAddr = cleanAddr.replaceAll(matchedProvince!.name, "")
                                            .replaceAll(dbCity, ""); // Xóa luôn cái text trong DB cho chắc
                       
                       // 2. Xóa tên Xã ("Xã Nhị Long")
                       cleanAddr = cleanAddr.replaceAll(matchedWard.name, "");
                       
                       // 3. Xóa từ khóa thừa & dấu phẩy
                       cleanAddr = cleanAddr.replaceAll("Tỉnh", "")
                                            .replaceAll("Thành phố", "")
                                            .replaceAll("Xã", "")
                                            .replaceAll("Phường", "")
                                            .replaceAll("Thị trấn", "")
                                            .replaceAll(",", "")
                                            .trim();
                       
                       // Xử lý khoảng trắng kép
                       while (cleanAddr.contains("  ")) {
                         cleanAddr = cleanAddr.replaceAll("  ", " ");
                       }

                       // Kết quả mong đợi: "71 Ấp Rạch Đập"
                       _shippingAddressDetailController.text = cleanAddr;
                     });
                     
                   } catch (e) {
                     print("Tìm thấy Tỉnh nhưng không tìm thấy Xã trong chuỗi: $dbAddressLine");
                     // Nếu không tìm thấy xã, chỉ điền nguyên chuỗi addressLine vào ô chi tiết
                     // (Có thể user nhập tay xã không chuẩn với API)
                     setState(() {
                        _shippingAddressDetailController.text = dbAddressLine;
                     });
                   }
                });
              } else {
                // Không tìm thấy tỉnh
                _shippingAddressDetailController.text = dbAddressLine;
                // Có thể nối thêm city vào nếu cần
                // _shippingAddressDetailController.text = "$dbAddressLine, $dbCity";
              }
            }
          });
        }
      } catch (e) {
        print("Lỗi load profile: $e");
      }
    }

    // 3. Load thông tin giỏ hàng
    final CartService cartService = CartService();
    final items = await cartService.getCartItems();
    if (mounted) {
      setState(() {
        _estimatedCartTotal = items.fold(0, (sum, item) => sum + (item.price * item.quantity));
      });
    }
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

  // --- API Địa chỉ mới (2 cấp) ---
  
  // 1. Lấy danh sách Tỉnh
  Future<void> _fetchProvinces() async {
    if (!mounted) return;
    setState(() { _isLoadingProvinces = true; _errorMessage = null; });
    
    // URL: https://production.cas.so/address-kit/2025-07-01/provinces
    final url = Uri.parse('$_apiBaseUrl/$_currentApiDateStr/provinces'); 
    
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        // 'x-api-key': 'YOUR_KEY' // Thêm key nếu API yêu cầu
      }).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          // Xử lý utf8
          final decodedBody = utf8.decode(response.bodyBytes);
          final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);
          
          // Dữ liệu nằm trong key "provinces"
          final List<dynamic> listData = jsonResponse['provinces'] ?? [];

          setState(() {
            _provinces = listData.map((json) => Province.fromJson(json)).toList();
            _isLoadingProvinces = false;
          });
        } else {
          print('Error fetch provinces: ${response.statusCode}');
          setState(() { _isLoadingProvinces = false; });
        }
      }
    } catch (e) {
      print('Exception fetch provinces: $e');
      if (mounted) setState(() { _isLoadingProvinces = false; });
    }
  }

  // 2. Lấy danh sách Xã (trực tiếp từ Tỉnh)
  Future<void> _fetchWardsDirectly(String provinceCode) async {
    if (!mounted) return;
    setState(() { 
      _isLoadingWards = true; 
      _currentWards = []; 
      _selectedWard = null; 
      _errorMessage = null; 
    });

    // URL dự kiến: .../provinces/{code}/communes
    // Lưu ý: Endpoint này trả về danh sách xã/phường/thị trấn thuộc Tỉnh
    final url = Uri.parse('$_apiBaseUrl/$_currentApiDateStr/provinces/$provinceCode/communes');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final Map<String, dynamic> jsonResponse = jsonDecode(decodedBody);
          
          // API Cas.so thường trả về key "communes" hoặc "wards"
          // Ta check an toàn cả 2 trường hợp hoặc log ra xem
          final List<dynamic> listData = jsonResponse['communes'] ?? jsonResponse['wards'] ?? [];

          setState(() {
            _currentWards = listData.map((json) => Ward.fromJson(json)).toList();
            _isLoadingWards = false;
          });
        } else {
          print('Error fetch wards: ${response.statusCode}');
          setState(() { _isLoadingWards = false; });
        }
      }
    } catch (e) {
      print('Exception fetch wards: $e');
      if (mounted) setState(() { _isLoadingWards = false; });
    }
  }

  // --- Kiểm tra Coupon ---
  Future<void> _checkCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _couponError = "Vui lòng nhập mã");
      return;
    }

    setState(() {
      _isLoading = true;
      _couponError = null;
      _calculatedCouponDiscount = 0;
      _isCouponApplied = false;
    });

    try {
      final result = await _apiService.validateDiscount(code, _estimatedCartTotal);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['valid'] == true) {
            _calculatedCouponDiscount = (result['discountAmount'] as num).toInt();
            _isCouponApplied = true;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Áp dụng mã thành công! Giảm ${_calculatedCouponDiscount}đ"),
                  backgroundColor: Colors.green,
                )
            );
          } else {
            _couponError = result['message'];
            _isCouponApplied = false;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _couponError = "Lỗi kiểm tra mã: $e"; });
    }
  }

  // --- Xử lý Submit ---
  Future<void> _proceedToPaymentScreen() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    // Validate
    if (_recipientNameController.text.trim().isEmpty ||
        _recipientPhoneController.text.trim().isEmpty ||
        _shippingAddressDetailController.text.trim().isEmpty ||
        _selectedProvince == null ||
        _selectedWard == null) { 
      setState(() { 
        _errorMessage = "Vui lòng điền đầy đủ thông tin (bao gồm Tỉnh và Xã/Phường)."; 
        _isLoading = false; 
      });
      return;
    }

    int pointsToUse = int.tryParse(_loyaltyPointsController.text.trim()) ?? 0;
    if (pointsToUse > _userLoyaltyPoints) {
      setState(() {
        _errorMessage = "Số điểm nhập vượt quá số điểm hiện có.";
        _pointsError = "Tối đa $_userLoyaltyPoints điểm";
        _isLoading = false;
      });
      return;
    }

    // Tạo chuỗi địa chỉ đầy đủ để lưu database
    String fullAddress = _shippingAddressDetailController.text.trim();
    fullAddress += ", ${_selectedWard!.name}";
    fullAddress += ", ${_selectedProvince!.name}";

    try {
      final CartService cartService = CartService();
      List<CartItem> cartItems = await cartService.getCartItems();
      if (cartItems.isEmpty) {
        setState(() { _errorMessage = "Giỏ hàng trống."; _isLoading = false; });
        return;
      }

      int itemsPrice = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
      int shippingFee = itemsPrice > 500000 ? 0 : 30000;
      int loyaltyDiscount = pointsToUse * 1000;

      int remainingTotal = itemsPrice + shippingFee - _calculatedCouponDiscount;
      if (loyaltyDiscount > remainingTotal) {
        loyaltyDiscount = remainingTotal;
      }

      int totalAmount = itemsPrice + shippingFee - _calculatedCouponDiscount - loyaltyDiscount;
      if (totalAmount < 0) totalAmount = 0;

      final Map<String, dynamic> previewData = {
        'items': cartItems.map((e) => {
          'product_id': e.productId,
          'variant_id': e.variantId,
          'quantity': e.quantity,
          'price_at_purchase': e.price,
          'variant': { 'name': e.name, 'image_url': e.image }
        }).toList(),
        'subtotal': itemsPrice,
        'shipping_fee': shippingFee,
        'coupon_discount_amount': _calculatedCouponDiscount,
        'loyalty_discount_amount': loyaltyDiscount,
        'total_amount': totalAmount,
        'recipient_name': _recipientNameController.text,
        'recipient_phone': _recipientPhoneController.text,
        'shipping_address': fullAddress, // Gửi chuỗi đầy đủ
        'notes': _noteController.text,
        'payment_method': _selectedPaymentMethod,
        'applied_coupon': _isCouponApplied ? {'code': _couponController.text.trim()} : null,
        'loyalty_points_used': pointsToUse,
        'guest_email_from_api_if_any': _emailController.text
      };

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPaymentScreen(
              previewOrderData: previewData,
              guestEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
              userId: widget.userId,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Lỗi xử lý: $e"; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- UI Helpers ---
  void _navigateToCatalog(int categoryId, String categoryName) {
    print('Navigating to: $categoryName');
  }

  void _onCartPressed() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _onAccountPressed() {}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.themePageBackground,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
                kIsWeb ? (screenWidth > 900 ? 60 : 50) : 45 + MediaQuery.of(context).padding.top),
            child: CustomHeader(
              categories: _categories,
              currentUserData: widget.currentUserData,
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
              onLogoTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              onSearchSubmitted: (value) => print('Search: $value'),
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                width: isDesktop ? 800 : double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 0 : 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("THÔNG TIN KHÁCH HÀNG"),
                    _buildCustomerInfoCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("ĐỊA CHỈ GIAO HÀNG"),
                    _buildDeliveryDetailsCard(),
                    const SizedBox(height: 16),
                    _buildSectionTitle("THANH TOÁN & ƯU ĐÃI"),
                    _buildPaymentAndPromoCard(),
                    const SizedBox(height: 16),
                    _buildProceedButton(),
                    if (_errorMessage != null && !(_isLoadingProvinces || _isLoadingWards || _isLoading))
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.montserrat(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoadingProvinces || _isLoadingWards || _isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
          ),
      ],
    );
  }

  // ... (Giữ nguyên các hàm build UI con như _buildStepIndicator, _buildSectionTitle, _buildCustomerInfoCard, _buildPaymentAndPromoCard, _buildDropdownField, _inputDecoration, _buildProceedButton từ code trước. Chúng không thay đổi logic)
  
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem("1. THÔNG TIN", isActive: true),
          Container(
            width: 60, height: 1, color: AppColors.borderGrey,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildStepItem("2. THANH TOÁN", isActive: false),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, {required bool isActive}) {
    return Column(
      children: [
        Text(title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primaryRed : AppColors.textGrey,
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(width: 60, height: 2, color: AppColors.primaryRed),
        ]
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(title,
        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("THÔNG TIN LIÊN HỆ", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textBlack)),
            const SizedBox(height: 12),
            Text("Họ và tên người nhận *", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            TextFormField(
              controller: _recipientNameController,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
              decoration: _inputDecoration("Nhập họ và tên"),
            ),
            const SizedBox(height: 12),
            Text("Số điện thoại người nhận *", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            TextFormField(
              controller: _recipientPhoneController,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration("Nhập số điện thoại"),
            ),
            const SizedBox(height: 12),
            Text("Email (dùng cho hóa đơn VAT)", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            TextFormField(
              controller: _emailController,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration("Nhập email"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cấp 1: Tỉnh
            _buildDropdownField<Province>(
              label: "Tỉnh / Thành Phố *",
              value: _selectedProvince,
              items: _provinces,
              onChanged: (Province? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedProvince = newValue;
                    _selectedWard = null; 
                    _currentWards = [];
                    if(mounted) _fetchWardsDirectly(newValue.code);
                  });
                }
              },
              hint: _isLoadingProvinces ? "Đang tải tỉnh/thành..." : "Chọn tỉnh / thành phố",
              disabled: _isLoadingProvinces,
            ),
            const SizedBox(height: 16),

            // Cấp 2: Xã / Phường (Trực thuộc Tỉnh)
            _buildDropdownField<Ward>(
              label: "Xã / Phường / Thị trấn *",
              value: _selectedWard,
              items: _currentWards,
              onChanged: (Ward? newValue) {
                if (newValue != null) {
                  setState(() { _selectedWard = newValue; });
                }
              },
              hint: _isLoadingWards 
                  ? "Đang tải xã/phường..." 
                  : (_selectedProvince == null ? "Vui lòng chọn Tỉnh/Thành trước" : "Chọn xã / phường / thị trấn"),
              disabled: _isLoadingWards || _selectedProvince == null || _provinces.isEmpty,
            ),
            const SizedBox(height: 16),

            Text("Số nhà, tên đường, chi tiết khác *",
                style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            TextFormField(
              controller: _shippingAddressDetailController,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
              decoration: _inputDecoration("Nhập số nhà, tên đường, tòa nhà..."),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text("Ghi chú (nếu có)", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            TextFormField(
              controller: _noteController,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
              decoration: _inputDecoration("Nhập ghi chú cho đơn hàng"),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAndPromoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phương thức thanh toán", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items: _paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method, style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (mounted) setState(() => _selectedPaymentMethod = newValue ?? _paymentMethods.first);
              },
              decoration: _inputDecoration("Chọn phương thức thanh toán"),
              isExpanded: true,
            ),
            const SizedBox(height: 16),

            Text("Mã giảm giá", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
                    decoration: _inputDecoration("Nhập mã giảm giá").copyWith(errorText: _couponError),
                    onChanged: (_) {
                      if (_couponError != null) setState(() => _couponError = null);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("Áp dụng", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            Text("Sử dụng điểm tích lũy (Hiện có: $_userLoyaltyPoints điểm)", style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _loyaltyPointsController,
              style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Nhập số điểm (1 điểm = 1000đ)").copyWith(
                helperText: "Tối đa $_userLoyaltyPoints điểm",
                helperStyle: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textGrey),
                errorText: _pointsError,
              ),
              onChanged: (value) {
                final input = int.tryParse(value) ?? 0;
                if (input > _userLoyaltyPoints) {
                  setState(() => _pointsError = "Bạn chỉ có $_userLoyaltyPoints điểm");
                } else if (_pointsError != null) {
                  setState(() => _pointsError = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textLightGrey.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderGrey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primaryRed)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String hint,
    bool disabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textLightGrey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(),
                style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textBlack),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: disabled ? null : onChanged,
          decoration: _inputDecoration(hint).copyWith(
            filled: disabled,
            fillColor: disabled ? Theme.of(context).disabledColor.withOpacity(0.05) : null,
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: disabled ? AppColors.textLightGrey.withOpacity(0.5) : AppColors.textGrey),
        ),
      ],
    );
  }

  Widget _buildProceedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _proceedToPaymentScreen,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: AppColors.primaryRed.withOpacity(0.5),
          ),
          child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Tiếp tục"),
        ),
      ),
    );
  }
}