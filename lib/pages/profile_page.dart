import 'package:cinema_booking_system_app/models/requests/auth_requests.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';

class ProfilePage extends StatefulWidget {
  
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (mounted) setState(() { _user = user; _isLoading = false; });
  }

  

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.cardDark,
                        backgroundImage: (_user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(_user!.avatarUrl!)
                            : null,
                        child: (_user?.avatarUrl == null || _user!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _user?.name ?? 'Guest',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    _user?.email ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),

                // Menu Items
                _MenuItem(icon: Icons.person_outline, label: 'Chỉnh sửa thông tin', onTap: () {}),
                _MenuItem(icon: Icons.lock_outline, label: 'Đổi mật khẩu', onTap: () {}),
                _MenuItem(icon: Icons.notifications_outlined, label: 'Thông báo', onTap: () {}),
                _MenuItem(icon: Icons.help_outline, label: 'Trợ giúp & Hỗ trợ', onTap: () {}),
                _MenuItem(icon: Icons.info_outline, label: 'Thông tin', onTap: () {}),
                const SizedBox(height: 24),

                AppButton(
                  label: 'Đăng xuất',
                  isOutlined: true,
                  onPressed: _logout,
                ),
              ],
            ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
