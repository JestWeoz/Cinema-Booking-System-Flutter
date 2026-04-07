// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/notification_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService.instance;
  List<MovieModel> _nowShowing = [];
  List<MovieModel> _comingSoon = [];
  bool _isLoading = true;
  String? _error;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        MovieService.instance.getNowShowing(),
        MovieService.instance.getComingSoon(),
      ]);
      if (mounted) {
        setState(() {
          _nowShowing = results[0];
          _comingSoon = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    final isLoggedIn = await _authService.isLoggedIn();
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

  Future<void> _openNotifications() async {
    await context.pushNamed('notifications');
    if (!mounted) return;
    await _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMovies,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                children: [
                  const Icon(Icons.movie, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text('CinemaBook', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
                _NotificationBellButton(
                  count: _unreadNotificationCount,
                  onPressed: _openNotifications,
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Không thể kết nối server', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadMovies, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionTitle(title: 'Đang chiếu', onSeeAll: () {}),
                    const SizedBox(height: 12),
                    _MovieCarousel(movies: _nowShowing),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Sắp chiếu', onSeeAll: () {}),
                    const SizedBox(height: 12),
                    _MovieGrid(movies: _comingSoon),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationBellButton({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = count > 99 ? '99+' : '$count';
    return IconButton(
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              right: -8,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  badgeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionTitle({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
      ],
    );
  }
}

class _MovieCarousel extends StatelessWidget {
  final List<MovieModel> movies;
  const _MovieCarousel({required this.movies});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return SizedBox(
        height: 220,
        child: const Center(child: Text('Không có phim', style: TextStyle(color: Colors.grey))),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () => context.push(AppRoutes.movieDetail.replaceFirst(':id', movie.id)),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: movie.posterUrl.isNotEmpty
                          ? AppNetworkImage(
                              url: movie.posterUrl,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.movie_outlined,
                              backgroundColor: AppColors.dividerDark,
                            )
                          : Container(
                              color: AppColors.dividerDark,
                              child: const Center(child: Icon(Icons.movie_outlined, color: Colors.grey))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movie.title,
                            style: Theme.of(context).textTheme.labelLarge,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.secondary, size: 12),
                            const SizedBox(width: 2),
                            Text(movie.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MovieGrid extends StatelessWidget {
  final List<MovieModel> movies;
  const _MovieGrid({required this.movies});

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Không có phim', style: TextStyle(color: Colors.grey))),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return GestureDetector(
          onTap: () => context.push(AppRoutes.movieDetail.replaceFirst(':id', movie.id)),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: movie.posterUrl.isNotEmpty
                  ? AppNetworkImage(
                      url: movie.posterUrl,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.movie_outlined,
                      backgroundColor: AppColors.cardDark,
                    )
                  : const Center(child: Icon(Icons.movie_outlined, color: Colors.grey)),
            ),
          ),
        );
      },
    );
  }
}
