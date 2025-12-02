class AppConstants {
  // Thay URL Ngrok mới nhất của bạn vào đây (nhớ bỏ dấu / ở cuối)
  static const String baseUrl = 'http://localhost:5000/api';
  
  static const String tokenKey = 'USER_TOKEN';
  static const String userIdKey = 'USER_ID';
  static const String userNameKey = 'USER_NAME';
  static const String userEmailKey = 'USER_EMAIL';

  // Hàm xử lý ảnh thông minh (Hỗ trợ cả Asset local và Ảnh từ Server)
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return 'assets/images/placeholder.png'; 
    }
    
    // 1. Nếu là đường dẫn Local Asset (như bạn đã lưu trong DB)
    if (relativePath.startsWith('assets/')) {
      return relativePath;
    }

    // 2. Nếu là URL mạng (http...)
    if (relativePath.startsWith('http')) {
      return relativePath;
    }
    
    // 3. Nếu là đường dẫn từ Server Backend
    String path = relativePath.replaceAll('\\', '/');
    if (!path.startsWith('/')) path = '/$path';
    
    // Lấy domain gốc từ baseUrl (bỏ /api)
    String serverRoot = baseUrl.replaceAll('/api', '');
    return '$serverRoot$path';
  }
}