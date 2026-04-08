import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/notification_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService.instance;
  final PageController _featuredController = PageController(
    viewportFraction: 0.74,
  );

  List<MovieModel> _featuredMovies = const [];
  List<MovieModel> _nowShowing = const [];
  List<MovieModel> _comingSoon = const [];
  bool _isLoading = true;
  String? _error;
  int _unreadNotificationCount = 0;
  int _featuredIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    _featuredController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final nowShowingFuture = MovieService.instance.getNowShowing(size: 12);
      final comingSoonFuture = MovieService.instance.getComingSoon(size: 18);
      final recommendedFuture = MovieService.instance.getRecommended();

      final results = await Future.wait<dynamic>([
        nowShowingFuture,
        comingSoonFuture,
        recommendedFuture.catchError((_) => <MovieModel>[]),
      ]);

      final nowShowing = results[0] as List<MovieModel>;
      final comingSoon = results[1] as List<MovieModel>;
      final recommended = results[2] as List<MovieModel>;

      if (!mounted) {
        return;
      }

      setState(() {
        _nowShowing = nowShowing;
        _comingSoon = comingSoon;
        _featuredMovies =
            _buildFeaturedMovies(recommended, nowShowing, comingSoon);
        _featuredIndex = 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<MovieModel> _buildFeaturedMovies(
    List<MovieModel> recommended,
    List<MovieModel> nowShowing,
    List<MovieModel> comingSoon,
  ) {
    final byId = <String, MovieModel>{};
    for (final movie in recommended) {
      byId[movie.id] = movie;
    }

    final combined = [...nowShowing, ...comingSoon]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    for (final movie in combined) {
      byId.putIfAbsent(movie.id, () => movie);
    }

    return byId.values.take(6).toList();
  }

  Future<void> _loadUnreadNotificationCount() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) {
        return;
      }
      setState(() => _unreadNotificationCount = 0);
      return;
    }

    try {
      final count = await _notificationService.getUnreadCount();
      if (!mounted) {
        return;
      }
      setState(() => _unreadNotificationCount = count);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _unreadNotificationCount = 0);
    }
  }

  Future<void> _openNotifications() async {
    await context.pushNamed('notifications');
    if (!mounted) {
      return;
    }
    await _loadUnreadNotificationCount();
  }

  String _ageLabel(AgeRating? rating) {
    switch (rating) {
      case AgeRating.C13:
        return '13+';
      case AgeRating.C16:
        return '16+';
      case AgeRating.C18:
        return '18+';
      case AgeRating.P:
        return 'P';
      default:
        return 'T';
    }
  }

  String _movieMeta(MovieModel movie) {
    final genres =
        movie.genres.where((item) => item.isNotEmpty).take(3).join(', ');
    return genres.isEmpty ? 'Dang cap nhat' : genres;
  }

  String _ratingText(MovieModel movie) {
    if (movie.rating <= 0) {
      return 'Chua co danh gia';
    }
    return '${movie.rating.toStringAsFixed(1)}/10';
  }

  @override
  Widget build(BuildContext context) {
    final featured = _featuredMovies;
    final currentFeatured = featured.isEmpty
        ? null
        : featured[_featuredIndex.clamp(0, featured.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeroHeader(
                  unreadNotificationCount: _unreadNotificationCount,
                  onNotificationsTap: _openNotifications,
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Khong tai duoc du lieu trang chu.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadHomeData,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Thu lai'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (featured.isNotEmpty) ...[
                          const _HomeSectionHeader(title: 'Phim nổi bật'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 446,
                            child: PageView.builder(
                              controller: _featuredController,
                              itemCount: featured.length,
                              onPageChanged: (index) =>
                                  setState(() => _featuredIndex = index),
                              itemBuilder: (context, index) {
                                final movie = featured[index];
                                final isActive = index == _featuredIndex;
                                return AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  scale: isActive ? 1 : 0.9,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: _FeaturedMoviePoster(
                                      movie: movie,
                                      ageText: _ageLabel(movie.ageRating),
                                      isActive: isActive,
                                      onTap: () => context.push(
                                        AppRoutes.movieDetail
                                            .replaceFirst(':id', movie.id),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (currentFeatured != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 22,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFFF7B39),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _ratingText(currentFeatured),
                                        style: const TextStyle(
                                          color: Color(0xFFFF7B39),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentFeatured.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _movieMeta(currentFeatured),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                          ],
                        ],
                        _HomeSectionHeader(
                          title: 'Phim đang chiếu',
                          actionLabel: 'Xem tat ca',
                          onAction: () => context.push(
                            AppRoutes.movieCatalogBySection('now-showing'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _HorizontalMovieStrip(
                          movies: _nowShowing,
                          ageLabel: _ageLabel,
                          metaBuilder: _movieMeta,
                          ratingBuilder: _ratingText,
                        ),
                        const SizedBox(height: 28),
                        _HomeSectionHeader(
                          title: 'Phim sắp chiếu',
                          actionLabel: 'Xem tat ca',
                          onAction: () => context.push(
                            AppRoutes.movieCatalogBySection('coming-soon'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _HorizontalMovieStrip(
                          movies: _comingSoon,
                          ageLabel: _ageLabel,
                          metaBuilder: _movieMeta,
                          ratingBuilder: _ratingText,
                          showComingSoonDate: true,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeroHeader extends StatelessWidget {
  final int unreadNotificationCount;
  final VoidCallback onNotificationsTap;

  const _HomeHeroHeader({
    required this.unreadNotificationCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF191313), Color(0xFF221415)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mua vé xem phim',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _RoundedIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationsTap,
                badgeCount: unreadNotificationCount,
              ),
              const SizedBox(width: 10),
              _RoundedIconButton(
                icon: Icons.person_outline_rounded,
                onTap: () => context.go(AppRoutes.profile),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _FakeSearchField(),
        ],
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HomeSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _HorizontalMovieStrip extends StatelessWidget {
  final List<MovieModel> movies;
  final String Function(AgeRating? rating) ageLabel;
  final String Function(MovieModel movie) metaBuilder;
  final String Function(MovieModel movie) ratingBuilder;
  final bool showComingSoonDate;

  const _HorizontalMovieStrip({
    required this.movies,
    required this.ageLabel,
    required this.metaBuilder,
    required this.ratingBuilder,
    this.showComingSoonDate = false,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Khong co phim.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 360,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _HomeMovieCard(
            movie: movie,
            ageText: ageLabel(movie.ageRating),
            titleMeta: metaBuilder(movie),
            subtitleText: ratingBuilder(movie),
            showComingSoonDate: showComingSoonDate,
          );
        },
      ),
    );
  }
}

class _HomeMovieCard extends StatelessWidget {
  final MovieModel movie;
  final String ageText;
  final String titleMeta;
  final String subtitleText;
  final bool showComingSoonDate;

  const _HomeMovieCard({
    required this.movie,
    required this.ageText,
    required this.titleMeta,
    required this.subtitleText,
    required this.showComingSoonDate,
  });

  String _releaseText() {
    final parsed = DateTime.tryParse(movie.releaseDate);
    if (parsed == null) {
      return 'Sap ra rap';
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return 'Khoi chieu $day/$month';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.push(AppRoutes.movieDetail.replaceFirst(':id', movie.id)),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AppNetworkImage(
                    url: movie.posterUrl,
                    width: 176,
                    height: 230,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.movie_outlined,
                    backgroundColor: AppColors.cardDark,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _AgeBadge(label: ageText),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              showComingSoonDate ? _releaseText() : subtitleText,
              style: TextStyle(
                color: showComingSoonDate
                    ? Colors.white70
                    : const Color(0xFFFF7B39),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titleMeta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedMoviePoster extends StatelessWidget {
  final MovieModel movie;
  final String ageText;
  final bool isActive;
  final VoidCallback onTap;

  const _FeaturedMoviePoster({
    required this.movie,
    required this.ageText,
    required this.isActive,
    required this.onTap,
  });

  String _featuredTag() {
    final genres =
        movie.genres.where((item) => item.trim().isNotEmpty).toList();
    if (genres.isNotEmpty) {
      return genres.first;
    }
    return 'Dang cap nhat';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: isActive ? 0.16 : 0.08),
            width: isActive ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x33000000).withValues(
                alpha: isActive ? 0.28 : 0.18,
              ),
              blurRadius: isActive ? 34 : 20,
              offset: Offset(0, isActive ? 24 : 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: AppNetworkImage(
                url: movie.posterUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                fallbackIcon: Icons.movie_outlined,
                backgroundColor: AppColors.cardDark,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.68),
                    ],
                    stops: const [0, 0.38, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _AgeBadge(
                    label: ageText,
                    compact: true,
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (movie.rating > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFF7B39),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFFFF7B39),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            _featuredTag(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeSearchField extends StatelessWidget {
  const _FakeSearchField();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.search),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 54,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: Colors.white54),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tìm tên phim',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _RoundedIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        if ((badgeCount ?? 0) > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: Text(
                badgeCount! > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AgeBadge extends StatelessWidget {
  final String label;
  final bool compact;

  const _AgeBadge({
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB022),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: compact ? 1.6 : 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 14,
        ),
      ),
    );
  }
}
