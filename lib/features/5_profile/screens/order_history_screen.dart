import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _apiService.getMyOrders();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử đơn hàng"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bạn chưa có đơn hàng nào"));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Mã đơn & Trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Đơn #${order.id.substring(0, 6).toUpperCase()}", // Rút gọn ID cho đẹp
                            style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
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
                          )
                        ],
                      ),
                      const Divider(),
                      
                      // Body: Ngày & Địa chỉ
                      Text("Ngày đặt: ${order.formattedDate}", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text("Giao đến: ${order.address}", style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 8),

                      // List sản phẩm (Hiển thị ngắn gọn)
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text("${item.quantity}x ", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),

                      const Divider(),
                      
                      // Footer: Tổng tiền
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("Tổng tiền: ", style: TextStyle(fontSize: 14)),
                          Text(
                            order.formattedTotal,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}