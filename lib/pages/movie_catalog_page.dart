import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_showtime_page.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/movie_service.dart';

class MovieCatalogPage extends StatefulWidget {
  final String section;

  const MovieCatalogPage({
    super.key,
    required this.section,
  });

  @override
  State<MovieCatalogPage> createState() => _MovieCatalogPageState();
}

class _MovieCatalogPageState extends State<MovieCatalogPage> {
  final TextEditingController _searchController = TextEditingController();

  List<MovieModel> _movies = const [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  bool get _isComingSoon => widget.section == 'coming-soon';

  String get _title => _isComingSoon ? 'Phim sap chieu' : 'Phim dang chieu';

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movies = _isComingSoon
          ? await MovieService.instance.getComingSoon(size: 60)
          : await MovieService.instance.getNowShowing(size: 60);
      if (!mounted) {
        return;
      }
      setState(() {
        _movies = movies;
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

  List<MovieModel> get _filteredMovies {
    if (_query.isEmpty) {
      return _movies;
    }
    return _movies.where((movie) {
      final haystack =
          '${movie.title} ${movie.genres.join(' ')} ${movie.overview}'
              .toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  Future<void> _openBooking(MovieModel movie) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingShowtimePage(
          movie: BookingMovieSnapshot(
            movieId: movie.id,
            title: movie.title,
            posterUrl: movie.posterUrl,
            ageRating: movie.ageRating,
            durationMinutes: movie.durationMinutes,
          ),
        ),
      ),
    );
  }

  String _formatReleaseDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return 'Chua cap nhat';
    }
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _formatDayMonth(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '';
    }
    return DateFormat('dd/MM').format(parsed);
  }

  String _formatMonthKey(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return 'Khac';
    }
    return DateFormat('MM/yyyy').format(parsed);
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

  String _ratingLabel(MovieModel movie) {
    if (movie.rating <= 0) {
      return 'Chua co danh gia';
    }
    return '${movie.rating.toStringAsFixed(1)}/10';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovies;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _CatalogHeader(
              title: _title,
              controller: _searchController,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _error != null
                      ? _CatalogErrorState(onRetry: _loadMovies)
                      : RefreshIndicator(
                          onRefresh: _loadMovies,
                          color: AppColors.primary,
                          child: _isComingSoon
                              ? _ComingSoonCatalog(
                                  movies: filtered,
                                  ageLabel: _ageLabel,
                                  formatDayMonth: _formatDayMonth,
                                  formatMonthKey: _formatMonthKey,
                                )
                              : _NowShowingCatalog(
                                  movies: filtered,
                                  ageLabel: _ageLabel,
                                  ratingLabel: _ratingLabel,
                                  formatReleaseDate: _formatReleaseDate,
                                  onOpenDetail: (movie) => context.push(
                                    AppRoutes.movieDetail
                                        .replaceFirst(':id', movie.id),
                                  ),
                                  onOpenBooking: _openBooking,
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const _CatalogHeader({
    required this.title,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF191313), Color(0xFF231415)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
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
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.home_outlined,
                onTap: () => context.go(AppRoutes.home),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tim kiem phim',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white54,
              ),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _NowShowingCatalog extends StatelessWidget {
  final List<MovieModel> movies;
  final String Function(AgeRating? rating) ageLabel;
  final String Function(MovieModel movie) ratingLabel;
  final String Function(String value) formatReleaseDate;
  final ValueChanged<MovieModel> onOpenDetail;
  final ValueChanged<MovieModel> onOpenBooking;

  const _NowShowingCatalog({
    required this.movies,
    required this.ageLabel,
    required this.ratingLabel,
    required this.formatReleaseDate,
    required this.onOpenDetail,
    required this.onOpenBooking,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Khong co phim phu hop.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _NowShowingMovieCard(
          movie: movie,
          ageText: ageLabel(movie.ageRating),
          ratingText: ratingLabel(movie),
          dateText: formatReleaseDate(movie.releaseDate),
          onOpenDetail: () => onOpenDetail(movie),
          onOpenBooking: () => onOpenBooking(movie),
        );
      },
    );
  }
}

class _ComingSoonCatalog extends StatelessWidget {
  final List<MovieModel> movies;
  final String Function(AgeRating? rating) ageLabel;
  final String Function(String value) formatDayMonth;
  final String Function(String value) formatMonthKey;

  const _ComingSoonCatalog({
    required this.movies,
    required this.ageLabel,
    required this.formatDayMonth,
    required this.formatMonthKey,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text(
            'Khong co phim phu hop.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    final grouped = <String, List<MovieModel>>{};
    for (final movie in movies) {
      final key = formatMonthKey(movie.releaseDate);
      grouped.putIfAbsent(key, () => <MovieModel>[]).add(movie);
    }

    final monthKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        for (final month in monthKeys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Text(
              'Thang $month',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 372,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: grouped[month]!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final movie = grouped[month]![index];
                return _ComingSoonMovieCard(
                  movie: movie,
                  ageText: ageLabel(movie.ageRating),
                  dayText: formatDayMonth(movie.releaseDate),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _NowShowingMovieCard extends StatelessWidget {
  final MovieModel movie;
  final String ageText;
  final String ratingText;
  final String dateText;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenBooking;

  const _NowShowingMovieCard({
    required this.movie,
    required this.ageText,
    required this.ratingText,
    required this.dateText,
    required this.onOpenDetail,
    required this.onOpenBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AppNetworkImage(
                  url: movie.posterUrl,
                  width: 112,
                  height: 168,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.movie_outlined,
                  backgroundColor: AppColors.cardDark,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _AgeBadge(label: ageText),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ratingText,
                  style: const TextStyle(
                    color: Color(0xFFFF7B39),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                  movie.genres.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      movie.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onOpenDetail,
                        child: const Text('Chi tiet'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onOpenBooking,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Mua ve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonMovieCard extends StatelessWidget {
  final MovieModel movie;
  final String ageText;
  final String dayText;

  const _ComingSoonMovieCard({
    required this.movie,
    required this.ageText,
    required this.dayText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.push(AppRoutes.movieDetail.replaceFirst(':id', movie.id)),
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 214,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AppNetworkImage(
                      url: movie.posterUrl,
                      width: 194,
                      height: 214,
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
                dayText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
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
                movie.genres.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeBadge extends StatelessWidget {
  final String label;

  const _AgeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB022),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _CatalogErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Khong tai duoc danh sach phim.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}
