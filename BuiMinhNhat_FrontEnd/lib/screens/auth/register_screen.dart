import 'package:flutter/material.dart';
import '../../models/department_model.dart';
import '../../services/auth_service.dart';
import '../../services/department_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _initialsController = TextEditingController();

  List<DepartmentModel> _departments = [];
  int? _selectedDepartmentId;
  String _selectedRole = 'Employee';
  bool _isLoading = false;
  bool _isLoadingDepts = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _fullNameController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final depts = await DepartmentService.getAll();
      if (mounted) {
        setState(() {
          _departments = depts;
          if (depts.isNotEmpty) {
            _selectedDepartmentId = depts.first.id;
          }
          _isLoadingDepts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDepts = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final msg = await AuthService.register(
        userName: _userController.text,
        email: _emailController.text,
        password: _passController.text,
        fullName: _fullNameController.text,
        initials: _initialsController.text.isNotEmpty ? _initialsController.text : null,
        departmentId: _selectedDepartmentId,
        role: _selectedRole,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tạo tài khoản chấm công mới',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Điền đầy đủ thông tin để tham gia hệ thống',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _userController,
                  label: 'Tên đăng nhập',
                  prefixIcon: Icons.account_circle_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _passController,
                  label: 'Mật khẩu (Tối thiểu 6 ký tự)',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu phải từ 6 ký tự trở lên' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _initialsController,
                  label: 'Ký tự viết tắt (Tùy chọn, ví dụ: NV)',
                  prefixIcon: Icons.short_text,
                ),
                const SizedBox(height: 14),

                // Chọn phòng ban
                if (_isLoadingDepts)
                  const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                else
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedDepartmentId,
                    decoration: InputDecoration(
                      labelText: 'Phòng ban làm việc',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: _departments.map((d) {
                      return DropdownMenuItem<int>(
                        value: d.id,
                        child: Text(
                          d.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDepartmentId = val),
                  ),
                const SizedBox(height: 14),

                // Chọn vai trò
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Vai trò (Role)',
                    prefixIcon: const Icon(Icons.manage_accounts_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Employee',
                      child: Text('👤 Nhân viên (Employee)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'Manager',
                      child: Text('💼 Quản lý (Manager)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'Admin',
                      child: Text('👑 Quản trị viên (Admin)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Đăng Ký Tài Khoản',
                  isLoading: _isLoading,
                  icon: Icons.person_add,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
