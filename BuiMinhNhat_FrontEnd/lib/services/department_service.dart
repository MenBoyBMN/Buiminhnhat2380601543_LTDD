import 'dart:convert';
import '../models/department_model.dart';
import 'api_service.dart';

class DepartmentService {
  static Future<List<DepartmentModel>> getAll() async {
    final response = await ApiService.get('/api/Departments');
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => DepartmentModel.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách phòng ban');
    }
  }

  static Future<void> create(DepartmentModel dept) async {
    final response = await ApiService.post('/api/Departments', dept.toJson());
    if (response.statusCode != 201 && response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Thêm phòng ban thất bại');
    }
  }

  static Future<void> update(int id, DepartmentModel dept) async {
    final response = await ApiService.put('/api/Departments/$id', dept.toJson());
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Cập nhật phòng ban thất bại');
    }
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete('/api/Departments/$id');
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Xóa phòng ban thất bại');
    }
  }
}
