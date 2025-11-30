import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // Import socket
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/api_service.dart';

class ReviewSection extends StatefulWidget {
  final String productId;
  final List<Review> reviews;
  final VoidCallback onReviewSubmitted; // Hàm callback để cha reload data

  const ReviewSection({
    super.key,
    required this.productId,
    required this.reviews,
    required this.onReviewSubmitted,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController(); // Cho khách nhập tên
  
  double _userRating = 5.0;
  bool _isSubmitting = false;
  bool _isLoggedIn = false;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _initSocket();
  }

  // 1. Kiểm tra đăng nhập
  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.containsKey(AppConstants.tokenKey);
    });
  }

  // 2. Khởi tạo Socket để nghe Realtime
  void _initSocket() {
    // Lưu ý: URL phải bỏ /api ở cuối nếu AppConstants.baseUrl có /api
    // Ví dụ baseUrl: .../api -> socketUrl: ...
    String socketUrl = '${AppConstants.baseUrl.replaceAll('/api', '')}'; 
    
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Socket connected for Reviews');
    });

    _socket.on('new_review', (data) {
      if (mounted) {
        if (data['productId'] == widget.productId) {
          print("Có review mới, reload data!");
          widget.onReviewSubmitted(); // Gọi cha reload lại API
        }
      }
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    _commentController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(_isLoggedIn ? "Đánh giá sản phẩm" : "Bình luận (Khách)"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chỉ hiện sao nếu đã đăng nhập
                    if (_isLoggedIn) ...[
                      const Text("Chọn số sao:"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setStateDialog(() => _userRating = index + 1.0);
                            },
                            icon: Icon(
                              index < _userRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                    ] else ...[
                       const Text("Bạn đang bình luận với tư cách Khách (Không thể đánh giá sao).", 
                         style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                       const SizedBox(height: 10),
                       TextField(
                        controller: _guestNameController,
                        decoration: const InputDecoration(
                          labelText: "Tên của bạn",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Nhập nội dung...",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy"),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (_commentController.text.trim().isEmpty) {
                      return;
                    }
                    setStateDialog(() => _isSubmitting = true);
                    
                    // Nếu là khách, rating là null
                    // Nếu là khách, lấy tên từ ô nhập, nếu trống thì mặc định 'Khách'
                    String guestName = _isLoggedIn ? '' : (_guestNameController.text.isEmpty ? 'Khách' : _guestNameController.text);

                    final result = await _apiService.createProductReview(
                      widget.productId,
                      _isLoggedIn ? _userRating : null, // Truyền null nếu là khách
                      _commentController.text.trim(),
                      guestName: guestName
                    );
                    
                    if(mounted) {
                        setStateDialog(() => _isSubmitting = false);
                        Navigator.pop(context);

                        if (result['success']) {
                          _commentController.clear();
                          _guestNameController.clear();
                          // Không cần gọi widget.onReviewSubmitted() ở đây nữa 
                          // vì Socket sẽ tự nghe và gọi nó.
                          // Tuy nhiên để chắc chắn UX nhanh, ta cứ gọi:
                          widget.onReviewSubmitted(); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gửi thành công!")));
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
                        }
                    }
                  },
                  child: _isSubmitting ? const CircularProgressIndicator() : const Text("Gửi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Đánh giá & Bình luận", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showAddReviewDialog,
              icon: const Icon(Icons.rate_review),
              label: Text(_isLoggedIn ? "Viết đánh giá" : "Viết bình luận"),
            ),
          ],
        ),
        const Divider(),
        if (widget.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("Chưa có đánh giá nào.", style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.reviews.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final review = widget.reviews[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'G'),
                ),
                title: Row(
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(review.formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chỉ hiện sao nếu rating > 0
                    if (review.rating > 0)
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                    const SizedBox(height: 4),
                    Text(review.comment),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}