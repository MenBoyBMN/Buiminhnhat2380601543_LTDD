import 'dart:convert';
import '../models/leave_model.dart';
import 'api_service.dart';

class LeaveService {
  /// Lấy danh sách đơn nghỉ phép của nhân viên hiện tại
  static Future<List<LeaveRequestModel>> getMyRequests() async {
    final response = await ApiService.get('/api/LeaveRequests/my-requests');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => LeaveRequestModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải đơn nghỉ phép của bạn');
    }
  }

  /// Tạo đơn nghỉ phép mới
  static Future<void> createRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final response = await ApiService.post('/api/LeaveRequests', {
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason.trim(),
    });

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Tạo đơn nghỉ phép thất bại');
    }
  }

  /// Sửa đơn nghỉ phép khi còn Pending
  static Future<void> updateRequest({
    required int id,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final response = await ApiService.put('/api/LeaveRequests/$id', {
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason.trim(),
    });

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Cập nhật đơn nghỉ phép thất bại');
    }
  }

  /// Xóa đơn nghỉ phép khi còn Pending
  static Future<void> deleteRequest(int id) async {
    final response = await ApiService.delete('/api/LeaveRequests/$id');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Xóa đơn nghỉ phép thất bại');
    }
  }

  /// Lấy toàn bộ đơn nghỉ phép (Manager / Admin)
  static Future<List<LeaveRequestModel>> getAllRequests({String? status}) async {
    String query = '';
    if (status != null && status.isNotEmpty) query = '?status=$status';

    final response = await ApiService.get('/api/LeaveRequests/all$query');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => LeaveRequestModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách đơn nghỉ phép');
    }
  }

  /// Phê duyệt hoặc Từ chối đơn nghỉ phép (Manager / Admin)
  static Future<void> reviewRequest({
    required int id,
    required String status, // 'Approved' hoặc 'Rejected'
    String? reviewNote,
  }) async {
    final response = await ApiService.post('/api/LeaveRequests/$id/review', {
      'status': status,
      if (reviewNote != null) 'reviewNote': reviewNote.trim(),
    });

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Xử lý đơn nghỉ phép thất bại');
    }
  }
}
