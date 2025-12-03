import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? orderModel;

  const OrderDetailScreen({super.key, required this.orderId, this.orderModel});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<OrderModel?> _orderFuture;

  // --- Constants Style ---
  static const Color primaryColor = Color(0xFFD70018); // Đỏ thương hiệu
  static const Color bgGrey = Color(0xFFF2F4F7); // Xám xanh hiện đại hơn
  static const Color textBlack = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);
  
  // Style chung cho các Card
  final BoxDecoration _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    if (widget.orderModel != null) {
      _orderFuture = Future.value(widget.orderModel);
    } else {
      _orderFuture = _apiService.getOrderDetail(widget.orderId);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Text(
          "Chi tiết đơn hàng", 
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 18, color: textBlack)
        ),
        backgroundColor: bgGrey, // Để trùng màu nền tạo cảm giác thoáng
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: textBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("Lỗi tải đơn hàng", style: GoogleFonts.manrope(color: textGrey)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                       _orderFuture = _apiService.getOrderDetail(widget.orderId);
                    }),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text("Thử lại", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            );
          }

          final order = snapshot.data!;

          // Sử dụng ListView với padding ngang để tránh bị bè ra 2 bên
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
            child: Column(
              children: [
                // 1. Header (Mã đơn + Trạng thái)
                _buildHeaderCard(order),
                const SizedBox(height: 16),

                // 2. Timeline
                _buildTrackingCard(order.statusHistory),
                const SizedBox(height: 16),

                // 3. Thông tin người nhận
                _buildInfoCard(
                  title: "Địa chỉ nhận hàng",
                  icon: Icons.location_on,
                  iconColor: Colors.orange,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Giả lập tên người nhận (nếu model có thì thay vào)
                      Text("Người nhận", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        order.address,
                        style: GoogleFonts.manrope(fontSize: 14, color: textGrey, height: 1.5),
                      ),
                    ],
                  )
                ),
                const SizedBox(height: 16),

                // 4. Danh sách sản phẩm
                _buildProductListCard(order.items),
                const SizedBox(height: 16),

                // 5. Thanh toán
                _buildPaymentCard(order),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  // 1. Header Card: Mã đơn & Trạng thái tổng quan
  Widget _buildHeaderCard(OrderModel order) {
    Color statusColor = _getStatusColor(order.status);
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MÃ ĐƠN HÀNG", style: GoogleFonts.manrope(fontSize: 11, color: textGrey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("#${order.id.substring(0, 8).toUpperCase()}", 
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: textBlack)
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  _translateStatus(order.status),
                  style: GoogleFonts.manrope(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: textGrey),
              const SizedBox(width: 6),
              Text("Ngày đặt: ${order.formattedDate}", style: GoogleFonts.manrope(fontSize: 13, color: textGrey)),
            ],
          )
        ],
      ),
    );
  }

  // 2. Tracking Timeline Compact
  Widget _buildTrackingCard(List<OrderStatusHistory> historyList) {
    if (historyList.isEmpty) return const SizedBox.shrink();
    
    // Lấy trạng thái mới nhất
    final latest = historyList.first; 

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle("Tiến độ đơn hàng", Icons.local_shipping_outlined, Colors.blue),
          const SizedBox(height: 16),
          // Chỉ hiển thị 1-2 bước mới nhất để gọn, hoặc hiển thị full list nhưng style đẹp hơn
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];
              final isFirst = index == 0;
              final isLast = index == historyList.length - 1;
              
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột Line
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: isFirst ? _getStatusColor(item.status) : Colors.grey[300],
                              shape: BoxShape.circle,
                              border: isFirst ? Border.all(color: Colors.white, width: 2) : null,
                              boxShadow: isFirst ? [BoxShadow(color: _getStatusColor(item.status).withOpacity(0.4), blurRadius: 4)] : null
                            ),
                          ),
                          if (!isLast)
                             Expanded(child: Container(width: 1.5, color: Colors.grey[200])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nội dung
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.statusVietnamese,
                              style: GoogleFonts.manrope(
                                fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                                color: isFirst ? textBlack : textGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(item.formattedDate, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Info Card Generic
  Widget _buildInfoCard({required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(title, icon, iconColor),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: content,
          ),
        ],
      ),
    );
  }

  // 4. Product List
  Widget _buildProductListCard(List<OrderItem> items) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildCardTitle("Sản phẩm (${items.length})", Icons.shopping_bag_outlined, primaryColor),
           const SizedBox(height: 16),
           ListView.separated(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemCount: items.length,
             separatorBuilder: (_, __) => const Padding(
               padding: EdgeInsets.symmetric(vertical: 12),
               child: Divider(height: 1, color: Color(0xFFF0F0F0)),
             ),
             itemBuilder: (context, index) => _buildProductItem(items[index]),
           )
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(item.image, fit: BoxFit.cover,
              errorBuilder: (_,__,___) => const Icon(Icons.image, size: 30, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: textBlack),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("x${item.quantity}", style: GoogleFonts.manrope(color: textGrey, fontSize: 13)),
                  Text(
                    NumberFormat("#,##0₫", "vi_VN").format(item.price),
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: textBlack),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Payment Details
  Widget _buildPaymentCard(OrderModel order) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCardTitle("Chi tiết thanh toán", Icons.receipt_long_rounded, Colors.teal),
          const SizedBox(height: 16),
          
          // Phương thức thanh toán
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgGrey,
              borderRadius: BorderRadius.circular(8)
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, size: 18, color: textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.paymentMethod?.toUpperCase() ?? "TIỀN MẶT (COD)",
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: textBlack),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryRow("Tổng tiền hàng", order.itemsPrice),
          _buildSummaryRow("Phí vận chuyển", order.shippingPrice),
          
          if (order.discountAmount > 0)
            _buildSummaryRow("Voucher giảm giá", -order.discountAmount, isNegative: true),
          
          if (order.loyaltyDiscountAmount > 0)
            _buildSummaryRow("Điểm tích lũy", -order.loyaltyDiscountAmount, isNegative: true),

          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEEEEEE))),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Thành tiền", style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: textBlack)),
              Text(
                order.formattedTotal, 
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor)
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Common Mini Widgets ---
  
  // Title with Icon Circle
  Widget _buildCardTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: textBlack)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, int value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(color: textGrey, fontSize: 14)),
          Text(
            "${isNegative ? '-' : ''}${NumberFormat("#,##0₫", "vi_VN").format(value)}", 
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w500, 
              color: isNegative ? Colors.green : textBlack,
              fontSize: 14
            )
          ),
        ],
      ),
    );
  }
}