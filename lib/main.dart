import 'package:cross_platform_mobile_app_development/data/services/api_service.dart';
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
          
          // Thay vì về Home ngay, ta về màn hình xử lý
          return MaterialPageRoute(
            builder: (_) => AuthProcessingScreen(token: token!),
          );
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

}

// Màn hình trung gian để xử lý lưu token
class AuthProcessingScreen extends StatefulWidget {
  final String token;
  const AuthProcessingScreen({super.key, required this.token});

  @override
  State<AuthProcessingScreen> createState() => _AuthProcessingScreenState();
}

class _AuthProcessingScreenState extends State<AuthProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _saveAndRedirect();
  }

  Future<void> _saveAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, widget.token);
    
    // Gọi API lấy profile ngay tại đây để cache thông tin user
    final apiService = ApiService();
    await apiService.getUserProfile(); 

    if (mounted) {
      // Chuyển hướng về Home và xóa các màn hình trước đó
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}