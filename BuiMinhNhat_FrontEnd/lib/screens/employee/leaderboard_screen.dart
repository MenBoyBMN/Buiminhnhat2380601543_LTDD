import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardItemModel> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final list = await AttendanceService.getLeaderboard();
      if (mounted) {
        setState(() {
          _leaderboard = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner vinh danh
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: 40)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bảng Xếp Hạng Chuyên Cần',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Đi làm đúng giờ để tăng chuỗi ngày liên tiếp (Streak) và tích lũy điểm thưởng!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Danh sách xếp hạng
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaderboard.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _leaderboard[index];
              final isTop1 = item.rank == 1;
              final isTop2 = item.rank == 2;
              final isTop3 = item.rank == 3;

              Widget rankBadge;
              if (isTop1) {
                rankBadge = const Text('🥇', style: TextStyle(fontSize: 24));
              } else if (isTop2) {
                rankBadge = const Text('🥈', style: TextStyle(fontSize: 24));
              } else if (isTop3) {
                rankBadge = const Text('🥉', style: TextStyle(fontSize: 24));
              } else {
                rankBadge = CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    '${item.rank}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                );
              }

              return Card(
                elevation: isTop1 ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isTop1
                      ? const BorderSide(color: Colors.amber, width: 1.5)
                      : BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: rankBadge,
                  title: Text(
                    item.fullName,
                    style: TextStyle(
                      fontWeight: isTop1 ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    item.departmentName ?? 'Chưa phân phòng',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 2),
                            Text(
                              '${item.streakCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.totalPoints} pts',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
