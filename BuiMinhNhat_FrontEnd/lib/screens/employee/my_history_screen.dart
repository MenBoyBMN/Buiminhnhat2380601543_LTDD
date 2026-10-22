import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/config_url.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  State<MyHistoryScreen> createState() => MyHistoryScreenState();
}

class MyHistoryScreenState extends State<MyHistoryScreen> {
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    if (_records.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await AttendanceService.getMyHistory();
      if (mounted) {
        setState(() {
          _records = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  child: Text('Không tải được ảnh minh chứng'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu chấm công',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = _records[index];
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
          final bool isOnTime = r.status.toLowerCase() == 'ontime';

          return Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh minh chứng (Selfie)
                  if (r.photoUrl != null && r.photoUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageDialog(ConfigUrl.getImageUrl(r.photoUrl)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          ConfigUrl.getImageUrl(r.photoUrl),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _getMoodEmoji(r.mood),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),

                  // Chi tiết chấm công
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOnTime ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOnTime ? Colors.green.shade200 : Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                isOnTime ? '✓ Đúng giờ' : '⏱ Đi trễ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOnTime ? Colors.green.shade800 : Colors.orange.shade900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${r.pointsEarned} ⭐',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vào: ${dateFormat.format(r.checkInTime.toLocal())}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (r.checkOutTime != null)
                          Text(
                            'Ra: ${dateFormat.format(r.checkOutTime!.toLocal())}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: r.isWithinGeofence ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cách VP: ${r.distanceMeters.toStringAsFixed(1)}m (${r.isWithinGeofence ? 'Hợp lệ' : 'Ngoài VP'})',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        if (r.note != null && r.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Ghi chú: ${r.note}',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
