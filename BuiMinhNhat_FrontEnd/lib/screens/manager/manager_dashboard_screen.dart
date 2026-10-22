import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/all_attendance_screen.dart';
import '../auth/login_screen.dart';
import '../employee/leaderboard_screen.dart';
import 'leave_approval_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<LeaveApprovalScreenState> _leaveKey = GlobalKey<LeaveApprovalScreenState>();
  final GlobalKey<AllAttendanceScreenState> _attendanceKey = GlobalKey<AllAttendanceScreenState>();
  final GlobalKey<LeaderboardScreenState> _leaderboardKey = GlobalKey<LeaderboardScreenState>();

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi quyền Quản lý?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Duyệt Đơn Nghỉ Phép', 'Giám Sát Chấm Công Đội Ngũ', 'Bảng Xếp Hạng Chuyên Cần'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LeaveApprovalScreen(key: _leaveKey),
          AllAttendanceScreen(key: _attendanceKey),
          LeaderboardScreen(key: _leaderboardKey),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 0) {
            _leaveKey.currentState?.loadAllRequests();
          } else if (idx == 1) {
            _attendanceKey.currentState?.loadAllRecords();
          } else if (idx == 2) {
            _leaderboardKey.currentState?.loadLeaderboard();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Duyệt đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Giám sát',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Xếp hạng',
          ),
        ],
      ),
    );
  }
}
