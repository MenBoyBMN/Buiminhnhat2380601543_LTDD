import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class AllAttendanceScreen extends StatefulWidget {
  const AllAttendanceScreen({super.key});

  @override
  State<AllAttendanceScreen> createState() => _AllAttendanceScreenState();
}

class _AllAttendanceScreenState extends State<AllAttendanceScreen> {
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    setState(() => _isLoading = true);
    try {
      final list = await AttendanceService.getAllRecords(status: _statusFilter);
      if (mounted) {
        setState(() {
          _records = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Không thể tải ảnh minh chứng'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bản ghi chấm công này?'),
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
        await AttendanceService.deleteRecord(id);
        _loadAllRecords();
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
                label: const Text('Tất cả'),
                selected: _statusFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _statusFilter = null);
                    _loadAllRecords();
                  }
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Đúng giờ'),
                selected: _statusFilter == 'OnTime',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _statusFilter = 'OnTime');
                    _loadAllRecords();
                  }
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Đi trễ'),
                selected: _statusFilter == 'Late',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _statusFilter = 'Late');
                    _loadAllRecords();
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
              : _records.isEmpty
                  ? Center(
                      child: Text('Không có dữ liệu chấm công', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllRecords,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _records.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                          final isOnTime = r.status.toLowerCase() == 'ontime';

                          return Card(
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (r.photoUrl != null && r.photoUrl!.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => _showImageDialog(ConfigUrl.getImageUrl(r.photoUrl)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          ConfigUrl.getImageUrl(r.photoUrl),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 64,
                                            height: 64,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.person, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getMoodEmoji(r.mood),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.fullName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isOnTime ? Colors.green.shade50 : Colors.orange.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isOnTime ? Colors.green.shade200 : Colors.orange.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                isOnTime ? 'Đúng giờ' : 'Đi trễ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOnTime ? Colors.green.shade800 : Colors.orange.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Phòng: ${r.departmentName ?? 'Chưa rõ'} | Ca: ${r.shiftName ?? 'Ca chuẩn'}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Vào: ${dateFormat.format(r.checkInTime.toLocal())}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        if (r.checkOutTime != null)
                                          Text(
                                            'Ra: ${dateFormat.format(r.checkOutTime!.toLocal())}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'GPS: ${r.distanceMeters.toStringAsFixed(1)}m (${r.isWithinGeofence ? 'Trong VP' : 'Ngoài VP'})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: r.isWithinGeofence ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                        if (r.note != null && r.note!.isNotEmpty)
                                          Text('Ghi chú: ${r.note}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _deleteRecord(r.id),
                                  ),
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

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'Energetic':
        return '⚡';
      case 'Happy':
        return '😊';
      case 'Neutral':
        return '😐';
      case 'Tired':
        return '😴';
      case 'Stressed':
        return '🤯';
      default:
        return '😊';
    }
  }
}
