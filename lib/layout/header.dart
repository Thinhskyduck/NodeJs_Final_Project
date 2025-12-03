// lib/layout/header.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/1_home/screens/home_screen.dart';
import '../features/2_product/screens/catalog_screen.dart';
import '../features/3_cart/screens/cart_screen.dart';
import '../features/0_authentication/screens/login.dart';

class CustomHeader extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? currentUserData;
  final int cartItemCount;
  final VoidCallback? onCartPressed;
  final VoidCallback? onAccountPressed;
  final VoidCallback? onLogoTap;
  final Function(String)? onSearchSubmitted;

  const CustomHeader({
    super.key,
    required this.categories,
    this.currentUserData,
    this.cartItemCount = 0,
    this.onCartPressed,
    this.onAccountPressed,
    this.onLogoTap,
    this.onSearchSubmitted,
  });

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  final TextEditingController _searchController = TextEditingController();
  static const Color _primaryRed = Color(0xFFD70018); // Đỏ CellphoneS
  static const double _maxWidth = 1240;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (widget.onSearchSubmitted != null) {
      widget.onSearchSubmitted!(query);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogScreen(initialSearch: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _primaryRed,
      // --- THAY ĐỔI Ở ĐÂY: Tăng padding từ 12 lên 24 để thanh dày hơn ---
      padding: const EdgeInsets.symmetric(vertical: 24), 
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // 1. Logo
                _buildLogo(),

                const SizedBox(width: 32),

                // 2. Search Bar
                _buildSearchBar(),

                const SizedBox(width: 32),

                // 3. Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onLogoTap ??
            () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false,
                ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TDTU SHOP",
              style: GoogleFonts.roboto(
                fontSize: 28, // Font to, rõ ràng
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "Nơi mua sắm tin cậy",
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Container(
        height: 48, // Chiều cao thanh tìm kiếm chuẩn
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // Bo góc mềm mại hơn chút
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Bạn đang tìm gì hôm nay?",
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
            InkWell(
              onTap: _handleSearch,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
              child: Container(
                height: 48,
                width: 60,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _actionItem(
          icon: Icons.phone_in_talk_outlined,
          label: "Gọi mua",
          subLabel: "1800.2097",
        ),
        const SizedBox(width: 24),
        _actionItem(
          icon: Icons.location_on_outlined,
          label: "Cửa hàng",
          subLabel: "Gần bạn",
        ),
        const SizedBox(width: 24),
        _actionItem(
          icon: Icons.shopping_bag_outlined,
          label: "Giỏ hàng",
          badgeCount: widget.cartItemCount,
          onTap: widget.onCartPressed ??
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
        const SizedBox(width: 24),
        _buildUserButton(),
      ],
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    String? subLabel,
    int? badgeCount,
    VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min, // Đảm bảo cột gọn gàng
              children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(height: 4),
                Text(
                  subLabel ?? label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryRed, width: 2), // Viền trùng màu nền để nổi
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(color: _primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserButton() {
    final bool isLoggedIn = widget.currentUserData != null;
    final String displayName = isLoggedIn
        ? (widget.currentUserData!['full_name'] ?? 'User')
        : 'Đăng nhập';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onAccountPressed ??
            () {
              if (!isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
              }
            },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                child: Text(
                  isLoggedIn ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: _primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? "Xin chào" : "Thành viên",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    displayName.length > 12 ? "${displayName.substring(0, 10)}..." : displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}