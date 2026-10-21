import 'package:flutter/material.dart';
import '../../models/department_model.dart';
import '../../services/department_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DepartmentCrudScreen extends StatefulWidget {
  const DepartmentCrudScreen({super.key});

  @override
  State<DepartmentCrudScreen> createState() => _DepartmentCrudScreenState();
}

class _DepartmentCrudScreenState extends State<DepartmentCrudScreen> {
  List<DepartmentModel> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final list = await DepartmentService.getAll();
      if (mounted) {
        setState(() {
          _departments = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog({DepartmentModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final addrCtrl = TextEditingController(text: existing?.officeAddress ?? '280 An Dương Vương, P4, Q5, TP.HCM');
    final latCtrl = TextEditingController(text: existing?.latitude.toString() ?? '10.759917');
    final lngCtrl = TextEditingController(text: existing?.longitude.toString() ?? '106.682258');
    final radiusCtrl = TextEditingController(text: existing?.radiusMeters.toString() ?? '300.0');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Thêm Phòng Ban Mới' : 'Cập Nhật Phòng Ban',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(controller: nameCtrl, label: 'Tên phòng ban'),
                    const SizedBox(height: 12),
                    CustomTextField(controller: descCtrl, label: 'Mô tả nhiệm vụ'),
                    const SizedBox(height: 12),
                    CustomTextField(controller: addrCtrl, label: 'Địa chỉ văn phòng'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(controller: latCtrl, label: 'Vĩ độ (Lat)', keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: CustomTextField(controller: lngCtrl, label: 'Kinh độ (Lng)', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(controller: radiusCtrl, label: 'Bán kính Geofence (mét)', keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: existing == null ? 'Tạo Phòng Ban' : 'Lưu Thay Đổi',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        setSheetState(() => isSaving = true);

                        final dept = DepartmentModel(
                          id: existing?.id ?? 0,
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          officeAddress: addrCtrl.text.trim(),
                          latitude: double.tryParse(latCtrl.text) ?? 10.759917,
                          longitude: double.tryParse(lngCtrl.text) ?? 106.682258,
                          radiusMeters: double.tryParse(radiusCtrl.text) ?? 300.0,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        try {
                          if (existing == null) {
                            await DepartmentService.create(dept);
                          } else {
                            await DepartmentService.update(existing.id, dept);
                          }
                          nav.pop();
                          _loadDepartments();
                        } catch (e) {
                          setSheetState(() => isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDepartment(DepartmentModel dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa phòng ban "${dept.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DepartmentService.delete(dept.id);
        _loadDepartments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Phòng Ban'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDepartments,
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                itemCount: _departments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final d = _departments[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business, color: Colors.indigo, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${d.userCount} nhân sự',
                                  style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (d.description != null && d.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(d.description!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  d.officeAddress ?? 'Chưa cấu hình địa chỉ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GPS: (${d.latitude}, ${d.longitude}) - Bán kính cho phép: ${d.radiusMeters}m',
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Chỉnh sửa'),
                                onPressed: () => _showAddEditDialog(existing: d),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                onPressed: () => _deleteDepartment(d),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
