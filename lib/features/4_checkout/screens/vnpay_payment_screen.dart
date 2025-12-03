import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VnPayPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String redirectUrl; // URL frontend success mà backend redirect về (VD: /order-success)

  const VnPayPaymentScreen({
    super.key, 
    required this.paymentUrl,
    this.redirectUrl = 'order-success', // Keyword để bắt link thành công
  });

  @override
  State<VnPayPaymentScreen> createState() => _VnPayPaymentScreenState();
}

class _VnPayPaymentScreenState extends State<VnPayPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Cấu hình WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Backend của bạn redirect về: FRONTEND_URL/order-success?orderId=...
            // Chúng ta sẽ bắt từ khóa 'order-success' hoặc 'order-failed'
            
            if (request.url.contains('order-success')) {
              // Thanh toán thành công
              Navigator.pop(context, true); // Trả về true
              return NavigationDecision.prevent; // Chặn redirect tiếp
            }
            
            if (request.url.contains('order-failed')) {
              // Thanh toán thất bại
              Navigator.pop(context, false); // Trả về false
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán VNPAY"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Người dùng chủ động hủy
            Navigator.pop(context, false);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}