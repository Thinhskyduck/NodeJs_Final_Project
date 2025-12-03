import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/cart_service.dart';
import '../../../layout/header.dart';
import '../../1_home/screens/home_screen.dart';
import '../../3_cart/screens/cart_screen.dart';
import 'profile_screen.dart';

// ==========================================
// Màn hình Danh sách địa chỉ
// ==========================================
class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  
  List<UserAddress> _addresses = [];
  bool _isLoading = true;

  // --- HEADER DATA ---
  List<Map<String, dynamic>> _headerCategories = [];
  Map<String, dynamic>? _currentUserData;
  int _cartItemCount = 0;

  // --- STYLE ---
  static const Color _primaryBlue = Color(0xFF007BFF);
  static const Color _bgGray = Color(0xFFF4F6F8);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAddresses(),
      _fetchHeaderData(),
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
          _headerCategories = categories;
          _currentUserData = userData;
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      debugPrint("Header error: $e");
    }
  }

  // Tải danh sách và sắp xếp
  Future<void> _fetchAddresses() async {
    try {
      final user = await _apiService.getUserProfile();
      if (mounted && user != null) {
        setState(() {
          _addresses = user.addresses;
          // Sắp xếp: Mặc định lên đầu
          _addresses.sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải địa chỉ: $e");
    }
  }

  void _navigateToAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );

    if (result == true) {
      // Reload lại nhưng cần set loading để user biết đang cập nhật
      setState(() => _isLoading = true);
      await _fetchAddresses();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultAddress(UserAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Đặt làm mặc định?"),
        content: Text("Chọn \"${address.addressLine}\" làm địa chỉ giao hàng chính?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white),
            child: const Text("Đồng ý"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _apiService.setDefaultAddress(address.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật địa chỉ mặc định"), backgroundColor: Colors.green));
          await _fetchAddresses(); // Tải lại danh sách
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối"), backgroundColor: Colors.red));
        }
        // --- SỬA LỖI Ở ĐÂY: Tắt loading sau khi hoàn tất ---
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Xóa địa chỉ?", style: TextStyle(color: Colors.red)),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _apiService.deleteAddress(addressId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa địa chỉ"), backgroundColor: Colors.green));
          await _fetchAddresses();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể xóa"), backgroundColor: Colors.red));
        }
        // --- SỬA LỖI Ở ĐÂY: Tắt loading sau khi hoàn tất ---
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kIsWeb ? 110 : 60 + MediaQuery.of(context).padding.top),
        child: CustomHeader(
          categories: _headerCategories,
          currentUserData: _currentUserData,
          cartItemCount: _cartItemCount,
          onCartPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          onAccountPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())),
          onLogoTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800), // Giới hạn width trên Web
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb & Title
                    _buildBreadcrumbs(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Sổ địa chỉ", style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Thêm địa chỉ mới"),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    // List Content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                           await _fetchAddresses();
                           // onRefresh tự tắt indicator, không cần set isLoading
                        },
                        child: _addresses.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _addresses.length,
                                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                                itemBuilder: (ctx, i) => _buildAddressCard(_addresses[i]),
                              ),
                      ),
                    ),
                  ],
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
        const Text("Sổ địa chỉ", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Bạn chưa lưu địa chỉ nào", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAddressCard(UserAddress addr) {
    final bool isDefault = addr.isDefault;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: _primaryBlue, width: 1.5) : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDefault ? null : () => _setDefaultAddress(addr),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Location
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDefault ? Colors.blue[50] : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: isDefault ? _primaryBlue : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Thông tin địa chỉ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  addr.addressLine,
                                  style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              if (isDefault)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: Text(
                                    "Mặc định",
                                    style: TextStyle(color: _primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("${addr.city}, ${addr.country}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("Postal Code: ${addr.postalCode}", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Footer Actions (Chỉ hiện nút xóa nếu không phải mặc định)
                if (!isDefault) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteAddress(addr.id),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text("Xóa địa chỉ", style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Màn hình Thêm địa chỉ mới
// ==========================================
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _addrController = TextEditingController(); 
  final _cityController = TextEditingController(); 
  final _apiService = ApiService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addrController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_addrController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ Tỉnh và Địa chỉ chi tiết")));
      return;
    }
    
    setState(() => _isSubmitting = true);

    final success = await _apiService.addAddress(
      _addrController.text.trim(), 
      _cityController.text.trim(), 
      "70000", 
      "Vietnam"
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi lưu. Vui lòng thử lại.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thêm địa chỉ mới"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[200], height: 1)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Thông tin vận chuyển", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Vui lòng nhập chính xác để giao hàng nhanh nhất.", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 30),

              _buildTextField(
                controller: _cityController,
                label: "Tỉnh / Thành phố",
                hint: "VD: Cần Thơ, Vĩnh Long...",
                icon: Icons.location_city,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _addrController,
                label: "Địa chỉ chi tiết",
                hint: "Số nhà, Tên đường, Phường/Xã...",
                icon: Icons.home_outlined,
                capitalization: TextCapitalization.sentences,
                isMultiline: true,
              ),
              
              const SizedBox(height: 40),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text("LƯU ĐỊA CHỈ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isMultiline ? 2 : 1,
          textCapitalization: capitalization,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF007BFF), width: 1.5)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}