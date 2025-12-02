import 'package:cross_platform_mobile_app_development/features/5_profile/screens/address_list_screen.dart';
import 'package:cross_platform_mobile_app_development/features/5_profile/screens/change_profile.dart' hide AddressListScreen;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../0_authentication/screens/login.dart';
import 'order_history_screen.dart'; // Import file vừa tạo


class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = await _apiService.getUserProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Xóa token
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (!mounted) return;
    // Chuyển về trang Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tài khoản"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildGuestView()
              : _buildUserView(),
    );
  }

  // Giao diện khi chưa đăng nhập
  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Bạn chưa đăng nhập", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
            },
            child: const Text("Đăng nhập ngay"),
          )
        ],
      ),
    );
  }

  // Giao diện khi đã đăng nhập
  Widget _buildUserView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_user!.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(_user!.email, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                        child: Text("Điểm tích lũy: ${_user!.loyaltyPoints}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    ],
                  ),
                ),
                // <--- 2. THÊM NÚT SỬA PROFILE TẠI ĐÂY
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    // Chuyển sang trang ChangeProfile
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => ChangeProfile(uid: _user!.id) // Truyền ID user sang
                      )
                    );
                    
                    // Nếu bên kia trả về true (đã update thành công), thì load lại profile ngay
                    if (result == true) {
                      _fetchProfile();
                    }
                  },
                )
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Menu Options
          _buildMenuItem(
            icon: Icons.history, 
            title: "Lịch sử đơn hàng", 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
            }
          ),
          _buildMenuItem(icon: Icons.location_on, title: "Sổ địa chỉ", onTap: () {
            // Dẫn tới màn hình quản lý địa chỉ
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()));
          }),
          _buildMenuItem(icon: Icons.settings, title: "Cài đặt", onTap: () {}),
          
          const Divider(height: 30),
          
          _buildMenuItem(
            icon: Icons.logout, 
            title: "Đăng xuất", 
            color: Colors.red,
            onTap: _logout
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon, 
    required String title, 
    required VoidCallback onTap,
    Color color = Colors.black87
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}