import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/user_model.dart'; // Đảm bảo UserModel có field addresses

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final ApiService _apiService = ApiService();
  
  // SỬA 1: Đổi từ List<dynamic> thành List<UserAddress> để code hiểu đúng kiểu dữ liệu
  List<UserAddress> _addresses = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    final user = await _apiService.getUserProfile();
    if (mounted) {
      setState(() {
        // Backend trả về user có field 'addresses' là List<UserAddress>
        _addresses = user?.addresses ?? []; 
        _isLoading = false;
      });
    }
  }

  void _navigateToAddAddress() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const AddAddressScreen())
    );
    if (result == true) {
      _fetchAddresses(); // Reload nếu có thêm mới
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sổ địa chỉ")),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? const Center(child: Text("Chưa có địa chỉ nào"))
              : ListView.builder(
                  itemCount: _addresses.length,
                  itemBuilder: (ctx, i) {
                    final addr = _addresses[i];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      // SỬA 2: Dùng dấu chấm (.) thay vì ['key']
                      // addr là object UserAddress, không phải Map
                      title: Text(addr.addressLine), 
                      subtitle: Text("${addr.city}, ${addr.country}"),
                      isThreeLine: true,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAddress,
        child: const Icon(Icons.add),
      ),
    );
  }
}
// Màn hình thêm địa chỉ nhỏ gọn
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});
  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _addrController = TextEditingController();
  final _cityController = TextEditingController();
  final _apiService = ApiService();

  Future<void> _submit() async {
    if (_addrController.text.isEmpty || _cityController.text.isEmpty) return;
    
    final success = await _apiService.addAddress(
      _addrController.text, 
      _cityController.text, 
      "70000", // Zipcode giả định
      "Vietnam"
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi thêm địa chỉ")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm địa chỉ mới")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _addrController, decoration: const InputDecoration(labelText: "Số nhà, tên đường")),
            const SizedBox(height: 10),
            TextField(controller: _cityController, decoration: const InputDecoration(labelText: "Tỉnh/Thành phố")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text("Lưu địa chỉ"))
          ],
        ),
      ),
    );
  }
}