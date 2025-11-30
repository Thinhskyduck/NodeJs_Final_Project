import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import 'login.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  final String token; // Token nhận từ URL

  const ResetPasswordConfirmScreen({super.key, required this.token});

  @override
  State<ResetPasswordConfirmScreen> createState() => _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState extends State<ResetPasswordConfirmScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _submitNewPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _message = "Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Gọi API reset password
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/reset-password/${widget.token}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': _passwordController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Thành công
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Thành công"),
            content: const Text("Mật khẩu đã được đặt lại. Vui lòng đăng nhập."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Chuyển về trang Login
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
                  );
                },
                child: const Text("Đăng nhập ngay"),
              )
            ],
          ),
        );
      } else {
        setState(() => _message = data['message'] ?? "Lỗi không xác định");
      }
    } catch (e) {
      setState(() => _message = "Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đặt lại mật khẩu")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Nhập mật khẩu mới của bạn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu mới",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Xác nhận mật khẩu",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_message!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitNewPassword,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Đổi mật khẩu"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}