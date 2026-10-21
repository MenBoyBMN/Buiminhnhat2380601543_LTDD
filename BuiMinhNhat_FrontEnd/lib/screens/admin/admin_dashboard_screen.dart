import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'all_attendance_screen.dart';
import 'department_crud_screen.dart';
import 'shift_crud_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  QrSessionModel? _activeQr;
  bool _isLoadingQr = true;
  Timer? _countdownTimer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _fetchQr();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQr() async {
    setState(() => _isLoadingQr = true);
    try {
      final session = await AttendanceService.getActiveQr();
      if (mounted) {
        setState(() {
          _activeQr = session;
          _secondsLeft = session.remainingSeconds;
          _isLoadingQr = false;
        });
        _startTimer();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingQr = false);
    }
  }

  Future<void> _generateNewQr() async {
    _countdownTimer?.cancel();
    setState(() => _isLoadingQr = true);
    try {
      final session = await AttendanceService.generateDynamicQr();
      if (mounted) {
        setState(() {
          _activeQr = session;
          _secondsLeft = 60;
          _isLoadingQr = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingQr = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        _generateNewQr(); // Tự động làm mới khi hết 60s
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi quyền Admin?'),
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
    final titles = ['Mã QR Chấm Công Động', 'Quản Lý Phòng Ban', 'Quản Lý Ca Làm', 'Giám Sát Chấm Công'];

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
          _buildDynamicQrTab(),
          const DepartmentCrudScreen(),
          const ShiftCrudScreen(),
          const AllAttendanceScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 0 && _activeQr == null) _fetchQr();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_2_outlined), selectedIcon: Icon(Icons.qr_code_2), label: 'Mã QR Động'),
          NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Phòng ban'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Ca làm'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Chấm công'),
        ],
      ),
    );
  }

  Widget _buildDynamicQrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: Colors.indigo, size: 20),
                SizedBox(width: 8),
                Text(
                  'Dynamic Anti-Fraud QR Code',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chiếu mã QR này tại sảnh/màn hình văn phòng.\nMã tự động đổi mỗi 60 giây để chống chụp ảnh gửi quét hộ!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // QR Code Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isLoadingQr
                ? const SizedBox(
                    height: 240,
                    width: 240,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      QrImageView(
                        data: _activeQr?.tokenCode ?? 'EMPTY_TOKEN',
                        version: QrVersions.auto,
                        size: 240.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _activeQr?.tokenCode ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Countdown indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.deepOrange, size: 20),
              const SizedBox(width: 6),
              Text(
                'Tự động làm mới sau: ',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              Text(
                '$_secondsLeft giây',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _generateNewQr,
            icon: const Icon(Icons.refresh),
            label: const Text('Đổi Mã QR Ngay'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
