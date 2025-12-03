import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart'; // Import thư viện này
import 'features/1_home/screens/home_screen.dart'; // Import Home
import 'features/0_authentication/screens/login.dart';
import 'features/0_authentication/screens/reset_password_confirm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'features/4_checkout/screens/order_success_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Gọi hàm này để xóa dấu #
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'TDTU Computer Shop',
      theme: ThemeData(primarySwatch: Colors.blue),
      
      // BỎ home: const HomeScreen(), và thay bằng onGenerateRoute
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Lấy URL hiện tại (Vd: /reset-password/abc123xyz)
        final Uri uri = Uri.parse(settings.name ?? '/');
        
        // --- LOGIC 1: XỬ LÝ GOOGLE LOGIN ---
        // Backend trả về: http://domain/login?token=TOKEN_JWT
        if (uri.path == '/login' && uri.queryParameters.containsKey('token')) {
          final token = uri.queryParameters['token'];
          // Lưu token và chuyển vào Home
          _saveTokenAndNavigate(token!);
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }

        // --- LOGIC 2: XỬ LÝ RESET PASSWORD ---
        // Link email: http://domain/reset-password/TOKEN_RESET
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'reset-password') {
          final token = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => ResetPasswordConfirmScreen(token: token),
          );
        }


        // --- LOGIC 3: XỬ LÝ THANH TOÁN THÀNH CÔNG VNPAY (MỚI) ---
        // Link: http://localhost:3000/order-success?orderId=xxxx
        if (uri.path == '/order-success') {
           final orderId = uri.queryParameters['orderId'] ?? '';
           return MaterialPageRoute(
             builder: (_) => OrderSuccessScreen(orderId: orderId),
           );
        }

        // --- LOGIC 4: XỬ LÝ THANH TOÁN THẤT BẠI ---
        if (uri.path == '/order-failed') {
           // Bạn có thể tạo màn hình Failed riêng hoặc về Home
           // Ở đây ví dụ cho về Home và hiện thông báo lỗi sau
           return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        
        // --- CÁC ROUTE CƠ BẢN ---
        if (uri.path == '/login') {
          return MaterialPageRoute(builder: (_) => const Login());
        }
        
        // Mặc định vào HomeScreen
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }

  // Hàm phụ trợ lưu token nhanh
  Future<void> _saveTokenAndNavigate(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    // Có thể cần gọi API getUserProfile ở đây để lấy info user lưu lại
  }
}