import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'current_user_profile';

  /// Bước 1: Gửi UserName + Password để tạo mã OTP
  static Future<LoginStep1Result> loginStep1(String userName, String password) async {
    final response = await ApiService.post('/api/Authenticate/login', {
      'userName': userName.trim(),
      'password': password,
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return LoginStep1Result.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Đăng nhập không thành công');
    }
  }

  /// Bước 2: Xác thực mã OTP 6 số để nhận JWT Token
  static Future<UserModel> verifyOtp(String userName, String otpCode) async {
    final response = await ApiService.post('/api/Authenticate/verify-otp', {
      'userName': userName.trim(),
      'otpCode': otpCode.trim(),
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final token = data['token'] as String;
      await ApiService.saveToken(token);

      // Giải mã JWT để kiểm tra tính hợp lệ
      if (JwtDecoder.isExpired(token)) {
        throw Exception('Token đã hết hạn!');
      }

      final user = UserModel.fromJson(data['user']);
      await saveStoredUser(user);
      return user;
    } else {
      throw Exception(data['message'] ?? 'Xác thực OTP thất bại');
    }
  }

  /// Đăng ký tài khoản mới qua Email
  static Future<String> register({
    required String userName,
    required String email,
    required String password,
    required String fullName,
    String? initials,
    int? departmentId,
    String role = 'Employee',
  }) async {
    final response = await ApiService.post('/api/Authenticate/register', {
      'userName': userName.trim(),
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
      'initials': initials?.trim(),
      'departmentId': departmentId,
      'role': role,
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Đăng ký thành công!';
    } else {
      throw Exception(data['message'] ?? 'Đăng ký thất bại');
    }
  }

  /// Lưu thông tin người dùng vào SharedPreferences
  static Future<void> saveStoredUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Lấy thông tin người dùng đã lưu
  static Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final token = await ApiService.getToken();

    if (userJson != null && token != null) {
      try {
        if (!JwtDecoder.isExpired(token)) {
          return UserModel.fromJson(jsonDecode(userJson));
        }
      } catch (_) {}
    }
    return null;
  }

  /// Lấy thông tin cá nhân mới nhất từ server và đồng bộ vào SharedPreferences
  static Future<UserModel?> fetchProfile() async {
    try {
      final response = await ApiService.get('/api/Authenticate/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data);
        await saveStoredUser(user);
        return user;
      }
    } catch (_) {}
    return await getStoredUser();
  }

  /// Cập nhật nhanh streakCount và totalPoints vào cached user
  static Future<void> updateStreakAndPoints(int streakCount, int totalPoints) async {
    final current = await getStoredUser();
    if (current != null) {
      final updated = UserModel(
        id: current.id,
        userName: current.userName,
        email: current.email,
        fullName: current.fullName,
        initials: current.initials,
        role: current.role,
        departmentId: current.departmentId,
        departmentName: current.departmentName,
        streakCount: streakCount,
        totalPoints: totalPoints,
      );
      await saveStoredUser(updated);
    }
  }

  /// Đăng xuất khỏi hệ thống
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await ApiService.removeToken();
  }
}
