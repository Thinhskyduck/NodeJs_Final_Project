import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import '../../../core/constants/app_constants.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // Controllers cho thông tin cá nhân
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  
  // Controllers mới cho địa chỉ
  final TextEditingController _cityController = TextEditingController(); 
  final TextEditingController _detailAddressController = TextEditingController(); 

  bool _obscureText = true;
  String errorMessage = "";
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneNumberController.dispose();
    _cityController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    // 1. Validate: Kiểm tra tất cả các trường, bao gồm 2 trường địa chỉ mới
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        fullNameController.text.trim().isEmpty ||
        phoneNumberController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _detailAddressController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Vui lòng điền đầy đủ thông tin (bao gồm Tỉnh và Địa chỉ chi tiết).";
      });
      return;
    }

    if (!emailController.text.contains('@')) {
      setState(() {
        errorMessage = "Địa chỉ email không hợp lệ.";
      });
      return;
    }

    if (passwordController.text.trim().length < 6) {
      setState(() {
        errorMessage = "Mật khẩu phải có ít nhất 6 ký tự.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      // 2. Cấu trúc lại Body JSON gửi lên Server
      final Map<String, dynamic> requestBody = {
        "email": emailController.text.trim(),
        "fullName": fullNameController.text.trim(),
        "phone_number": phoneNumberController.text.trim(),
        "password": passwordController.text.trim(),
        // Object address lồng nhau theo yêu cầu mới
        "shippingAddress": {
           "addressLine": _detailAddressController.text.trim(), // VD: 71, Xã Nhị Long
           "city": _cityController.text.trim(),                 // VD: Vĩnh Long
           "postalCode": "70000",                               // Mặc định hoặc cho nhập nếu cần
           "country": "Vietnam"                                 // Mặc định
        }
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/register'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); // Quay lại màn hình Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        String apiErrorMessage = 'Lỗi không xác định từ server.';
        
        // Xử lý thông báo lỗi linh hoạt
        if (errorData['message'] != null) {
          apiErrorMessage = errorData['message'].toString();
        } else if (errorData['detail'] != null) {
          apiErrorMessage = errorData['detail'].toString();
        }

        setState(() {
          errorMessage = 'Đăng ký thất bại: $apiErrorMessage';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Đã xảy ra lỗi kết nối: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = Colors.blue[700]!;
    final Color lightBackgroundColor = Colors.blue[50]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.5), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30.0, vertical: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 60,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Create Account",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Fill in the details below to register",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 35),
                    
                    _buildTextField(
                      controller: fullNameController,
                      hintText: "Full Name",
                      icon: Icons.person_outline,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                    ),
                    const SizedBox(height: 18),
                    
                    _buildTextField(
                      controller: emailController,
                      hintText: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                    ),
                    const SizedBox(height: 18),
                    
                    _buildTextField(
                      controller: phoneNumberController,
                      hintText: "Phone Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                    ),
                    const SizedBox(height: 18),

                    // --- CẬP NHẬT GIAO DIỆN ĐỊA CHỈ MỚI ---
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("Shipping Address", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1. Ô nhập Tỉnh/Thành phố
                    _buildTextField(
                      controller: _cityController,
                      hintText: "City / Province (e.g. Can Tho)",
                      icon: Icons.location_city,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                    ),
                    const SizedBox(height: 18),

                    // 2. Ô nhập Địa chỉ chi tiết
                    _buildTextField(
                      controller: _detailAddressController,
                      hintText: "Street, Ward, House No.",
                      icon: Icons.home_outlined,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                    ),
                    // ----------------------------------------
                    
                    const SizedBox(height: 18),

                    _buildPasswordField(
                      controller: passwordController,
                      hintText: "Password (min. 6 characters)",
                      obscureText: _obscureText,
                      primaryColor: primaryColor,
                      lightBackgroundColor: lightBackgroundColor,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    const SizedBox(height: 25),
                    
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          errorMessage,
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    SizedBox(
                      height: 50,
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: primaryColor))
                          : ElevatedButton(
                              onPressed: signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                "SIGN UP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Login()),
                                  );
                                },
                          child: Text(
                            "Login",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required Color primaryColor,
    required Color lightBackgroundColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: lightBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required Color primaryColor,
    required Color lightBackgroundColor,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.lock_outline, color: primaryColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[600],
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: lightBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
      ),
    );
  }
}