import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.cardDark,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
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
          const Center(child: Text('John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const Center(child: Text('john@example.com', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: const [
              _StatChip(label: 'Bookings', value: '12'),
              SizedBox(width: 12),
              _StatChip(label: 'Movies', value: '28'),
              SizedBox(width: 12),
              _StatChip(label: 'Points', value: '540'),
            ],
          ),
          const SizedBox(height: 32),

          // Menu Items
          _MenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
          _MenuItem(icon: Icons.lock_outline, label: 'Change Password', onTap: () {}),
          _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
          _MenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
          _MenuItem(icon: Icons.info_outline, label: 'About', onTap: () {}),
          const SizedBox(height: 24),

          AppButton(
            label: 'Sign Out',
            isOutlined: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
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
