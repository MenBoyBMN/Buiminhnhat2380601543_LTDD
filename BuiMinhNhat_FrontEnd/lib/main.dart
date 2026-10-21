import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/config_url.dart';
import 'models/user_model.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/employee/employee_dashboard_screen.dart';
import 'screens/manager/manager_dashboard_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load cấu hình .env (bỏ qua lỗi nếu file chưa nạp để fallback vào default)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Khởi tạo URL máy chủ
  await ConfigUrl.init();

  // Kiểm tra phiên đăng nhập đã lưu trong SharedPreferences
  final savedUser = await AuthService.getStoredUser();

  runApp(AttendanceApp(initialUser: savedUser));
}

class AttendanceApp extends StatelessWidget {
  final UserModel? initialUser;

  const AttendanceApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;
    if (initialUser != null) {
      if (initialUser!.isAdmin) {
        initialScreen = const AdminDashboardScreen();
      } else if (initialUser!.isManager) {
        initialScreen = const ManagerDashboardScreen();
      } else {
        initialScreen = const EmployeeDashboardScreen();
      }
    } else {
      initialScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Smart Attendance - Bùi Minh Nhật',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo.shade700,
          secondary: Colors.blue.shade600,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        fontFamily: 'Roboto',
      ),
      home: initialScreen,
    );
  }
}
