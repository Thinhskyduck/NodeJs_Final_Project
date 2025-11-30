import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cross_platform_mobile_app_development/features/5_profile/screens/change_password.dart';
import 'package:cross_platform_mobile_app_development/features/5_profile/screens/change_profile.dart';
import 'package:cross_platform_mobile_app_development/features/1_home/screens/home_screen.dart';
import 'package:cross_platform_mobile_app_development/features/0_authentication/screens/login.dart';
import '../../../data/services/api_service.dart'; // Import ApiService

class NavDrawer extends StatelessWidget {
  final Map<String, dynamic>? userData;
  // BỎ DÒNG NÀY: final FirebaseAuth _auth = FirebaseAuth.instance;

  const NavDrawer({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue[700]!;

    // ... (Giữ nguyên logic build UI Header như cũ)
    // Phần check userData == null giữ nguyên

    if (userData == null) {
       // ... (Code cũ phần Guest)
       return Drawer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGuestHeader(context, primaryColor),
              _buildGuestMenuItems(context),
            ],
          ),
        ),
      );
    } else {
      // ... (Code cũ lấy fullName, email...)
       final fullName = userData?['full_name'] as String? ?? 'Người dùng';
      final email = userData?['email'] as String? ?? 'Không có email';
      final imageLink = userData?['profile_image_url_or_similar_key'] as String?;
      final backendUserId = userData?['user_id']?.toString();

      if (backendUserId == null || backendUserId.isEmpty) {
        return Drawer(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGuestHeader(context, primaryColor),
                _buildGuestMenuItems(context),
              ],
            ),
          ),
        );
      }

      return Drawer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildHeader(
                context,
                fullName,
                email,
                imageLink,
                primaryColor,
                backendUserId,
              ),
              buildMenuItems(context, backendUserId),
            ],
          ),
        ),
      );
    }
  }

  // ... (Giữ nguyên các hàm _buildGuestHeader, _buildGuestMenuItems, buildHeader)
  Widget _buildGuestHeader(BuildContext context, Color backgroundColor) {
    return Material(
      color: backgroundColor,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 24,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: Icon(
                Icons.person_outline,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chào mừng bạn!',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để có trải nghiệm tốt nhất',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestMenuItems(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Wrap(
        runSpacing: 8,
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.black54),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                    settings: const RouteSettings(name: '/'),
                  ),
                );
              }
            },
            dense: true,
          ),
          const Divider(thickness: 0.8),
          ListTile(
            leading: const Icon(Icons.login, color: Colors.blue),
            title: const Text('Đăng nhập / Đăng ký'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Login()),
                    (route) => false,
              );
            },
            dense: true,
          ),
        ],
      ),
    );
  }

   Widget buildHeader(
      BuildContext context,
      String fullName,
      String email,
      String? imageLink,
      Color backgroundColor,
      String backendUserId,
      ) {
    return Material(
      color: backgroundColor,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 24,
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white.withOpacity(0.8),
              backgroundImage: getUserImage(imageLink),
              child: getUserImage(imageLink) == null
                  ? Icon(
                Icons.person,
                size: 50,
                color: Colors.grey[400],
              )
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChangeProfile(uid: backendUserId),
                      ),
                    );
                    if (result == true && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                          settings: const RouteSettings(name: '/'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  tooltip: "Chỉnh sửa hồ sơ",
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuItems(BuildContext context, String backendUserId) {
    // ... Giữ nguyên
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Wrap(
        runSpacing: 8,
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.black54),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                    settings: const RouteSettings(name: '/'),
                  ),
                );
              }
            },
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.black54),
            title: const Text('Đổi mật khẩu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChangePassword()),
              );
            },
            dense: true,
          ),
          const Divider(thickness: 0.8),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[600]),
            title: Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red[600]),
            ),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Xác nhận Đăng xuất"),
                  content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Hủy",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _performLogout(context);
                      },
                      child: Text(
                        "Đăng xuất",
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              );
            },
            dense: true,
          ),
        ],
      ),
    );
  }

  // SỬA HÀM NÀY: Xóa Firebase logout
  Future<void> _performLogout(BuildContext context) async {
    try {
      final ApiService apiService = ApiService();
      // Gọi hàm logout của ApiService (nếu có) hoặc tự xóa token
      await apiService.logout(); 

      // Nếu ApiService.logout() của bạn chưa xóa prefs thì gọi dòng dưới:
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.clear();

      print("Đã đăng xuất");

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
              (route) => false,
        );
      }
    } catch (e) {
      print("Lỗi khi đăng xuất: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng xuất thất bại.")),
        );
      }
    }
  }

  ImageProvider? getUserImage(String? imageLink) {
    // ... Giữ nguyên
    if (imageLink == null || imageLink.isEmpty) return null;
    try {
      if (imageLink.startsWith('http')) return NetworkImage(imageLink);
      UriData? data = Uri.tryParse(imageLink)?.data;
      if (data != null && data.isBase64) {
        return MemoryImage(data.contentAsBytes());
      }
      final bytes = base64Decode(imageLink);
      return MemoryImage(bytes);
    } catch (e) {
      print("Lỗi decode ảnh: $e");
      return null;
    }
  }
}