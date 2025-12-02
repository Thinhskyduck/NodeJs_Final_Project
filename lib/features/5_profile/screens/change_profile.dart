import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import 'address_list_screen.dart'; 

class ChangeProfile extends StatefulWidget {
  // Không cần truyền uid nữa vì ApiService tự lấy từ Token, 
  // nhưng nếu bạn muốn giữ để tương thích code cũ thì cứ để.
  final String uid; 

  const ChangeProfile({super.key, required this.uid});

  @override
  State<ChangeProfile> createState() => _ChangeProfileState();
}

class _ChangeProfileState extends State<ChangeProfile> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(); // Khởi tạo Service

  bool _isLoading = true;
  String? _errorMessage;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Hàm load dữ liệu dùng ApiService
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Gọi hàm có sẵn trong ApiService
      final userModel = await _apiService.getUserProfile();

      if (!mounted) return;

      if (userModel != null) {
        setState(() {
          _fullNameController.text = userModel.fullName;
          _emailController.text = userModel.email;
        });
      } else {
        setState(() {
          _errorMessage = "Không tải được thông tin người dùng.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hàm lưu dữ liệu dùng ApiService
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Gọi hàm mới thêm trong ApiService
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
          ),
        );
        Navigator.of(context).pop(true); // Trả về true để màn hình trước reload
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
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text("Chỉnh sửa Hồ sơ"),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _errorMessage == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!)
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    
                    // --- Họ và tên ---
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: "Họ và tên",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) 
                          ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 20),

                    // --- Số điện thoại ---
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: "Số điện thoại",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value == null || value.trim().isEmpty) 
                          ? 'Vui lòng nhập số điện thoại' : null,
                    ),
                    const SizedBox(height: 20),

                    // --- QUẢN LÝ ĐỊA CHỈ (Nút bấm) ---
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: const Icon(Icons.location_on_outlined, color: Colors.blue),
                      title: const Text(
                        "Quản lý địa chỉ giao hàng",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const AddressListScreen())
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Email (Read Only) ---
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email (Không thể thay đổi)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 35),

                    // --- Nút Lưu ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text("Lưu thay đổi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}