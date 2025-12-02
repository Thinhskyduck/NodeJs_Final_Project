import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/user_model.dart';

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
  List<UserAddress> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  // Tải danh sách và sắp xếp (Mặc định lên đầu)
  Future<void> _fetchAddresses() async {
    try {
      final user = await _apiService.getUserProfile();
      if (mounted) {
        setState(() {
          _addresses = user?.addresses ?? [];
          // Sắp xếp: Địa chỉ mặc định (isDefault = true) đưa lên đầu danh sách
          _addresses.sort((a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi tải địa chỉ: $e");
    }
  }

  // Hàm chuyển sang màn hình thêm mới
  void _navigateToAddAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      _fetchAddresses();
    }
  }

  // Hàm thiết lập địa chỉ mặc định
  Future<void> _setDefaultAddress(UserAddress address) async {
    // Hiển thị dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Đặt làm mặc định?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Bạn muốn chọn địa chỉ \"${address.addressLine}\" làm địa chỉ giao hàng mặc định?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã cập nhật địa chỉ mặc định"), backgroundColor: Colors.green),
          );
          await _fetchAddresses(); // Tải lại để cập nhật UI
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi kết nối khi cập nhật"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Hàm xóa địa chỉ (Tận dụng lại logic)
  Future<void> _deleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Xóa địa chỉ?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn xóa địa chỉ này? Hành động này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa địa chỉ thành công"), backgroundColor: Colors.green),
          );
          await _fetchAddresses();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Không thể xóa địa chỉ này"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: const Text("Sổ địa chỉ"),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAddresses, // Kéo xuống để refresh
              child: _addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "Bạn chưa lưu địa chỉ nào",
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _addresses.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final addr = _addresses[i];
                        return _buildAddressCard(addr);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddAddress,
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("Thêm địa chỉ", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Widget con để hiển thị từng thẻ địa chỉ
  Widget _buildAddressCard(UserAddress addr) {
    final bool isDefault = addr.isDefault;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: Colors.blue, width: 1.5) : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDefault ? null : () => _setDefaultAddress(addr), // Chỉ cho bấm set default nếu chưa phải default
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Location
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDefault ? Colors.blue[50] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isDefault ? Colors.blue[700] : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            // Badge Mặc định
                            if (isDefault)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Mặc định",
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${addr.city}, ${addr.country}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Nút xóa (chỉ hiện nếu không phải mặc định)
              if (!isDefault) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _deleteAddress(addr.id), // Gọi hàm _deleteAddress đã viết
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text("Xóa", style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    // Validate đơn giản
    if (_addrController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đủ Tỉnh và Địa chỉ chi tiết")),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);

    // Backend lưu vào addressLine và city
    final success = await _apiService.addAddress(
      _addrController.text.trim(), 
      _cityController.text.trim(), 
      "70000", 
      "Vietnam"
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true); // Trả về true để reload list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi khi lưu địa chỉ. Vui lòng thử lại.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thêm địa chỉ mới"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Thông tin vận chuyển",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Vui lòng nhập chính xác để giao hàng nhanh nhất.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // 1. Ô nhập Tỉnh/Thành phố
            _buildTextField(
              controller: _cityController,
              label: "Tỉnh / Thành phố",
              hint: "VD: Cần Thơ, Vĩnh Long...",
              icon: Icons.location_city,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            
            // 2. Ô nhập Chi tiết
            _buildTextField(
              controller: _addrController,
              label: "Địa chỉ chi tiết",
              hint: "Số nhà, Đường, Xã/Phường...",
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
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: _isSubmitting 
                  ? const SizedBox(
                      height: 24, width: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                    )
                  : const Text("LƯU ĐỊA CHỈ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget helper để vẽ TextField đẹp hơn
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
            prefixIcon: Icon(icon, color: Colors.blue[700]),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}