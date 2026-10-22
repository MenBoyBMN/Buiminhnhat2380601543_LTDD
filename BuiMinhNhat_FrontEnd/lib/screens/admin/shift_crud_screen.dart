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
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '08:00');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '17:00');
    final graceCtrl = TextEditingController(text: existing?.gracePeriodMinutes.toString() ?? '15');
    bool isActive = existing?.isActive ?? true;
    bool isSaving = false;
    String? dialogError;

    Future<void> pickTime(TextEditingController controller) async {
      final parts = controller.text.split(':');
      TimeOfDay initial = const TimeOfDay(hour: 8, minute: 0);
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
      );
      if (picked != null) {
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        controller.text = '$hh:$mm';
      }
    }

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
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existing == null ? 'Thêm Ca Làm Việc Mới' : 'Cập Nhật Ca Làm Việc',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      CustomTextField(
                        controller: nameCtrl,
                        label: 'Tên ca làm',
                        hint: 'VD: Ca Tối, Ca Tăng Ca, Ca Gãy...',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập tên ca làm việc!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: startCtrl,
                              label: 'Giờ vào (HH:mm)',
                              hint: '08:00',
                              prefixIcon: Icons.login,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.access_time, size: 20),
                                onPressed: () async {
                                  await pickTime(startCtrl);
                                  setSheetState(() {});
                                },
                              ),
                              onTap: () async {
                                await pickTime(startCtrl);
                                setSheetState(() {});
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Nhập giờ vào';
                                final regex = RegExp(r'^\d{1,2}:\d{2}$');
                                if (!regex.hasMatch(val.trim())) return 'HH:mm';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: endCtrl,
                              label: 'Giờ tan (HH:mm)',
                              hint: '17:00',
                              prefixIcon: Icons.logout,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.access_time, size: 20),
                                onPressed: () async {
                                  await pickTime(endCtrl);
                                  setSheetState(() {});
                                },
                              ),
                              onTap: () async {
                                await pickTime(endCtrl);
                                setSheetState(() {});
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Nhập giờ tan';
                                final regex = RegExp(r'^\d{1,2}:\d{2}$');
                                if (!regex.hasMatch(val.trim())) return 'HH:mm';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: graceCtrl,
                        label: 'Số phút cho phép trễ',
                        hint: '15',
                        prefixIcon: Icons.timer_outlined,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số phút trễ';
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) return 'Số phút phải là số nguyên ≥ 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kích hoạt ca làm này'),
                        subtitle: Text(
                          isActive ? 'Nhân viên có thể điểm danh theo ca này' : 'Ca làm này tạm ngưng hoạt động',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        value: isActive,
                        onChanged: (val) => setSheetState(() => isActive = val),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: existing == null ? 'Tạo Ca Làm' : 'Lưu Thay Đổi',
                        isLoading: isSaving,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setSheetState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          final shift = ShiftModel(
                            id: existing?.id ?? 0,
                            name: nameCtrl.text.trim(),
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            gracePeriodMinutes: int.tryParse(graceCtrl.text.trim()) ?? 15,
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
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(existing == null ? 'Đã thêm ca làm việc thành công!' : 'Đã cập nhật ca làm việc!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setSheetState(() {
                              isSaving = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                      ),
                    ],
                  ),
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
