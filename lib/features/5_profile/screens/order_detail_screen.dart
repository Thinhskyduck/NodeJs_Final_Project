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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER: Mã đơn & Trạng thái
                Text("Đơn hàng #${order.id.substring(0, 8).toUpperCase()}", 
                  style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Ngày đặt: ${order.formattedDate}", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // 2. BẢNG TRẠNG THÁI (TRACKING TABLE) - YÊU CẦU QUAN TRỌNG
                Text("Theo dõi trạng thái", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header Table
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 2, child: Text("Thời gian", style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text("Trạng thái", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Body Table
                      ...order.statusHistory.map((history) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(history.formattedDate, style: const TextStyle(fontSize: 13))),
                              Expanded(
                                flex: 3, 
                                child: Text(
                                  history.statusVietnamese, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600, 
                                    color: _getStatusColor(history.status)
                                  )
                                )
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (order.statusHistory.isEmpty)
                         const Padding(padding: EdgeInsets.all(12), child: Text("Chưa có lịch sử trạng thái"))
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // 3. DANH SÁCH SẢN PHẨM
                Text("Sản phẩm", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...order.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.network(
                          item.image,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => const Icon(Icons.image, size: 60, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text("${NumberFormat("#,##0₫", "vi_VN").format(item.price)} x ${item.quantity}", 
                                style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          NumberFormat("#,##0₫", "vi_VN").format(item.price * item.quantity),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 20),
                const Divider(),
                
                // 4. ĐỊA CHỈ & TỔNG TIỀN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng tiền:", style: TextStyle(fontSize: 16)),
                    Text(order.formattedTotal, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 10),
                Text("Địa chỉ giao hàng:", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                Text(order.address, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          );
        },
      ),
    );
  }
}