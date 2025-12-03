import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cross_platform_mobile_app_development/features/5_profile/screens/order_detail_screen.dart'; // Đảm bảo đường dẫn đúng
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<OrderModel>> _ordersFuture;
  late TabController _tabController;

  // Style Constants (Đồng bộ với OrderDetail)
  static const Color primaryColor = Color(0xFFD70018);
  static const Color bgGrey = Color(0xFFF2F4F7);
  static const Color textBlack = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  // Danh sách Tab trạng thái
  final List<String> _tabs = ["Tất cả", "Chờ xác nhận", "Đang giao", "Đã giao", "Đã hủy"];

  @override
  void initState() {
    super.initState();
    _ordersFuture = _apiService.getMyOrders();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Helpers ---
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

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'shipping': return 'Đang vận chuyển';
      case 'delivered': return 'Giao thành công';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  // Hàm lọc danh sách đơn hàng theo Tab
  List<OrderModel> _filterOrders(List<OrderModel> allOrders, int tabIndex) {
    if (tabIndex == 0) return allOrders; // Tất cả
    String targetStatus = '';
    switch (tabIndex) {
      case 1: targetStatus = 'pending'; break; // Có thể gộp 'confirmed' vào đây tùy logic BE
      case 2: targetStatus = 'shipping'; break;
      case 3: targetStatus = 'delivered'; break;
      case 4: targetStatus = 'cancelled'; break;
    }
    // Lọc theo trạng thái (chứa từ khóa vì status BE có thể khác một chút)
    return allOrders.where((o) => 
      o.status.toLowerCase().contains(targetStatus) || 
      (tabIndex == 1 && o.status.toLowerCase() == 'confirmed') // Ví dụ gộp Pending và Confirmed vào tab 2
    ).toList();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _apiService.getMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Text(
          "Lịch sử đơn hàng", 
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18, color: textBlack)
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textBlack),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Cho phép cuộn ngang nếu nhiều tab
          labelColor: primaryColor,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryColor,
          labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          onTap: (index) => setState(() {}), // Rebuild để lọc list
        ),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allOrders = snapshot.data!;
          // Đảo ngược để đơn mới nhất lên đầu (nếu API chưa sort)
          final sortedOrders = allOrders.reversed.toList(); 
          final filteredOrders = _filterOrders(sortedOrders, _tabController.index);

          if (filteredOrders.isEmpty) {
            return _buildEmptyState(message: "Không có đơn hàng ở mục này");
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            color: primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: filteredOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildOrderCard(filteredOrders[index]);
              },
            ),
          );
        },
      ),
    );
  }

  // --- Widget Card Item ---
  Widget _buildOrderCard(OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final otherItemsCount = order.items.length - 1;
    final statusColor = _getStatusColor(order.status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id, orderModel: order)
          )
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Header Card: Shop name/Date & Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 18, color: textGrey),
                      const SizedBox(width: 6),
                      Text(
                        order.formattedDate.split(" ")[0], // Chỉ lấy ngày
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: textBlack),
                      ),
                    ],
                  ),
                  Text(
                    _translateStatus(order.status).toUpperCase(),
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // 2. Body Card: Product Preview
            if (firstItem != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh sản phẩm
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          firstItem.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Thông tin text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstItem.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: textBlack),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Số lượng: x${firstItem.quantity}", 
                                style: GoogleFonts.manrope(fontSize: 13, color: textGrey)
                              ),
                              if (otherItemsCount > 0)
                                Text(
                                  "+ $otherItemsCount sản phẩm khác",
                                  style: GoogleFonts.manrope(fontSize: 12, color: textGrey, fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                           // Hiển thị giá 1 item hoặc tổng tùy ý (ở đây để giá 1 item cho gọn)
                          Text(
                            NumberFormat("#,##0₫", "vi_VN").format(firstItem.price),
                            style: GoogleFonts.manrope(fontSize: 14, color: textGrey, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // 3. Footer Card: Total Price & Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Thành tiền:", style: GoogleFonts.manrope(fontSize: 12, color: textGrey)),
                      Text(
                        order.formattedTotal,
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action Button (Ví dụ)
                  _buildActionButton(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nút hành động dựa trên trạng thái (Logic giả định để UI đẹp)
  Widget _buildActionButton(OrderModel order) {
    String text = "Xem chi tiết";
    Color bgColor = Colors.white;
    Color textColor = textGrey;
    Color borderColor = Colors.grey[300]!;

    if (order.status.toLowerCase() == 'delivered') {
      text = "Mua lại";
      bgColor = primaryColor;
      textColor = Colors.white;
      borderColor = primaryColor;
    } else if (order.status.toLowerCase() == 'pending') {
      text = "Thanh toán"; // Giả định
      borderColor = primaryColor;
      textColor = primaryColor;
    }

    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id, orderModel: order)
          )
        );
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 13, color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEmptyState({String message = "Bạn chưa có đơn hàng nào"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle
            ),
            child: Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.manrope(color: textGrey, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text("Lỗi kết nối", style: GoogleFonts.manrope(color: textGrey)),
          TextButton(
            onPressed: _refreshOrders,
            child: const Text("Thử lại", style: TextStyle(color: primaryColor)),
          )
        ],
      ),
    );
  }
}