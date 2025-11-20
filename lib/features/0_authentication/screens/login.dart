import 'dart:async';

import 'package:cross_platform_mobile_app_development/features/1_home/screens/home_screen.dart'; // Giữ đường dẫn thực tế của bạn
import 'package:flutter/material.dart';

import '../../../data/services/api_service.dart'; // Import Service mới
import 'reset_password.dart'; // Giữ đường dẫn thực tế của bạn
import 'signup.dart'; // Giữ đường dẫn thực tế của bạn

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;


  Future<void> _signIn() async {
    // 1. Validate cơ bản
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin.';
      });
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

      if (user != null) {
        // 3. Thành công -> Vào Home
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Đăng nhập thất bại. Kiểm tra email/pass.';
        });
      }
    } catch (e) {
       setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            colors: [primaryColor.withOpacity(0.6), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 80,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome Back!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please login to continue",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: lightBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() { _obscureText = !_obscureText; });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: lightBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
                      ),
                    ),
                    const SizedBox(height: 15),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: primaryColor,
                        ),
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(
                      height: 50,
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                          : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUp()),
                            );
                          },
                          child: Text(
                            "Sign Up",
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
}