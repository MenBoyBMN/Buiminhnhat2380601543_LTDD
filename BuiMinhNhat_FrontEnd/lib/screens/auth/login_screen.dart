import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../admin/admin_dashboard_screen.dart';
import '../employee/employee_dashboard_screen.dart';
import '../manager/manager_dashboard_screen.dart';
import 'register_screen.dart';
import 'server_settings_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _fillCredentials(String user, String pass) {
    setState(() {
      _userController.text = user;
      _passController.text = pass;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final step1 = await AuthService.loginStep1(
        _userController.text,
        _passController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showOtpDialog(step1);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showOtpDialog(LoginStep1Result step1) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_read, color: Colors.indigo, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Xác Thực OTP 2 Lớp',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mã OTP 6 số đã được gửi đến email: ${step1.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),

                  // Box demo OTP
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Demo OTP: ${step1.demoOtp}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            otpController.text = step1.demoOtp;
                          },
                          icon: const Icon(Icons.flash_on, size: 16),
                          label: const Text('Điền mã'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  CustomTextField(
                    controller: otpController,
                    label: 'Mã OTP (6 chữ số)',
                    hint: 'Nhập mã 6 chữ số',
                    prefixIcon: Icons.security,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Xác Nhận Đăng Nhập',
                    isLoading: isVerifying,
                    onPressed: () async {
                      final code = otpController.text.trim();
                      if (code.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số OTP')),
                        );
                        return;
                      }

                      setSheetState(() => isVerifying = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      try {
                        final user = await AuthService.verifyOtp(step1.userName, code);
                        if (mounted) {
                          nav.pop();
                          _navigateByRole(user);
                        }
                      } catch (e) {
                        setSheetState(() => isVerifying = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.red.shade700,
                          ),
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

  void _navigateByRole(UserModel user) {
    Widget destination;
    if (user.isAdmin) {
      destination = const AdminDashboardScreen();
    } else if (user.isManager) {
      destination = const ManagerDashboardScreen();
    } else {
      destination = const EmployeeDashboardScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.indigo),
            tooltip: 'Cấu hình Server API',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ServerSettingsDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Branding
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.indigo.shade600, Colors.blue.shade500],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.fingerprint, size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Smart Attendance',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hệ thống Chấm Công Nhân Viên Thông Minh\n(Bùi Minh Nhật - LTDD)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nút điền nhanh tài khoản mẫu (Demo Quick-Fill)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app, size: 16, color: Colors.indigo),
                            SizedBox(width: 6),
                            Text(
                              'Đăng nhập nhanh tài khoản mẫu:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ActionChip(
                              avatar: const Text('👑'),
                              label: const Text('Admin'),
                              onPressed: () => _fillCredentials('admin', 'Admin@123'),
                            ),
                            ActionChip(
                              avatar: const Text('💼'),
                              label: const Text('Quản lý'),
                              onPressed: () => _fillCredentials('manager', 'Manager@123'),
                            ),
                            ActionChip(
                              avatar: const Text('👤'),
                              label: const Text('Nhân viên'),
                              onPressed: () => _fillCredentials('nhanvien1', 'User@123'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  CustomTextField(
                    controller: _userController,
                    label: 'Tên đăng nhập hoặc Email',
                    hint: 'Ví dụ: nhanvien1 hoặc admin',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _passController,
                    label: 'Mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Đăng Nhập',
                    isLoading: _isLoading,
                    icon: Icons.login,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey.shade700)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
