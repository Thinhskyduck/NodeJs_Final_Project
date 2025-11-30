import 'package:cross_platform_mobile_app_development/features/1_home/screens/home_screen.dart';
import 'package:cross_platform_mobile_app_development/features/0_authentication/screens/login.dart';
import 'package:cross_platform_mobile_app_development/data/services/api_service.dart'; // Import API Service
import 'package:flutter/material.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmedPasswordVisible = false;

  String errorMessage = "";
  bool isLoading = false;

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final ApiService _apiService = ApiService(); // Khởi tạo ApiService

  // Hàm đăng xuất sau khi đổi mật khẩu thành công
  Future<void> signOut() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  Future<void> changePassword() async {
    // 1. Validate dữ liệu nhập vào
    if (oldPasswordController.text.isEmpty) {
      setState(() => errorMessage = "Vui lòng nhập mật khẩu cũ");
      return;
    }
    if (newPasswordController.text.isEmpty) {
      setState(() => errorMessage = "Vui lòng nhập mật khẩu mới");
      return;
    }
    if (confirmPasswordController.text.isEmpty) {
      setState(() => errorMessage = "Vui lòng nhập xác nhận mật khẩu");
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = "Mật khẩu mới không khớp!");
      return;
    }
    if (newPasswordController.text.length < 6) {
      setState(() => errorMessage = "Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }
    if (oldPasswordController.text == newPasswordController.text) {
       setState(() => errorMessage = "Mật khẩu mới không được trùng mật khẩu cũ");
       return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    // 2. Gọi API đổi mật khẩu
    final result = await _apiService.changePassword(
      oldPasswordController.text.trim(), 
      newPasswordController.text.trim()
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      // Thành công
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công! Vui lòng đăng nhập lại."),
          backgroundColor: Colors.green,
        ),
      );
      // Đăng xuất để user đăng nhập lại bằng mật khẩu mới
      signOut();
    } else {
      // Thất bại
      setState(() {
        errorMessage = result['message'];
      });
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.blue.shade700, // Chỉnh lại màu cho đồng bộ app
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      body: Align(
        alignment: Alignment.center,
        child: Container(
          height: size.height * 0.75, // Tăng chiều cao một chút
          width: double.infinity,
          margin: const EdgeInsets.only(top: 20), // Thêm margin top
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), 
              topRight: Radius.circular(30)
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "ĐỔI MẬT KHẨU",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),

                  // Mật khẩu cũ
                  TextField(
                    controller: oldPasswordController,
                    obscureText: !_oldPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu cũ",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _oldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _oldPasswordVisible = !_oldPasswordVisible);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mật khẩu mới
                  TextField(
                    controller: newPasswordController,
                    obscureText: !_newPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu mới",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _newPasswordVisible = !_newPasswordVisible);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Xác nhận mật khẩu mới
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !_confirmedPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Xác nhận mật khẩu mới",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmedPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _confirmedPasswordVisible = !_confirmedPasswordVisible);
                        },
                      ),
                    ),
                  ),

                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 40),

                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                              )
                            ),
                            child: const Text(
                              "LƯU THAY ĐỔI",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}