import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/pages/trailer_player_page.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/review_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class MovieDetailPage extends StatefulWidget {
  final String movieId;

  const MovieDetailPage({super.key, required this.movieId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MovieService _movieService = MovieService.instance;
  final ReviewService _reviewService = ReviewService.instance;

  MovieResponse? _movie;
  List<MoviePersonResponse> _people = const [];
  List<MovieImageResponse> _images = const [];
  List<ReviewResponse> _reviews = const [];
  double _averageRating = 0;
  bool _isLoading = true;
  bool _expandedOverview = false;
  bool _liked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  Future<void> _loadMovie() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movie = await _movieService.getDetail(widget.movieId);
      final results = await Future.wait<dynamic>([
        _safePeople(widget.movieId),
        _safeImages(widget.movieId),
        _safeReviews(widget.movieId),
        _safeAverageRating(widget.movieId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _movie = movie;
        _people = results[0] as List<MoviePersonResponse>;
        _images = results[1] as List<MovieImageResponse>;
        _reviews = results[2] as List<ReviewResponse>;
        _averageRating = results[3] as double;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<MoviePersonResponse>> _safePeople(String movieId) async {
    try {
      return await _movieService.getPeople(movieId);
    } catch (_) {
      return const [];
    }
  }

  Future<List<MovieImageResponse>> _safeImages(String movieId) async {
    try {
      return await _movieService.getImages(movieId);
    } catch (_) {
      return const [];
    }
  }

  Future<List<ReviewResponse>> _safeReviews(String movieId) async {
    try {
      return await _reviewService.getByMovie(movieId, size: 50);
    } catch (_) {
      return const [];
    }
  }

  Future<double> _safeAverageRating(String movieId) async {
    try {
      return await _reviewService.getAverageRating(movieId);
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Chưa cập nhật';
    }
    final parts = value.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return value;
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) {
      return 'Chưa cập nhật';
    }
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (hours == 0) {
      return '$remain phút';
    }
    if (remain == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $remain phút';
  }

  String _languageLabel(String? value) {
    switch (value?.toUpperCase()) {
      case 'ORIGINAL':
        return 'Nguyên bản';
      case 'VIETNAMESE':
        return 'Tiếng Việt';
      case 'ENGLISH':
        return 'Tiếng Anh';
      case 'SUBTITLED':
        return 'Phụ đề';
      case 'DUBBED':
        return 'Lồng tiếng';
      default:
        return value == null || value.isEmpty ? 'Chưa cập nhật' : value;
    }
  }

  String _ageLabel(AgeRating? value) {
    switch (value) {
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

  String _statusLabel(MovieStatus? status) {
    switch (status) {
      case MovieStatus.NOW_SHOWING:
        return 'Đang chiếu';
      case MovieStatus.COMING_SOON:
        return 'Sắp chiếu';
      case MovieStatus.ENDED:
        return 'Đã kết thúc';
      default:
        return 'Chưa rõ';
    }
  }

  Color _statusColor(MovieStatus? status) {
    switch (status) {
      case MovieStatus.NOW_SHOWING:
        return AppColors.success;
      case MovieStatus.COMING_SOON:
        return AppColors.secondary;
      case MovieStatus.ENDED:
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }

  Future<void> _openTrailer() async {
    final url = _movie?.trailerUrl;
    if (url == null || url.isEmpty) {
      return;
    }
    if (Uri.tryParse(url) == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrailerPlayerPage(
          url: url,
          title: _movie?.title ?? 'Trailer',
        ),
      ),
    );
  }

  List<_RatingBand> _ratingBands() {
    final reviews = _reviews;
    final total = math.max(reviews.length, 1);
    int countInRange(int min, int max) {
      return reviews.where((review) => review.rating >= min && review.rating <= max).length;
    }

    return [
      _RatingBand(label: '9-10', count: countInRange(9, 10) / total),
      _RatingBand(label: '7-8', count: countInRange(7, 8) / total),
      _RatingBand(label: '5-6', count: countInRange(5, 6) / total),
      _RatingBand(label: '3-4', count: countInRange(3, 4) / total),
      _RatingBand(label: '1-2', count: countInRange(1, 2) / total),
    ];
  }

  double _buttonFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scaled = width * 0.048;
    if (scaled < 15) {
      return 15;
    }
    if (scaled > 18) {
      return 18;
    }
    return scaled;
  }

  @override
  Widget build(BuildContext context) {
    final movie = _movie;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'Thông tin phim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null || movie == null
              ? _ErrorState(message: _error ?? 'Không tải được thông tin phim', onRetry: _loadMovie)
              : RefreshIndicator(
                  onRefresh: _loadMovie,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _buildHeader(movie),
                      const SizedBox(height: 18),
                      _buildQuickStats(movie),
                      const SizedBox(height: 18),
                      _buildRatingCard(),
                      const SizedBox(height: 18),
                      _buildOverview(movie),
                      if (_people.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        _buildCastSection(),
                      ],
                      if (_images.isNotEmpty || (movie.trailerUrl?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 22),
                        _buildMediaSection(movie),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: movie == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: SizedBox(
                  height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.push(AppRoutes.seatSelection),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      'Mua vé',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _buttonFontSize(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(MovieResponse movie) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AppNetworkImage(
                  url: movie.posterUrl,
                  width: 124,
                  height: 176,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.movie,
                  backgroundColor: AppColors.cardDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _liked = !_liked),
                          icon: Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            color: _liked ? AppColors.primary : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          label: _statusLabel(movie.status),
                          color: _statusColor(movie.status),
                        ),
                        _Pill(
                          label: _ageLabel(movie.ageRating),
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                    if (movie.categories.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        movie.categories.map((item) => item.name).join(' • '),
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Phim được phổ biến đến người xem phù hợp với phân loại tuổi hiện tại.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 210;
                        return Row(
                          children: [
                            Expanded(
                              child: _HeaderActionButton(
                                label: compact ? 'Thích' : (_liked ? 'Đã thích' : 'Yêu thích'),
                                icon: _liked ? Icons.favorite : Icons.favorite_border,
                                onPressed: () => setState(() => _liked = !_liked),
                                foregroundColor: Colors.white,
                                borderColor: Colors.white.withValues(alpha: 0.16),
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeaderActionButton(
                                label: 'Trailer',
                                icon: Icons.play_circle_outline,
                                onPressed: (movie.trailerUrl?.isNotEmpty ?? false) ? _openTrailer : null,
                                foregroundColor: AppColors.secondary,
                                borderColor: AppColors.secondary.withValues(alpha: 0.5),
                                compact: compact,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(MovieResponse movie) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              title: 'Ngày khởi chiếu',
              value: _formatDate(movie.releaseDate),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatColumn(
              title: 'Thời lượng',
              value: _formatDuration(movie.duration),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatColumn(
              title: 'Ngôn ngữ',
              value: _languageLabel(movie.language),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    final score = _averageRating > 0 ? _averageRating : 0;
    final reviewCount = _reviews.length;
    final isFeatured = score >= 8;
    final bands = _ratingBands();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium_outlined, color: AppColors.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFeatured ? 'Siêu phẩm nổi bật' : 'Đánh giá cộng đồng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reviewCount > 0
                          ? '$reviewCount đánh giá từ khán giả đã xem phim'
                          : 'Chưa có đủ dữ liệu đánh giá từ khán giả',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 42),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: score.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(
                            text: '/10',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewCount > 0 ? '($reviewCount đánh giá)' : 'Chưa có đánh giá',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: bands
                      .map(
                        (band) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  band.label,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.star_border_rounded, color: Colors.white24, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 9,
                                    value: band.count,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverview(MovieResponse movie) {
    final overview = movie.description.trim();
    final isLong = overview.length > 240;
    final displayed = !_expandedOverview && isLong
        ? '${overview.substring(0, 240).trimRight()}...'
        : overview;

    return _SectionCard(
      title: 'Nội dung phim',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overview.isEmpty ? 'Chưa có mô tả cho phim này.' : displayed,
            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.7),
          ),
          if (isLong) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _expandedOverview = !_expandedOverview),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
              child: Text(_expandedOverview ? 'Thu gọn' : 'Xem thêm'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCastSection() {
    return _SectionCard(
      title: 'Diễn viên và đoàn làm phim',
      child: SizedBox(
        height: 174,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _people.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final person = _people[index];
            return SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AppNetworkImage(
                      url: person.avatarUrl,
                      width: 110,
                      height: 132,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.person_outline,
                      backgroundColor: AppColors.cardDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    person.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    person.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaSection(MovieResponse movie) {
    final mediaCount = _images.length + ((movie.trailerUrl?.isNotEmpty ?? false) ? 1 : 0);
    return _SectionCard(
      title: 'Hình ảnh và video',
      child: SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: mediaCount,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final hasTrailer = movie.trailerUrl?.isNotEmpty ?? false;
            if (hasTrailer && index == 0) {
              return _TrailerCard(
                posterUrl: movie.posterUrl,
                onTap: _openTrailer,
              );
            }
            final imageIndex = hasTrailer ? index - 1 : index;
            final image = _images[imageIndex];
            return GestureDetector(
              onTap: () => _showImagePreview(image.imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AppNetworkImage(
                  url: image.imageUrl,
                  width: 220,
                  height: 160,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.image_outlined,
                  backgroundColor: AppColors.cardDark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AppNetworkImage(
                url: url,
                fit: BoxFit.contain,
                backgroundColor: AppColors.surfaceDark,
                fallbackIcon: Icons.image_outlined,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 52,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;

  const _StatColumn({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color borderColor;
  final bool compact;

  const _HeaderActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.foregroundColor,
    required this.borderColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 12.0 : 15.0;
    final iconSize = compact ? 16.0 : 20.0;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 10 : 12,
        ),
        minimumSize: const Size(0, 52),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize),
            SizedBox(width: compact ? 5 : 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailerCard extends StatelessWidget {
  final String? posterUrl;
  final VoidCallback onTap;

  const _TrailerCard({
    required this.posterUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AppNetworkImage(
              url: posterUrl,
              width: 220,
              height: 160,
              fit: BoxFit.cover,
              fallbackIcon: Icons.play_circle_outline,
              backgroundColor: AppColors.cardDark,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: Center(
              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Trailer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBand {
  final String label;
  final double count;

  const _RatingBand({
    required this.label,
    required this.count,
  });
}
