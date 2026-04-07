import 'package:cinema_booking_system_app/core/extensions/string_extensions.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_text_field.dart';
import 'package:cinema_booking_system_app/shared/widgets/image_picker_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _avatarUploading = false;
  DateTime? _dob;
  Gender? _gender;
  UserResponse? _user;

  /// URL ảnh avatar hiện tại (có thể đã được thay đổi)
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await AuthService.instance.getCurrentUserResponse();
    if (!mounted) return;

    if (user != null) {
      _user = user;
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _avatarUrl = user.avatarUrl;
      _gender = user.gender;
      if (user.dob != null && user.dob!.isNotEmpty) {
        _dob = DateTime.tryParse(user.dob!);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initialDate = _dob ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _formatDob(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // 1. Cập nhật thông tin cơ bản
      await AuthService.instance.updateProfile(
        UpdateProfileRequest(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          dob: _formatDob(_dob).isEmpty ? null : _formatDob(_dob),
          gender: _gender,
        ),
      );

      // 2. Nếu avatar URL đã thay đổi (người dùng đã upload ảnh mới)
      final originalAvatar = _user?.avatarUrl?.trim() ?? '';
      if (_avatarUrl != null &&
          _avatarUrl!.isNotEmpty &&
          _avatarUrl != originalAvatar) {
        await AuthService.instance.changeAvatar(
          ChangeAvatarRequest(avatarUrl: _avatarUrl!),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công ✓'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật thông tin'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Avatar picker (tròn, ở đầu trang) ──────────────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ImagePickerButton(
                          label: 'Ảnh đại diện',
                          currentImageUrl: _avatarUrl,
                          size: 110,
                          shape: ImagePickerButtonShape.circle,
                          onUploaded: (url) {
                            setState(() => _avatarUrl = url);
                          },
                          onError: (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi tải ảnh lên: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          },
                        ),
                        if (_avatarUploading)
                          Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nhấn vào ảnh để thay đổi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // ── Thông tin cơ bản ─────────────────────────────────────
                    AppTextField(
                      label: 'Họ và tên',
                      controller: _fullNameController,
                      validator: (v) => v.isNullOrEmpty ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v.isNullOrEmpty) return 'Vui lòng nhập email';
                        if (!(v!.trim()).isValidEmail) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Số điện thoại',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v.isNullOrEmpty) return 'Vui lòng nhập số điện thoại';
                        if (!(v!.trim()).isValidPhone) return 'Số điện thoại không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Ngày sinh ──────────────────────────────────────────
                    InkWell(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày sinh',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _formatDob(_dob).isEmpty ? 'Chọn ngày sinh' : _formatDob(_dob),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Giới tính ──────────────────────────────────────────
                    DropdownButtonFormField<Gender>(
                      initialValue: _gender,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Giới tính'),
                      items: Gender.values
                          .map((g) => DropdownMenuItem<Gender>(
                                value: g,
                                child: Text(g.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const SizedBox(height: 28),

                    AppButton(
                      label: 'Lưu thay đổi',
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
