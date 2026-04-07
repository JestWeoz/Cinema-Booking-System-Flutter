import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
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
  bool _avatarUploading = false;

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
    if (mounted) await _loadUser();
  }

  /// Quick-change avatar trực tiếp từ profile page
  Future<void> _changeAvatarQuick() async {
    final newUser = await AuthService.instance.pickAndChangeAvatar(
      onUploading: (v) {
        if (mounted) setState(() => _avatarUploading = v);
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải ảnh lên: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    if (newUser != null && mounted) {
      // Reload user sau khi đổi avatar
      await _loadUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi ảnh đại diện thành công ✓'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
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
                // ── Avatar với quick-change tap ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _changeAvatarQuick,
                    child: Stack(
                      children: [
                        // Avatar hiện tại
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.cardDark,
                          child: _avatarUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : ClipOval(
                                  child: SizedBox(
                                    width: 104,
                                    height: 104,
                                    child: AppNetworkImage(
                                      url: _user?.avatarUrl,
                                      width: 104,
                                      height: 104,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.person,
                                      backgroundColor: AppColors.cardDark,
                                    ),
                                  ),
                                ),
                        ),
                        // Badge camera
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            opacity: _avatarUploading ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _avatarUploading ? 'Đang tải ảnh lên...' : 'Nhấn vào ảnh để thay đổi',
                    style: TextStyle(
                      fontSize: 11,
                      color: _avatarUploading ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _user?.name ?? 'Khách',
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

                // ── Menu items ───────────────────────────────────────────────
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Chỉnh sửa thông tin',
                  onTap: _openEditProfile,
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Đổi mật khẩu',
                  onTap: () => context.pushNamed('changePassword'),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Thông báo',
                  onTap: () => context.pushNamed('notifications'),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Trợ giúp & Hỗ trợ',
                  onTap: () => _showInfo(
                      context, 'Liên hệ hỗ trợ', 'Vui lòng liên hệ bộ phận CSKH để được hỗ trợ.'),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Thông tin ứng dụng',
                  onTap: () =>
                      _showInfo(context, 'Cinema Booking', 'Ứng dụng đặt vé rạp phim.'),
                ),
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

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Đóng'),
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
