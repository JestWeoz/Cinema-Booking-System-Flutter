import 'package:cinema_booking_system_app/core/extensions/string_extensions.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.changePassword(
        ChangePasswordRequest(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thanh cong')),
      );
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong the Đổi mật khẩu')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Mat khau hien tai',
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                validator: (v) =>
                    v.isNullOrEmpty ? 'Vui long nhap mat khau hien tai' : null,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  icon: Icon(_obscureOld
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Mat khau moi',
                controller: _newPasswordController,
                obscureText: _obscureNew,
                validator: (v) {
                  if (v.isNullOrEmpty) {
                    return 'Vui long nhap mat khau moi';
                  }
                  if (!(v!.trim()).isValidPassword) {
                    return 'Mat khau phai co it nhat 8 ky tu';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  icon: Icon(_obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Xac nhan mat khau moi',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v.isNullOrEmpty) {
                    return 'Vui long nhap xac nhan mat khau';
                  }
                  if (v != _newPasswordController.text) {
                    return 'Mat khau xac nhan khong khop';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Cap nhat mat khau',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
