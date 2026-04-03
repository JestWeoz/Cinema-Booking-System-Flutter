import 'package:cinema_booking_system_app/core/extensions/string_extensions.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_text_field.dart';
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
  final _avatarUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _dob;
  Gender? _gender;
  UserResponse? _user;

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
    _avatarUrlController.dispose();
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
      _avatarUrlController.text = user.avatarUrl ?? '';
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
    if (picked != null) {
      setState(() => _dob = picked);
    }
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
      await AuthService.instance.updateProfile(
        UpdateProfileRequest(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          dob: _formatDob(_dob).isEmpty ? null : _formatDob(_dob),
          gender: _gender,
        ),
      );

      final avatarUrl = _avatarUrlController.text.trim();
      final originalAvatar = _user?.avatarUrl?.trim() ?? '';
      if (avatarUrl.isNotEmpty && avatarUrl != originalAvatar) {
        await AuthService.instance.changeAvatar(
          ChangeAvatarRequest(avatarUrl: avatarUrl),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cap nhat thong tin thanh cong')),
      );
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong the cap nhat thong tin')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chinh sua thong tin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Ho va ten',
                      controller: _fullNameController,
                      validator: (v) =>
                          v.isNullOrEmpty ? 'Vui long nhap ho ten' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v.isNullOrEmpty) {
                          return 'Vui long nhap email';
                        }
                        if (!(v!.trim()).isValidEmail) {
                          return 'Email khong hop le';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'So dien thoai',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v.isNullOrEmpty) {
                          return 'Vui long nhap so dien thoai';
                        }
                        if (!(v!.trim()).isValidPhone) {
                          return 'So dien thoai khong hop le';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Avatar URL',
                      controller: _avatarUrlController,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDob,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngay sinh',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _formatDob(_dob).isEmpty
                              ? 'Chon ngay sinh'
                              : _formatDob(_dob),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Gender>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gioi tinh'),
                      items: Gender.values
                          .map(
                            (g) => DropdownMenuItem<Gender>(
                              value: g,
                              child: Text(g.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Luu thay doi',
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
