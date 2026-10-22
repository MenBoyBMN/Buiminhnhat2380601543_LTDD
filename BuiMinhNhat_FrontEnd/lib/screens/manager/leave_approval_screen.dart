import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave_model.dart';
import '../../services/leave_service.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => LeaveApprovalScreenState();
}

class LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  List<LeaveRequestModel> _requests = [];
  bool _isLoading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    loadAllRequests();
  }

  Future<void> loadAllRequests() async {
    if (_requests.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await LeaveService.getAllRequests(status: _statusFilter);
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

  Future<void> _loadAllRequests() => loadAllRequests();

  void _showReviewDialog(LeaveRequestModel request, String targetStatus) {
    final noteController = TextEditingController();
    final isApprove = targetStatus == 'Approved';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle : Icons.cancel,
              color: isApprove ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isApprove ? 'Duyệt Đơn Nghỉ Phép' : 'Từ Chối Đơn Nghỉ Phép',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhân viên: ${request.fullName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Loại nghỉ: ${request.leaveTypeName}'),
            Text('Lý do: ${request.reason}'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Ý kiến / Ghi chú phản hồi (Tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);

              try {
                await LeaveService.reviewRequest(
                  id: request.id,
                  status: targetStatus,
                  reviewNote: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                );
                nav.pop();
                _loadAllRequests();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isApprove ? 'Đã duyệt đơn nghỉ phép!' : 'Đã từ chối đơn nghỉ phép!'),
                    backgroundColor: isApprove ? Colors.green : Colors.red,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                );
              }
            },
            child: Text(isApprove ? 'Xác Nhận Duyệt' : 'Từ Chối', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Lọc: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Chờ duyệt'),
                selected: _statusFilter == 'Pending',
                onSelected: (selected) {
                  setState(() => _statusFilter = selected ? 'Pending' : null);
                  _loadAllRequests();
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Đã duyệt'),
                selected: _statusFilter == 'Approved',
                onSelected: (selected) {
                  setState(() => _statusFilter = selected ? 'Approved' : null);
                  _loadAllRequests();
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _statusFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _statusFilter = null);
                    _loadAllRequests();
                  }
                },
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
                  ? Center(
                      child: Text('Không có đơn nghỉ phép nào', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllRequests,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final req = _requests[index];

                          Color statusColor = Colors.orange;
                          String statusText = 'Đang chờ duyệt';
                          if (req.isApproved) {
                            statusColor = Colors.green;
                            statusText = 'Đã duyệt';
                          } else if (req.isRejected) {
                            statusColor = Colors.red;
                            statusText = 'Đã từ chối';
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
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo.shade50,
                                        child: const Icon(Icons.person, color: Colors.indigo),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(req.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Text(req.departmentName ?? 'Phòng ban', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ),
                                      ),
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
                                  const Divider(height: 18),
                                  Text(
                                    '${req.leaveTypeName}: ${dateFormat.format(req.startDate)} → ${dateFormat.format(req.endDate)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lý do: ${req.reason}',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  if (req.reviewNote != null && req.reviewNote!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Ghi chú phê duyệt: ${req.reviewNote}',
                                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ),
                                  if (req.isPending) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                          label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                                          onPressed: () => _showReviewDialog(req, 'Rejected'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Phê Duyệt'),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          onPressed: () => _showReviewDialog(req, 'Approved'),
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
        ),
      ],
    );
  }
}
