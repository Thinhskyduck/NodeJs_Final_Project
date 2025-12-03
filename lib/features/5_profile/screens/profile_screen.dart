import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../layout/header.dart'; 
import '../../0_authentication/screens/login.dart';
import '../../3_cart/screens/cart_screen.dart';
import 'address_list_screen.dart';
import 'change_profile.dart'; // Import ChangeProfile
import 'order_history_screen.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  
  UserModel? _user;
  bool _isLoading = true;

  // --- HEADER DATA ---
  List<Map<String, dynamic>> _headerCategories = [];
  int _cartItemCount = 0;

  // --- STYLE CONSTANTS ---
  static const Color _primaryBlue = Color(0xFF007BFF); // Hoặc màu chủ đạo của App
  static const Color _bgGray = Color(0xFFF4F6F8);
  static const Color _textBlack = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProfile(),
      _fetchHeaderData(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchHeaderData() async {
    try {
      final categories = await _apiService.getCategories();
      final cartItems = await _cartService.getCartItems();
      if (mounted) {
        setState(() {
          _headerCategories = categories;
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      debugPrint("Lỗi header: $e");
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await _apiService.getUserProfile();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      debugPrint("Lỗi profile: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _headerCategories,
          currentUserData: _user != null ? {'full_name': _user!.fullName, 'email': _user!.email} : null,
          cartItemCount: _cartItemCount,
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () {}, // Đang ở trang này
          onLogoTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildGuestView()
              : _buildUserView(),
    );
  }

  // ==================== GUEST VIEW ====================
  Widget _buildGuestView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 60, color: _primaryBlue),
            ),
            const SizedBox(height: 24),
            Text(
              "Xin chào, khách!",
              style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: _textBlack),
            ),
            const SizedBox(height: 8),
            const Text(
              "Đăng nhập để xem lịch sử đơn hàng, tích điểm và nhận ưu đãi dành riêng cho bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Login())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text("Đăng nhập / Đăng ký", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ==================== USER VIEW ====================
  Widget _buildUserView() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), // Giới hạn width cho Web đẹp hơn
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Info Card
              _buildProfileCard(),
              
              const SizedBox(height: 24),
              
              // 2. Menu Sections
              _buildMenuSectionTitle("Đơn hàng của tôi"),
              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.history,
                  iconColor: Colors.orange,
                  title: "Lịch sử mua hàng",
                  subtitle: "Theo dõi đơn hàng đang giao",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              _buildMenuSectionTitle("Tài khoản"),
              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.blue,
                  title: "Sổ địa chỉ",
                  subtitle: "Quản lý địa chỉ nhận hàng",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())),
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  iconColor: Colors.grey,
                  title: "Cài đặt tài khoản",
                  subtitle: "Thông báo, bảo mật...",
                  onTap: () {}, // TODO: Link tới trang settings
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 30),

              // 3. Logout Button
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Đăng xuất"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: Profile Card Header ---
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
            ),
            alignment: Alignment.center,
            child: Text(
              _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'U',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
          ),
          const SizedBox(width: 20),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.fullName,
                  style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: _textBlack),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(_user!.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.orange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "${_user!.loyaltyPoints} điểm tích lũy",
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChangeProfile(uid: _user!.id)),
              );
              if (result == true) {
                _initData(); // Reload lại data khi quay về
              }
            },
            icon: const Icon(Icons.edit_outlined, color: _primaryBlue),
            tooltip: "Chỉnh sửa hồ sơ",
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: onTap,
        ),
        if (showDivider)
           Divider(height: 1, indent: 60, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }
}