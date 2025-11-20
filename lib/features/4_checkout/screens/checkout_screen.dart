import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/cart_model.dart'; // Import CartModel
import '../../1_home/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
class CheckoutScreen extends StatefulWidget {
  // Nhận cartItems từ màn hình trước
  final List<CartItem>? cartItems; 
  final int totalPrice;

  const CheckoutScreen({super.key, this.cartItems, this.totalPrice = 0});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isGuest = false; // Biến cờ để biết là khách hay user

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final user = await _apiService.getUserProfile();
    if (user != null) {
      // Đã đăng nhập -> Điền sẵn thông tin
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      setState(() => _isGuest = false);
    } else {
      // Chưa đăng nhập -> Là khách
      setState(() => _isGuest = true);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success = false;

    if (_isGuest) {
      // --- GUEST CHECKOUT ---
      // Cần map CartItem sang format mà Backend Guest API yêu cầu
      // Backend cần: { product: "id", variant: "id", quantity: 1, price: ... }
      List<Map<String, dynamic>> itemsForApi = widget.cartItems!.map((item) => {
        "product": item.productId, // Khớp với backend
        "variant": item.variantId, // Khớp với backend
        "quantity": item.quantity,
        "price": item.price,
        "name": item.name,
        "image": item.image
      }).toList();

      success = await _apiService.createGuestOrder(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        addressLine: _addressController.text,
        city: _cityController.text,
        cartItems: itemsForApi,
      );
    } else {
      // --- USER CHECKOUT ---
      success = await _apiService.createOrder(
        addressLine: _addressController.text,
        city: _cityController.text,
        phone: _phoneController.text,
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Thành công!"),
          content: Text(_isGuest 
            ? "Đơn hàng đã tạo. Tài khoản đã được tạo tự động, vui lòng kiểm tra email." 
            : "Đơn hàng của bạn đang được xử lý."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
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
        const SnackBar(content: Text("Đặt hàng thất bại. Kiểm tra lại thông tin."), backgroundColor: Colors.red),
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
              if (_isGuest)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.orange.shade100,
                  child: const Row(children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text("Bạn đang mua hàng với tư cách KHÁCH. Tài khoản sẽ được tạo tự động."))
                  ]),
                ),

              const Text("Thông tin liên hệ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Email & Tên (Guest phải nhập, User thì readonly hoặc cho sửa)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty || !v.contains('@') ? "Email không hợp lệ" : null,
                readOnly: !_isGuest, // User đã đăng nhập thì không sửa email
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Nhập họ tên" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Nhập số điện thoại" : null,
              ),

              const SizedBox(height: 20),
              const Text("Địa chỉ giao hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Số nhà, tên đường", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Nhập địa chỉ" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "Tỉnh / Thành phố", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Nhập thành phố" : null,
              ),

              const SizedBox(height: 20),
              const Text("Mã giảm giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(hintText: "Nhập mã (VD: SALE10)", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã áp dụng mã (Demo)")));
                      // Logic trừ tiền giả lập ở đây nếu muốn
                    },
                    child: const Text("Áp dụng"),
                  )
                ],
              ),
              const SizedBox(height: 30),
              Text("Phương thức thanh toán", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
              const ListTile(
                leading: Icon(Icons.money, color: Colors.green),
                title: Text("Thanh toán khi nhận hàng (COD)"),
                trailing: Icon(Icons.check_circle, color: Colors.blue),
              ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("ĐẶT HÀNG (${widget.totalPrice}đ)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}