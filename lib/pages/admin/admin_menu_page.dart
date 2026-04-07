import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _MenuItem(icon: Icons.movie_outlined, label: 'Phim', route: AppRoutes.adminMovies, color: Color(0xFFE50914)),
      const _MenuItem(icon: Icons.schedule_outlined, label: 'Suất Chiếu', route: AppRoutes.adminShowtimes, color: Color(0xFFFF6B35)),
      const _MenuItem(icon: Icons.category_outlined, label: 'Thể Loại', route: AppRoutes.adminCategories, color: Color(0xFF00BCD4)),
      const _MenuItem(icon: Icons.fastfood_outlined, label: 'Sản Phẩm', route: AppRoutes.adminProducts, color: Color(0xFF8BC34A)),
      const _MenuItem(icon: Icons.theater_comedy_outlined, label: 'Người Tham Gia', route: AppRoutes.adminPeople, color: Color(0xFFEC407A)),
      const _MenuItem(icon: Icons.local_offer_outlined, label: 'Voucher', route: AppRoutes.adminVouchers, color: Color(0xFFFFC107)),
      const _MenuItem(icon: Icons.people_outlined, label: 'Người Dùng', route: AppRoutes.adminUsers, color: Color(0xFF4CAF50)),
      const _MenuItem(icon: Icons.theater_comedy_outlined, label: 'Rạp Chiếu', route: AppRoutes.adminCinema, color: Color(0xFF9C27B0)),
      const _MenuItem(icon: Icons.bar_chart_rounded, label: 'Thống Kê', route: AppRoutes.adminStats, color: Color(0xFFFF5722)),
      const _MenuItem(icon: Icons.settings_outlined, label: 'Cài Đặt', route: AppRoutes.adminSettings, color: Color(0xFF607D8B)),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.surfaceDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('CinemaAdmin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0A0A), Color(0xFF0A0A1A)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.admin_panel_settings,
                      size: 80, color: AppColors.primary.withValues(alpha: 0.15)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = items[i];
                  return _MenuCard(item: item);
                },
                childCount: items.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _MenuItem({required this.icon, required this.label, required this.route, required this.color});
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.3), width: 1),
          boxShadow: [BoxShadow(color: item.color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(item.label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
