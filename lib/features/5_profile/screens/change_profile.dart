import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../layout/header.dart'; // Import CustomHeader
import '../../1_home/screens/home_screen.dart';
import '../../3_cart/screens/cart_screen.dart';
import '../../2_product/screens/catalog_screen.dart';
import 'address_list_screen.dart'; 
import 'profile_screen.dart';

class ChangeProfile extends StatefulWidget {
  final String uid; 

  const ChangeProfile({super.key, required this.uid});

  @override
  State<ChangeProfile> createState() => _ChangeProfileState();
}

class _ChangeProfileState extends State<ChangeProfile> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();

  // --- HEADER STATE ---
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _currentUserData;
  int _cartItemCount = 0;

  bool _isLoading = true;
  String? _errorMessage;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // --- STYLE CONSTANTS ---
  static const Color _bgGray = Color(0xFFF4F6F8);
  static const double _maxWidth = 800; // Giới hạn chiều rộng form cho đẹp trên web

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _initAllData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initAllData() async {
    setState(() => _isLoading = true);
    // Chạy song song cả 2 tác vụ để tiết kiệm thời gian
    await Future.wait([
      _fetchHeaderData(),
      _loadUserDataForForm(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchHeaderData() async {
    try {
      final categories = await _apiService.getCategories();
      final user = await _apiService.getUserProfile();
      final cartItems = await _cartService.getCartItems();

      Map<String, dynamic>? userData;
      if (user != null) {
        userData = {
          'full_name': user.fullName,
          'email': user.email,
          'user_id': user.id,
        };
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _currentUserData = userData;
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      debugPrint("Header load error: $e");
    }
  }

  Future<void> _loadUserDataForForm() async {
    try {
      _errorMessage = null;
      final userModel = await _apiService.getUserProfile();

      if (mounted) {
        if (userModel != null) {
          _fullNameController.text = userModel.fullName;
          _emailController.text = userModel.email;
          // Nếu API có trả về phone thì gán vào, hiện tại giả định userModel chưa có field phone
          // _phoneController.text = userModel.phone ?? ''; 
        } else {
          _errorMessage = "Không tải được thông tin người dùng.";
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Lỗi: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _apiService.updateUserProfile(
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Cập nhật lại header data sau khi lưu thành công
        await _fetchHeaderData();
        setState(() => _isLoading = false);
        // Navigator.of(context).pop(true); // Có thể pop hoặc giữ lại trang
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue[700]!;

    return Scaffold(
      backgroundColor: _bgGray,
      // --- HEADER ---
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _categories,
          currentUserData: _currentUserData,
          cartItemCount: _cartItemCount,
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
          onSearchSubmitted: (query) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(initialSearch: query)));
          },
        ),
      ),
      // --- BODY ---
      body: _isLoading && _fullNameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumbs
                      _buildBreadcrumbs(),
                      const SizedBox(height: 20),

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Chỉnh sửa Hồ sơ",
                                style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const Divider(height: 30),

                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red[200]!)
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.red[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // --- Họ và tên ---
                              const Text("Họ và tên", style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fullNameController,
                                decoration: _inputDecoration("Nhập họ và tên của bạn", Icons.person_outline),
                                validator: (value) => (value == null || value.trim().isEmpty) 
                                    ? 'Vui lòng nhập họ và tên' : null,
                              ),
                              const SizedBox(height: 20),

                              // --- Số điện thoại ---
                              const Text("Số điện thoại", style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                decoration: _inputDecoration("Nhập số điện thoại", Icons.phone_outlined),
                                keyboardType: TextInputType.phone,
                                validator: (value) => (value == null || value.trim().isEmpty) 
                                    ? 'Vui lòng nhập số điện thoại' : null,
                              ),
                              const SizedBox(height: 20),

                              // --- QUẢN LÝ ĐỊA CHỈ (Nút bấm) ---
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor: Colors.blue.shade50,
                                leading: const Icon(Icons.location_on, color: Colors.blue),
                                title: const Text(
                                  "Quản lý sổ địa chỉ giao hàng",
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                                ),
                                subtitle: const Text("Thêm, sửa, xóa địa chỉ nhận hàng của bạn"),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                                onTap: () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => const AddressListScreen())
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // --- Email (Read Only) ---
                              const Text("Email (Không thể thay đổi)", style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration("Email", Icons.email_outlined).copyWith(
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                readOnly: true,
                                enabled: false,
                              ),
                              const SizedBox(height: 35),

                              // --- Nút Lưu ---
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24, width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
          child: const Icon(Icons.home, size: 18, color: Colors.grey),
        ),
        const SizedBox(width: 5),
        const Text(" / ", style: TextStyle(color: Colors.grey)),
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          child: const Text("Tài khoản", style: TextStyle(color: Colors.grey)),
        ),
        const Text(" / ", style: TextStyle(color: Colors.grey)),
        const Text("Chỉnh sửa hồ sơ", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}