import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    setState(() => _isLoading = true);
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _openEditProfile() async {
    await context.pushNamed('editProfile');
    if (mounted) {
      await _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thong tin ca nhan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.cardDark,
                        backgroundImage: (_user?.avatarUrl != null &&
                                _user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(_user!.avatarUrl!)
                            : null,
                        child: (_user?.avatarUrl == null ||
                                _user!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _user?.name ?? 'Guest',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    _user?.email ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Chinh sua thong tin',
                  onTap: _openEditProfile,
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Doi mat khau',
                  onTap: () => context.pushNamed('changePassword'),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Thong bao',
                  onTap: () => context.pushNamed('notifications'),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Tro giup & Ho tro',
                  onTap: () => _showInfo(context, 'Lien he ho tro',
                      'Vui long lien he bo phan CSKH de duoc ho tro.'),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Thong tin ung dung',
                  onTap: () => _showInfo(
                      context, 'Cinema Booking', 'Ung dung dat ve rap phim.'),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Dang xuat',
                  isOutlined: true,
                  onPressed: _logout,
                ),
              ],
            ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Dong'),
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

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
