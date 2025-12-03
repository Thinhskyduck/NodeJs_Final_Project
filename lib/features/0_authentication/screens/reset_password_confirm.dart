import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import 'login.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  final String token; 

  const ResetPasswordConfirmScreen({super.key, required this.token});

  @override
  State<ResetPasswordConfirmScreen> createState() => _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState extends State<ResetPasswordConfirmScreen> {
  // Styles
  static const Color primaryColor = Color(0xFFD70018);
  static const Color textDark = Color(0xFF212529);

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _message;

  Future<void> _submitNewPassword() async {
    if (_passwordController.text.length < 6) {
       setState(() => _message = "Mật khẩu phải từ 6 ký tự trở lên.");
       return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _message = "Mật khẩu xác nhận không khớp.");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/reset-password/${widget.token}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': _passwordController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        setState(() => _message = data['message'] ?? "Lỗi không xác định từ server.");
      }
    } catch (e) {
      setState(() => _message = "Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            SizedBox(height: 12),
            Text("Thành công!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Mật khẩu của bạn đã được thay đổi. Vui lòng đăng nhập lại.", textAlign: TextAlign.center),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Login()),
                  (route) => false,
                );
              },
              child: const Text("Đăng nhập ngay", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FA),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                   const Icon(Icons.password_rounded, size: 50, color: primaryColor),
                   const SizedBox(height: 16),
                   Text(
                    "Đặt lại mật khẩu mới",
                    style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hãy nhập mật khẩu mạnh để bảo vệ tài khoản.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        if (_message != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 20, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_message!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                              ],
                            ),
                          ),

                        _buildPassField(
                          controller: _passwordController,
                          label: "Mật khẩu mới",
                          obscure: _obscurePass,
                          onToggle: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildPassField(
                          controller: _confirmPasswordController,
                          label: "Xác nhận mật khẩu",
                          obscure: _obscureConfirm,
                          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitNewPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : const Text("XÁC NHẬN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const Login()),
                      (route) => false,
                    ),
                    child: const Text("Hủy bỏ, quay về đăng nhập", style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
      ),
    );
  }
}