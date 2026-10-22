import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  List<LeaveRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final list = await LeaveService.getMyRequests();
      if (mounted) {
        setState(() {
          _requests = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateEditDialog({LeaveRequestModel? existing}) {
    final reasonController = TextEditingController(text: existing?.reason ?? '');
    String leaveType = existing?.leaveType ?? 'Annual';
    DateTime startDate = existing?.startDate ?? DateTime.now().add(const Duration(days: 1));
    DateTime endDate = existing?.endDate ?? DateTime.now().add(const Duration(days: 2));
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final dateFormat = DateFormat('dd/MM/yyyy');
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Tạo Đơn Xin Nghỉ Phép' : 'Chỉnh Sửa Đơn Nghỉ Phép',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: leaveType,
                    decoration: const InputDecoration(
                      labelText: 'Loại nghỉ phép',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Annual', child: Text('Nghỉ phép năm', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Sick', child: Text('Nghỉ ốm đau', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Unpaid', child: Text('Nghỉ không lương', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Personal', child: Text('Việc riêng cá nhân', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setSheetState(() => leaveType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text('Từ: ${dateFormat.format(startDate)}'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) {
                              setSheetState(() {
                                startDate = d;
                                if (endDate.isBefore(startDate)) endDate = startDate;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event, size: 16),
                          label: Text('Đến: ${dateFormat.format(endDate)}'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setSheetState(() => endDate = d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: reasonController,
                    label: 'Lý do nghỉ phép',
                    hint: 'Nhập rõ lý do xin nghỉ...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: existing == null ? 'Gửi Đơn' : 'Lưu Thay Đổi',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập lý do nghỉ phép')),
                        );
                        return;
                      }

                      setSheetState(() => isSaving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      try {
                        if (existing == null) {
                          await LeaveService.createRequest(
                            leaveType: leaveType,
                            startDate: startDate,
                            endDate: endDate,
                            reason: reasonController.text.trim(),
                          );
                        } else {
                          await LeaveService.updateRequest(
                            id: existing.id,
                            leaveType: leaveType,
                            startDate: startDate,
                            endDate: endDate,
                            reason: reasonController.text.trim(),
                          );
                        }
                        nav.pop();
                        _loadRequests();
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
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRequest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa đơn xin nghỉ phép này?'),
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
        await LeaveService.deleteRequest(id);
        _loadRequests();
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
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo Đơn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.beach_access, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Bạn chưa có đơn xin nghỉ phép nào', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showCreateEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo đơn xin nghỉ'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    itemCount: _requests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _requests[index];
                      final dateFormat = DateFormat('dd/MM/yyyy');

                      Color statusColor;
                      String statusText;
                      if (item.isApproved) {
                        statusColor = Colors.green;
                        statusText = 'Đã duyệt';
                      } else if (item.isRejected) {
                        statusColor = Colors.red;
                        statusText = 'Bị từ chối';
                      } else {
                        statusColor = Colors.orange;
                        statusText = 'Đang chờ duyệt';
                      }

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
                                  Text(
                                    item.leaveTypeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thời gian: ${dateFormat.format(item.startDate)} → ${dateFormat.format(item.endDate)}',
                                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lý do: ${item.reason}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              if (item.reviewNote != null && item.reviewNote!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Phản hồi quản lý: ${item.reviewNote}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: item.isApproved ? Colors.green.shade800 : Colors.red.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (item.isPending) ...[
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Sửa'),
                                      onPressed: () => _showCreateEditDialog(existing: item),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      onPressed: () => _deleteRequest(item.id),
                                    ),
                                  ],
                                ),
                              ],
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
