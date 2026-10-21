import 'package:flutter/material.dart';
import '../../models/shift_model.dart';
import '../../services/shift_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ShiftCrudScreen extends StatefulWidget {
  const ShiftCrudScreen({super.key});

  @override
  State<ShiftCrudScreen> createState() => _ShiftCrudScreenState();
}

class _ShiftCrudScreenState extends State<ShiftCrudScreen> {
  List<ShiftModel> _shifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    setState(() => _isLoading = true);
    try {
      final list = await ShiftService.getAll();
      if (mounted) {
        setState(() {
          _shifts = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog({ShiftModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '08:00');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '17:00');
    final graceCtrl = TextEditingController(text: existing?.gracePeriodMinutes.toString() ?? '15');
    bool isActive = existing?.isActive ?? true;
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
                      existing == null ? 'Thêm Ca Làm Việc Mới' : 'Cập Nhật Ca Làm Việc',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(controller: nameCtrl, label: 'Tên ca làm (VD: Ca Sáng)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: CustomTextField(controller: startCtrl, label: 'Giờ vào (HH:mm)', hint: '08:00')),
                        const SizedBox(width: 8),
                        Expanded(child: CustomTextField(controller: endCtrl, label: 'Giờ tan (HH:mm)', hint: '17:00')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: graceCtrl,
                      label: 'Số phút cho phép trễ',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Kích hoạt ca làm này'),
                      value: isActive,
                      onChanged: (val) => setSheetState(() => isActive = val),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: existing == null ? 'Tạo Ca Làm' : 'Lưu Thay Đổi',
                      isLoading: isSaving,
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        setSheetState(() => isSaving = true);

                        final shift = ShiftModel(
                          id: existing?.id ?? 0,
                          name: nameCtrl.text.trim(),
                          startTime: startCtrl.text.trim(),
                          endTime: endCtrl.text.trim(),
                          gracePeriodMinutes: int.tryParse(graceCtrl.text) ?? 15,
                          isActive: isActive,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        try {
                          if (existing == null) {
                            await ShiftService.create(shift);
                          } else {
                            await ShiftService.update(existing.id, shift);
                          }
                          nav.pop();
                          _loadShifts();
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

  Future<void> _deleteShift(ShiftModel shift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa ca làm "${shift.name}"?'),
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
        await ShiftService.delete(shift.id);
        _loadShifts();
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
        label: const Text('Thêm Ca Làm'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShifts,
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                itemCount: _shifts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final s = _shifts[index];
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
                              const Icon(Icons.schedule, color: Colors.indigo, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: s.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s.isActive ? 'Đang hoạt động' : 'Tạm dừng',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: s.isActive ? Colors.green.shade800 : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Khung giờ: ${s.startTime} → ${s.endTime} (Cho phép trễ tối đa: ${s.gracePeriodMinutes} phút)',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Chỉnh sửa'),
                                onPressed: () => _showAddEditDialog(existing: s),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                onPressed: () => _deleteShift(s),
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
