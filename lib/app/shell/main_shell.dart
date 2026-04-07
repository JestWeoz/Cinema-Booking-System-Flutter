import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatefulWidget {
  const _BottomNavBar();

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: AppRoutes.home,
    ),
    _NavItem(
      label: 'Chọn rạp',
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on,
      route: AppRoutes.schedules,
    ),
    _NavItem(
      label: 'Ưu đãi',
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer,
      route: AppRoutes.offers,
    ),
    _NavItem(
      label: 'Cá nhân',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: AppRoutes.profile,
    ),
  ];

  RouterDelegate<RouteMatchList>? _delegate;
  String _location = AppRoutes.home;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    final delegate = router.routerDelegate;
    if (delegate != _delegate) {
      _delegate?.removeListener(_onRouteChange);
      _delegate = delegate;
      _delegate!.addListener(_onRouteChange);
      _location = delegate.currentConfiguration.uri.toString();
    }
  }

  void _onRouteChange() {
    final newLocation =
        _delegate?.currentConfiguration?.uri.toString() ?? _location;
    if (newLocation == _location) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _location = newLocation);
      }
    });
  }

  @override
  void dispose() {
    _delegate?.removeListener(_onRouteChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex =
        _items.indexWhere((item) => _location.startsWith(item.route));
    if (currentIndex < 0) {
      currentIndex = 0;
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => context.go(_items[index].route),
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
