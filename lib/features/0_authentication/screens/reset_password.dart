import 'package:cross_platform_mobile_app_development/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Constants
  static const Color primaryColor = Color(0xFFD70018); // CellphoneS Red
  static const Color textDark = Color(0xFF212529);
  static const Color textGrey = Color(0xFF868E96);

  final TextEditingController emailController = TextEditingController();
  String errorMessage = "";
  bool isLoading = false;
  bool _emailSent = false;

  Future<void> resetPassword() async {
    String email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorMessage = "Vui lòng nhập địa chỉ email hợp lệ.";
        _emailSent = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
      _emailSent = false;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/forgot-password'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        setState(() {
          isLoading = false;
          _emailSent = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Link reset đã gửi tới $email"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi: ${errorData['message'] ?? 'Không thể gửi email.'}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Đã xảy ra lỗi kết nối: ${e.toString()}";
      });
    }
  }

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
            Positioned(top: -150, right: -150, child: _buildBlob(primaryColor.withOpacity(0.05))),
            Positioned(bottom: -150, left: -150, child: _buildBlob(Colors.blue.withOpacity(0.05))),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    children: [
                      // Icon Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))]),
                        child: const Icon(Icons.lock_reset, size: 50, color: primaryColor),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        "Quên mật khẩu?",
                        style: GoogleFonts.roboto(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Nhập email của bạn, chúng tôi sẽ gửi liên kết để đặt lại mật khẩu.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(fontSize: 15, color: textGrey, height: 1.4),
                      ),
                      const SizedBox(height: 32),

                      // Main Card
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
                          children: [
                            // Success State
                            if (_emailSent)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Đã gửi thành công tới\n${emailController.text}",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(color: Colors.green.shade800, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Vui lòng kiểm tra hộp thư (cả mục Spam)", style: GoogleFonts.roboto(fontSize: 12, color: Colors.green.shade600)),
                                  ],
                                ),
                              )
                            else ...[
                              // Error Message
                              if (errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                                  ),
                                ),

                              // Input Field
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email của bạn",
                                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : resetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text("GỬI YÊU CẦU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login())),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text("Quay lại đăng nhập"),
                        style: TextButton.styleFrom(foregroundColor: textGrey),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBlob(Color color) {
    return Container(width: 400, height: 400, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}