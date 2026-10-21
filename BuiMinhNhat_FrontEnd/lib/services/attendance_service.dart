import 'dart:convert';
import 'dart:io';
import '../models/attendance_model.dart';
import 'api_service.dart';

class AttendanceService {
  /// 5. Chấm công 3-trong-1 (GPS + QR + Chụp ảnh selfie + Mood)
  static Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    String? qrToken,
    String? mood,
    int? shiftId,
    String? note,
    File? photoFile,
  }) async {
    final fields = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    if (qrToken != null && qrToken.isNotEmpty) fields['qrToken'] = qrToken;
    if (mood != null && mood.isNotEmpty) fields['mood'] = mood;
    if (shiftId != null) fields['shiftId'] = shiftId.toString();
    if (note != null && note.isNotEmpty) fields['note'] = note;

    final streamedResponse = await ApiService.postMultipart(
      endpoint: '/api/Attendance/check-in',
      fields: fields,
      file: photoFile,
      fileParamName: 'photo',
    );

    final response = await streamedResponse.stream.bytesToString();
    final data = jsonDecode(response);

    if (streamedResponse.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Check-in thất bại');
    }
  }

  /// Check-out cuối ca làm
  static Future<Map<String, dynamic>> checkOut({int? recordId, String? note}) async {
    final payload = <String, dynamic>{};
    if (recordId != null) payload['attendanceRecordId'] = recordId;
    if (note != null) payload['note'] = note;
    final response = await ApiService.post('/api/Attendance/check-out', payload);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Check-out thất bại');
    }
  }

  /// Lấy lịch sử chấm công của bản thân
  static Future<List<AttendanceRecordModel>> getMyHistory() async {
    final response = await ApiService.get('/api/Attendance/my-history');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => AttendanceRecordModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải lịch sử chấm công');
    }
  }

  /// Lấy toàn bộ bản ghi chấm công (Admin/Manager)
  static Future<List<AttendanceRecordModel>> getAllRecords({DateTime? date, String? status}) async {
    String query = '';
    final params = <String>[];
    if (date != null) params.add('date=${date.toIso8601String().split('T')[0]}');
    if (status != null && status.isNotEmpty) params.add('status=$status');
    if (params.isNotEmpty) query = '?${params.join('&')}';

    final response = await ApiService.get('/api/Attendance/all$query');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => AttendanceRecordModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách chấm công');
    }
  }

  /// 6. Bảng xếp hạng chuyên cần (Leaderboard) & Gamification
  static Future<List<LeaderboardItemModel>> getLeaderboard() async {
    final response = await ApiService.get('/api/Attendance/leaderboard');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => LeaderboardItemModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải bảng xếp hạng');
    }
  }

  /// Sinh mã Dynamic Anti-Fraud QR Code mới
  static Future<QrSessionModel> generateDynamicQr({int? shiftId}) async {
    final endpoint = shiftId != null ? '/api/Attendance/generate-qr?shiftId=$shiftId' : '/api/Attendance/generate-qr';
    final response = await ApiService.post(endpoint, null);
    if (response.statusCode == 200) {
      return QrSessionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tạo mã QR động');
    }
  }

  /// Lấy mã Dynamic QR đang hoạt động
  static Future<QrSessionModel> getActiveQr() async {
    final response = await ApiService.get('/api/Attendance/active-qr');
    if (response.statusCode == 200) {
      return QrSessionModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể lấy mã QR đang hoạt động');
    }
  }

  /// Xóa bản ghi chấm công (Admin)
  static Future<void> deleteRecord(int id) async {
    final response = await ApiService.delete('/api/Attendance/$id');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Xóa bản ghi thất bại');
    }
  }
}
