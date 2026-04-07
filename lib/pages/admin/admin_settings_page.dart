import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  UserResponse? _user;
  DateTime? _dob;
  Gender? _gender;
  bool _loading = true;
  bool _savingProfile = false;
  bool _uploadingAvatar = false;
  bool _changingPassword = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'STAFF':
        return 'Nhân viên';
      case 'USER':
        return 'Người dùng';
      default:
        return role;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.getCurrentUserResponse();
      if (!mounted) return;
      if (user != null) {
        _user = user;
        _fullNameCtrl.text = user.fullName;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
        _gender = user.gender;
        _dob = _parseDate(user.dob);
      }
    } catch (e) {
      if (mounted) _snack('Không tải được thông tin: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardDark,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _savingProfile = true);
    try {
      await AuthService.instance.updateProfile(
        UpdateProfileRequest(
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          dob: _formatDate(_dob).isEmpty ? null : _formatDate(_dob),
          gender: _gender,
        ),
      );
      await _loadProfile();
      if (!mounted) return;
      _snack('Cập nhật thông tin thành công', error: false);
    } catch (e) {
      if (!mounted) return;
      _snack('Không thể cập nhật thông tin: $e');
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final user = await AuthService.instance.pickAndChangeAvatar(
        onUploading: (value) {
          if (mounted) {
            setState(() => _uploadingAvatar = value);
          }
        },
        onError: (error) {
          if (mounted) _snack('Tải ảnh đại diện thất bại: $error');
        },
      );
      if (user == null) {
        return;
      }
      await _loadProfile();
      if (!mounted) return;
      _snack('Cập nhật avatar thành công', error: false);
    } catch (e) {
      if (!mounted) return;
      _snack('Không thể đổi avatar: $e');
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await AuthService.instance.changePassword(
        ChangePasswordRequest(
          oldPassword: _oldPasswordCtrl.text.trim(),
          newPassword: _newPasswordCtrl.text.trim(),
          confirmPassword: _confirmPasswordCtrl.text.trim(),
        ),
      );
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (!mounted) return;
      _snack('Đổi mật khẩu thành công', error: false);
    } catch (e) {
      if (!mounted) return;
      _snack('Không thể đổi mật khẩu: $e');
    } finally {
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final base = _required(value, 'email');
    if (base != null) {
      return base;
    }
    final email = value!.trim();
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final base = _required(value, 'số điện thoại');
    if (base != null) {
      return base;
    }
    final phone = value!.trim();
    final pattern = RegExp(r'^[0-9+\-\s]{8,15}$');
    if (!pattern.hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final base = _required(value, 'mật khẩu mới');
    if (base != null) {
      return base;
    }
    if (value!.trim().length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    return null;
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Cài Đặt Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildProfileForm(),
                  const SizedBox(height: 16),
                  _buildPasswordForm(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng Xuất'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final roles = _user?.roles ?? const <String>[];
    final avatarUrl = _user?.avatarUrl;
    final name = (_user?.fullName ?? '').trim().isEmpty
        ? _user?.username ?? 'Admin'
        : _user!.fullName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF23110B), Color(0xFF121A23)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.surfaceDark,
                    child: ClipOval(
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: AppNetworkImage(
                          url: avatarUrl,
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.admin_panel_settings,
                          backgroundColor: AppColors.surfaceDark,
                          iconColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  if (_uploadingAvatar)
                    const SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?.email ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_user?.username ?? ''}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _uploadingAvatar ? null : _changeAvatar,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ảnh đại diện'),
              ),
            ],
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map(
                    (role) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _roleLabel(role),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return _SettingsCard(
      title: 'Thông Tin Cá Nhân',
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _fullNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Họ và tên'),
              validator: (value) => _required(value, 'họ và tên'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Số điện thoại'),
              validator: _validatePhone,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: _inputDecoration(
                  'Ngày sinh',
                  suffixIcon: const Icon(Icons.calendar_month_outlined, color: Colors.white54),
                ),
                child: Text(
                  _formatDate(_dob).isEmpty ? 'Chọn ngày sinh' : _formatDate(_dob),
                  style: TextStyle(
                    color: _formatDate(_dob).isEmpty ? Colors.white54 : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Gender>(
              initialValue: _gender,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Giới tính'),
              items: Gender.values
                  .map(
                    (gender) => DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(genderLabel(gender)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _savingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.save_outlined, color: Colors.black),
                label: const Text(
                  'Lưu Thông Tin',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return _SettingsCard(
      title: 'Đổi Mật Khẩu',
      child: Form(
        key: _passwordFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _oldPasswordCtrl,
              obscureText: _obscureOld,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Mật khẩu hiện tại',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  icon: Icon(
                    _obscureOld ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
              validator: (value) => _required(value, 'mật khẩu hiện tại'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: _obscureNew,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Mật khẩu mới',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  icon: Icon(
                    _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
              validator: _validateNewPassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                'Xác nhận mật khẩu mới',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
              validator: (value) {
                final base = _required(value, 'xác nhận mật khẩu');
                if (base != null) {
                  return base;
                }
                if (value!.trim() != _newPasswordCtrl.text.trim()) {
                  return 'Xác nhận mật khẩu không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _changingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _changingPassword
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_reset_outlined),
                label: const Text('Cập Nhật Mật Khẩu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
