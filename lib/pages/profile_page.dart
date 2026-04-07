import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/notification_service.dart';
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
  final NotificationService _notificationService = NotificationService.instance;

  UserModel? _user;
  bool _isLoading = true;
  bool _avatarUploading = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadNotificationCount();
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

  Future<void> _loadUnreadNotificationCount() async {
    final isLoggedIn = await AuthService.instance.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      setState(() => _unreadNotificationCount = 0);
      return;
    }
    try {
      final count = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadNotificationCount = count);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unreadNotificationCount = 0);
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _openEditProfile() async {
    await context.pushNamed('editProfile');
    if (mounted) await _loadUser();
  }

  Future<void> _openNotifications() async {
    await context.pushNamed('notifications');
    if (!mounted) return;
    await _loadUnreadNotificationCount();
  }

  Future<void> _changeAvatarQuick() async {
    final newUser = await AuthService.instance.pickAndChangeAvatar(
      onUploading: (value) {
        if (mounted) setState(() => _avatarUploading = value);
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loi tai anh len: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );

    if (newUser != null && mounted) {
      await _loadUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doi anh dai dien thanh cong'),
          backgroundColor: AppColors.success,
        ),
      );
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
                  child: GestureDetector(
                    onTap: _changeAvatarQuick,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.cardDark,
                          child: _avatarUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
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
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            opacity: _avatarUploading ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
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
                    _avatarUploading
                        ? 'Dang tai anh len...'
                        : 'Nhan vao anh de thay doi',
                    style: TextStyle(
                      fontSize: 11,
                      color: _avatarUploading
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _user?.name ?? 'Khach',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                  badgeText: _unreadNotificationCount > 0
                      ? (_unreadNotificationCount > 99
                          ? '99+'
                          : '$_unreadNotificationCount')
                      : null,
                  onTap: _openNotifications,
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Tro giup & Ho tro',
                  onTap: () => _showInfo(
                    context,
                    'Lien he ho tro',
                    'Vui long lien he bo phan CSKH de duoc ho tro.',
                  ),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'Thong tin ung dung',
                  onTap: () => _showInfo(
                    context,
                    'Cinema Booking',
                    'Ung dung dat ve rap phim.',
                  ),
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
  final String? badgeText;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
