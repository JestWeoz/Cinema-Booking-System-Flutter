import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItem> _items = const [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home, route: AppRoutes.home),
    _NavItem(label: 'Tickets', icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number, route: AppRoutes.tickets),
    _NavItem(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = _items.indexWhere((item) => location.startsWith(item.route));
    if (currentIndex < 0) currentIndex = 0;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => context.go(_items[index].route),
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      destinations: _items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
