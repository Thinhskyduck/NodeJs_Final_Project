import 'package:cross_platform_mobile_app_development/features/0_authentication/screens/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // home: const HomeScreen(),
      home: const Login(),

      // home: const CartScreen(),
      // home: const CheckoutPaymentScreen(),
      // home: const CheckoutInfoScreen(),
      // home: const ProductDetailsScreen2()
      // home: const AccountPage(),
      // home:  ShipperApp(),
    );
  }
}
