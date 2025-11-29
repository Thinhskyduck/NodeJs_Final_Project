import 'package:flutter/material.dart';

import 'features/1_home/screens/home_screen.dart'; // Import Home


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nếu bạn không dùng Firebase nữa thì có thể comment dòng này lại để app nhẹ hơn
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'E-commerce App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // SỬA Ở ĐÂY: Đổi Login() thành HomeScreen()
      home: const HomeScreen(), 
    );
  }
}