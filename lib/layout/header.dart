import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/1_home/screens/home_screen.dart';
import '../features/2_product/screens/catalog_screen.dart';
import '../features/2_product/screens/product_detail.dart';

class CustomHeader extends StatelessWidget {
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
    dynamic onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      color: Colors.blue[700], // Màu chủ đạo
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: isDesktop 
        ? _buildDesktopHeader(context) 
        : _buildMobileHeader(context),
    );
  }

  // --- GIAO DIỆN DESKTOP ---
  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        // 1. Logo
        InkWell(
          onTap: onLogoTap ?? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
          child: Text("TDTU Shop", style: GoogleFonts.roboto(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(width: 40),

        // 2. Menu Links (Thay thế BottomNavBar)
        _buildNavButton(context, "Trang chủ", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()))),
        const SizedBox(width: 20),
        _buildNavButton(context, "Sản phẩm", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()))),
        
        const SizedBox(width: 40),

        // 3. Search Bar
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: onSearchSubmitted ?? (val) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogScreen(initialSearch: val)));
              },
            ),
          ),
        ),
        
        const SizedBox(width: 30),

        // 4. Actions (Cart & Account)
        IconButton(
          onPressed: onCartPressed, 
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          tooltip: "Giỏ hàng",
        ),
        const SizedBox(width: 10),
        
        InkWell(
          onTap: onAccountPressed,
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                currentUserData != null ? "Chào, ${currentUserData!['full_name'].split(' ').last}" : "Đăng nhập",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )
            ],
          ),
        )
      ],
    );
  }

  // --- GIAO DIỆN MOBILE ---
  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onLogoTap,
          child: const Text("TDTU Shop", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white), 
              onPressed: () {
                // Chuyển sang màn hình Catalog để user tìm kiếm
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen()));
              }
            ), 
            IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.white), onPressed: onCartPressed),
            IconButton(icon: const Icon(Icons.person, color: Colors.white), onPressed: onAccountPressed),
          ],
        )
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, String title, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}