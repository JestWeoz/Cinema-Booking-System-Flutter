import 'dart:async';

import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_showtime_page.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MovieSearchPage extends StatefulWidget {
  const MovieSearchPage({super.key});

  @override
  State<MovieSearchPage> createState() => _MovieSearchPageState();
}

class _MovieSearchPageState extends State<MovieSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<MovieModel> _results = const [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final normalized = value.trim();

    if (normalized.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _isLoading = false;
        _hasSearched = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _query = normalized;
      _isLoading = true;
      _error = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final movies = await MovieService.instance.search(normalized, size: 20);
        if (!mounted || normalized != _searchController.text.trim()) {
          return;
        }
        setState(() {
          _results = movies;
          _isLoading = false;
          _hasSearched = true;
        });
      } catch (error) {
        if (!mounted || normalized != _searchController.text.trim()) {
          return;
        }
        setState(() {
          _results = const [];
          _isLoading = false;
          _hasSearched = true;
          _error = error.toString();
        });
      }
    });
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

  String _releaseYear(String releaseDate) {
    final parsed = DateTime.tryParse(releaseDate);
    return parsed?.year.toString() ?? 'Dang cap nhat';
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

  bool _isComingSoon(MovieModel movie) {
    return movie.status.toUpperCase().contains('COMING');
  }

  String _statusLabel(MovieModel movie) {
    return _isComingSoon(movie) ? 'Sap chieu' : 'Dang chieu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF121212),
                    Color(0xFF191313),
                    Color(0xFF231415),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Tim ten phim',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white54,
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _onQueryChanged('');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white54,
                                  ),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Huy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              const Text(
                'Khong tim duoc ket qua luc nay.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _onQueryChanged(_searchController.text),
                child: const Text('Thu lai'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 56,
                color: Colors.white38,
              ),
              SizedBox(height: 12),
              Text(
                'Nhap ten phim de tim kiem nhanh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.white38,
              ),
              const SizedBox(height: 12),
              Text(
                'Khong co phim nao khop voi "$_query".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final movie = _results[index];
        final comingSoon = _isComingSoon(movie);

        return Container(
          padding: const EdgeInsets.all(14),
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
                      width: 90,
                      height: 126,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.movie_outlined,
                      backgroundColor: AppColors.cardDark,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB022),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _ageLabel(movie.ageRating),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _releaseYear(movie.releaseDate),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: comingSoon
                                ? AppColors.secondary.withValues(alpha: 0.18)
                                : AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(movie),
                            style: TextStyle(
                              color: comingSoon
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      movie.genres.isEmpty
                          ? 'Dang cap nhat the loai'
                          : movie.genres.take(3).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (movie.rating > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Color(0xFFFF7B39),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFFFF7B39),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push(
                              AppRoutes.movieDetail.replaceFirst(
                                ':id',
                                movie.id,
                              ),
                            ),
                            child: const Text('Thong tin'),
                          ),
                        ),
                        if (!comingSoon) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _openBooking(movie),
                              child: const Text('Mua ve'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
