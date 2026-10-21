import 'dart:convert';
import '../models/shift_model.dart';
import 'api_service.dart';

class ShiftService {
  static Future<List<ShiftModel>> getAll() async {
    final response = await ApiService.get('/api/Shifts');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => ShiftModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách ca làm việc');
    }
  }

  static Future<void> create(ShiftModel shift) async {
    final response = await ApiService.post('/api/Shifts', shift.toJson());
    if (response.statusCode != 201 && response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Thêm ca làm việc thất bại');
    }
  }

  static Future<void> update(int id, ShiftModel shift) async {
    final response = await ApiService.put('/api/Shifts/$id', shift.toJson());
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Cập nhật ca làm việc thất bại');
    }
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete('/api/Shifts/$id');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Xóa ca làm việc thất bại');
    }
  }
}
