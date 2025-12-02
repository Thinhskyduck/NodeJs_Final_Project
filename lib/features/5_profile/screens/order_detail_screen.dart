import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  // Cho phép truyền thẳng model nếu đã có, đỡ phải load lại
  final OrderModel? orderModel; 

  const OrderDetailScreen({super.key, required this.orderId, this.orderModel});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<OrderModel?> _orderFuture;

  @override
  void initState() {
    super.initState();
    if (widget.orderModel != null) {
      _orderFuture = Future.value(widget.orderModel);
    } else {
      _orderFuture = _apiService.getOrderDetail(widget.orderId);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipping': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết đơn hàng"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tải được thông tin đơn hàng"));
          }

          final order = snapshot.data!;

          // --- TÍNH TOÁN TIỀN GIẢM GIÁ TỪ ĐIỂM (LOYALTY) ---
          // Công thức: Giảm điểm = (Tiền hàng + Ship) - (Giảm Voucher) - (Tổng thực trả)
          // Lưu ý: Các biến itemsPrice, shippingPrice, discountAmount phải có trong OrderModel (như đã cập nhật ở bước trước)
          int expectedTotal = order.itemsPrice + order.shippingPrice - order.discountAmount;
          int loyaltyDiscount = expectedTotal - order.totalPrice;
          if (loyaltyDiscount < 0) loyaltyDiscount = 0; // Tránh sai số âm

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. THÔNG TIN CHUNG
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Đơn #${order.id.substring(0, 8).toUpperCase()}", 
                      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getStatusColor(order.status)),
                      ),
                      child: Text(
                        _translateStatus(order.status),
                        style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text("Ngày đặt: ${order.formattedDate}", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // 2. BẢNG THEO DÕI TRẠNG THÁI (TRACKING HISTORY)
                Text("Lịch sử trạng thái", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      // Header bảng
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text("Thời gian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(flex: 3, child: Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Nội dung bảng (Dùng statusHistory từ Model)
                      if (order.statusHistory.isNotEmpty)
                        ...order.statusHistory.map((history) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(history.formattedDate, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                Expanded(
                                  flex: 3, 
                                  child: Text(
                                    history.statusVietnamese, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500, 
                                      color: _getStatusColor(history.status),
                                      fontSize: 13
                                    )
                                  )
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      else
                        const Padding(padding: EdgeInsets.all(15), child: Text("Chưa có lịch sử trạng thái", style: TextStyle(fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),

                // 3. DANH SÁCH SẢN PHẨM
                Text("Sản phẩm", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = order.items[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.image,
                              width: 60, height: 60, fit: BoxFit.cover,
                              errorBuilder: (c,e,s) => const Icon(Icons.image, size: 60, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("${NumberFormat("#,##0₫", "vi_VN").format(item.price)} x ${item.quantity}", 
                                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(
                            NumberFormat("#,##0₫", "vi_VN").format(item.price * item.quantity),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),
                
                // 4. CHI TIẾT THANH TOÁN (PRICE BREAKDOWN)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow("Tổng tiền hàng", order.itemsPrice),
                      _buildPriceRow("Phí vận chuyển", order.shippingPrice),
                      
                      // Hiển thị Voucher
                      if (order.discountAmount > 0)
                        _buildPriceRow(
                          "Voucher giảm giá ${order.discountCode != null ? '(${order.discountCode})' : ''}", 
                          -order.discountAmount, 
                          color: Colors.green
                        ),
                      
                      // <--- SỬA LẠI ĐOẠN NÀY: Dùng trường trực tiếp từ Model ---
                      if (order.loyaltyDiscountAmount > 0)
                        _buildPriceRow(
                          "Điểm tích lũy (${order.loyaltyPointsUsed} điểm)", 
                          -order.loyaltyDiscountAmount, 
                          color: Colors.green
                        ),
                      // --------------------------------------------------------

                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Thành tiền", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            order.formattedTotal, 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 5. ĐỊA CHỈ NHẬN HÀNG
                Text("Địa chỉ nhận hàng", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.address, 
                          style: const TextStyle(color: Colors.black87, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget con để hiển thị dòng giá tiền
  Widget _buildPriceRow(String label, int value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            NumberFormat("#,##0₫", "vi_VN").format(value), 
            style: TextStyle(fontWeight: FontWeight.w600, color: color)
          ),
        ],
      ),
    );
  }
  
  // Các hàm helper _getStatusColor và _translateStatus giữ nguyên như cũ
  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'shipping': return 'Đang giao';
      case 'delivered': return 'Đã giao';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}