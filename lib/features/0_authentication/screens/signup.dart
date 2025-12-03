import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // --- Style Constants ---
  static const Color primaryColor = Color(0xFFD70018); // Đỏ CellphoneS
  static const Color textDark = Color(0xFF212529);
  static const Color textGrey = Color(0xFF868E96);

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  
  // Controllers cho địa chỉ
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

  // --- LOGIC GIỮ NGUYÊN ---
  Future<void> signUp() async {
    // 1. Validate
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
      // 2. Cấu trúc JSON gửi lên Server
      final Map<String, dynamic> requestBody = {
        "email": emailController.text.trim(),
        "fullName": fullNameController.text.trim(),
        "phone_number": phoneNumberController.text.trim(),
        "password": passwordController.text.trim(),
        // Object address lồng nhau theo logic cũ
        "shippingAddress": {
           "addressLine": _detailAddressController.text.trim(),
           "city": _cityController.text.trim(),
           "postalCode": "70000",
           "country": "Vietnam"
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

      if (!mounted) return;

      if (response.statusCode == 201) {
          // Quay lại màn hình Login nếu thành công
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login())); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
                backgroundColor: Colors.green),
          );
      } else {
        final errorData = jsonDecode(response.body);
        String apiErrorMessage = 'Lỗi không xác định từ server.';
        
        if (errorData['message'] != null) {
          apiErrorMessage = errorData['message'].toString();
        } else if (errorData['detail'] != null) {
          apiErrorMessage = errorData['detail'].toString();
        }

        setState(() {
          errorMessage = apiErrorMessage;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi kết nối: ${e.toString()}";
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI PART ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FA),
        body: Stack(
          children: [
             // Decorations
            Positioned(top: -120, left: -100, child: _buildBlob(primaryColor.withOpacity(0.05))),
            Positioned(bottom: -120, right: -100, child: _buildBlob(Colors.blue.withOpacity(0.05))),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                       // --- Header ---
                      const Icon(Icons.person_add_outlined, size: 50, color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Tạo tài khoản mới',
                        style: GoogleFonts.roboto(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập thông tin chi tiết bên dưới',
                        style: GoogleFonts.roboto(fontSize: 15, color: textGrey),
                      ),
                      const SizedBox(height: 32),

                      // --- Main Card ---
                      Container(
                        padding: EdgeInsets.all(isMobile ? 24 : 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (errorMessage.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                              ),

                            _buildSectionLabel("Thông tin cá nhân"),
                            _buildInputField(fullNameController, "Họ và tên", Icons.badge_outlined),
                            const SizedBox(height: 16),
                            _buildInputField(emailController, "Email", Icons.email_outlined, type: TextInputType.emailAddress),
                            // const SizedBox(height: 16),
                            // _buildInputField(phoneNumberController, "Số điện thoại", Icons.phone_iphone, type: TextInputType.phone),
                            
                            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                            
                            _buildSectionLabel("Địa chỉ giao hàng"),
                            Row(
                              children: [
                                Expanded(child: _buildInputField(_cityController, "Tỉnh / TP", Icons.location_city)),
                                const SizedBox(width: 12),
                                Expanded(flex: 2, child: _buildInputField(_detailAddressController, "Số nhà, đường, phường", Icons.home_outlined)),
                              ],
                            ),

                            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                            _buildSectionLabel("Bảo mật"),
                            _buildInputField(passwordController, "Mật khẩu (tối thiểu 6 ký tự)", Icons.lock_outline, isPassword: true),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text("ĐĂNG KÝ", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Footer Link
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.roboto(color: textGrey, fontSize: 15),
                          children: [
                            const TextSpan(text: 'Đã có tài khoản? '),
                            TextSpan(
                              text: 'Đăng nhập',
                              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
                                },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: const Icon(Icons.arrow_back, size: 24, color: textDark),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label.toUpperCase(), style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: textGrey)),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword ? _obscureText : false,
      style: GoogleFonts.roboto(fontSize: 15, color: textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor)),
        suffixIcon: isPassword
          ? IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400], size: 20),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
          : null,
      ),
    );
  }

  Widget _buildBlob(Color color) {
    return Container(width: 300, height: 300, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}