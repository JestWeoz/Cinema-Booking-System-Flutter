import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/core/theme/app_text_styles.dart';
import 'package:cinema_booking_system_app/core/extensions/string_extensions.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_text_field.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/models/requests/auth_requests.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.login(
        LoginRequest(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
      if (mounted) {
        final isAdmin = await AuthService.instance.isAdmin();
        if (mounted) {
          context.go(isAdmin ? AppRoutes.admin : AppRoutes.home);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Đăng nhập thất bại. Kiểm tra email/mật khẩu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text('Chào mừng trở lại 🎬', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để tiếp tục đặt vé',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Username',
                  hint: 'nhập tên đăng nhập',
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  validator: (v) => v.isNullOrEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (v) => v.isNullOrEmpty ? 'Vui lòng nhập mật khẩu' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                AppButton(label: 'Đăng nhập', onPressed: _submit, isLoading: _isLoading),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản? ', style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
