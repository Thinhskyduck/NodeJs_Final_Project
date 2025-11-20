import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/api_service.dart';
import '../../1_home/screens/home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success = await _apiService.createOrder(
      addressLine: _addressController.text,
      city: _cityController.text,
      phone: _phoneController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      // Hiển thị thông báo thành công và về trang chủ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Đặt hàng thành công!"),
          content: const Text("Cảm ơn bạn đã mua hàng. Đơn hàng của bạn đang được xử lý."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng dialog
                // Quay về Home và xóa hết các màn hình trước đó (Cart, Checkout)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text("Về trang chủ"),
            )
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đặt hàng thất bại. Vui lòng thử lại."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Thông tin giao hàng", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Số nhà, Tên đường", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập địa chỉ" : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "Tỉnh / Thành phố", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập thành phố" : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Vui lòng nhập số điện thoại" : null,
              ),
              
              const SizedBox(height: 30),
              Text("Phương thức thanh toán", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
              const ListTile(
                leading: Icon(Icons.money, color: Colors.green),
                title: Text("Thanh toán khi nhận hàng (COD)"),
                trailing: Icon(Icons.check_circle, color: Colors.blue),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("XÁC NHẬN ĐẶT HÀNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}