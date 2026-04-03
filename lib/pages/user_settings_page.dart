import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cai dat')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tai khoan'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Dang xuat',
              isOutlined: true,
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
