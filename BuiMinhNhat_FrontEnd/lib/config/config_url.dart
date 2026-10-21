import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigUrl {
  static const String _prefKey = 'custom_api_base_url';
  static String? _cachedBaseUrl;

  /// Khởi tạo và load URL từ SharedPreferences hoặc .env
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_prefKey);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _cachedBaseUrl = customUrl.trim();
    } else {
      _cachedBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
    }
  }

  /// URL API hiện tại
  static String get baseUrl {
    return _cachedBaseUrl ?? 'http://localhost:5000';
  }

  /// Cập nhật URL mới (Lưu vào SharedPreferences)
  static Future<void> setBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedBaseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, cleanUrl);
  }

  /// Reset về mặc định theo nền tảng
  static Future<void> resetToDefault({bool isEmulator = false}) async {
    final defaultUrl = isEmulator ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
    await setBaseUrl(defaultUrl);
  }

  /// Format đường dẫn ảnh selfie minh chứng đầy đủ
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    final cleanPath = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseUrl$cleanPath';
  }
}
