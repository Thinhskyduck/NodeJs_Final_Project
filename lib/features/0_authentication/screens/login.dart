import 'package:cross_platform_mobile_app_development/core/constants/app_constants.dart';
import 'package:cross_platform_mobile_app_development/data/services/api_service.dart';
import 'package:cross_platform_mobile_app_development/features/0_authentication/screens/reset_password.dart';
import 'package:cross_platform_mobile_app_development/features/0_authentication/screens/signup.dart';
import 'package:cross_platform_mobile_app_development/features/1_home/screens/home_screen.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // --- Constants ---
  static const Color primaryColor = Color(0xFFD70018); // Đỏ CellphoneS
  static const Color textDark = Color(0xFF212529);
  static const Color textGrey = Color(0xFF868E96);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // 1. Validate Form
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ email và mật khẩu.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Gọi API
      final apiService = ApiService();
      final user = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        // 3. Thành công -> Clear Stack và về Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() => _errorMessage = 'Thông tin đăng nhập không chính xác.');
      }
    } catch (e) {
       setState(() => _errorMessage = 'Lỗi kết nối: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBackToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Ẩn bàn phím khi chạm ra ngoài
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FA), // Nền xám hiện đại
        body: Stack(
          children: [
            // Background decoration (Optional circles)
            Positioned(top: -100, right: -100, child: _buildBlob(primaryColor.withOpacity(0.05))),
            Positioned(bottom: -100, left: -100, child: _buildBlob(Colors.blue.withOpacity(0.05))),

            // Main Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Logo Section (Không dùng ảnh) ---
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 5))
                          ]
                        ),
                        child: const Icon(Icons.bolt, color: primaryColor, size: 45),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Chào mừng trở lại!',
                        style: GoogleFonts.roboto(fontSize: 26, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để tiếp tục trải nghiệm mua sắm',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(fontSize: 15, color: textGrey),
                      ),
                      const SizedBox(height: 32),

                      // --- Login Form Card ---
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
                             // Hiển thị lỗi nếu có
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: primaryColor, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: primaryColor, fontSize: 13))),
                                  ],
                                ),
                              ),

                            // Input Email
                            _buildInputField(
                              controller: _emailController,
                              label: 'Email / Số điện thoại',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),

                            // Input Password
                            _buildInputField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen())),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: textGrey),
                                child: Text('Quên mật khẩu?', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500)),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('ĐĂNG NHẬP', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),

                            const SizedBox(height: 24),
                            
                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("Hoặc", style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey[400])),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Google Login Button (No Image)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final url = Uri.parse('${AppConstants.baseUrl.replaceAll("/api", "")}/api/auth/google');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, webOnlyWindowName: '_self');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.public, color: Color(0xFFDB4437)), // Giả lập icon Google
                                    const SizedBox(width: 12),
                                    Text('Tiếp tục với Google', style: GoogleFonts.roboto(color: textDark, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            
                            // Sign Up
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.roboto(color: textGrey, fontSize: 15),
                                children: [
                                  const TextSpan(text: 'Chưa có tài khoản? '),
                                  TextSpan(
                                    text: 'Đăng ký ngay',
                                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUp())),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // --- Modern Back Button ---
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onBackToHome,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: const Icon(Icons.close_rounded, size: 24, color: textDark),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper: Input Decoration Builder
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      style: GoogleFonts.roboto(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textGrey),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // Helper: Decoration Blob
  Widget _buildBlob(Color color) {
    return Container(
      width: 250, height: 250,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}