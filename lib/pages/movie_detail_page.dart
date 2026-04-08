import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_showtime_page.dart';
import 'package:cinema_booking_system_app/pages/trailer_player_page.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/review_ai_summary_service.dart';
import 'package:cinema_booking_system_app/services/review_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:go_router/go_router.dart';

class MovieDetailPage extends StatefulWidget {
  final String movieId;

  const MovieDetailPage({super.key, required this.movieId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final AuthService _authService = AuthService.instance;
  final MovieService _movieService = MovieService.instance;
  final ReviewService _reviewService = ReviewService.instance;
  final ReviewAiSummaryService _reviewAiSummaryService =
      ReviewAiSummaryService.instance;

  MovieResponse? _movie;
  List<MoviePersonResponse> _people = const [];
  List<MovieImageResponse> _images = const [];
  List<ReviewSummaryResponse> _reviews = const [];
  final Map<String, ReviewResponse> _reviewDetails = {};
  int _reviewTotal = 0;
  double _averageRating = 0;
  String? _aiReviewSummary;
  String? _aiReviewSummaryError;
  DateTime? _aiReviewSummaryAt;
  int _aiReviewSourceCount = 0;
  bool _aiReviewSummaryLoading = false;
  bool _isLoading = true;
  bool _expandedOverview = false;
  bool _liked = false;
  String? _currentUsername;
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
        _safeCurrentUsername(),
      ]);

      if (!mounted) {
        return;
      }

      final reviewPage = results[2] as ReviewPageResponse;
      final averageRating = results[3] as double;
      setState(() {
        _movie = movie;
        _people = results[0] as List<MoviePersonResponse>;
        _images = results[1] as List<MovieImageResponse>;
        _reviews = reviewPage.items;
        _reviewTotal = reviewPage.totalElements;
        _reviewDetails.clear();
        _averageRating = averageRating;
        _currentUsername = results[4] as String?;
        _aiReviewSummary = null;
        _aiReviewSummaryError = null;
        _aiReviewSummaryAt = null;
        _aiReviewSourceCount = reviewPage.items.length;
        _aiReviewSummaryLoading = false;
        _isLoading = false;
      });
      await _loadAiReviewSummary(
        movie: movie,
        reviews: reviewPage.items,
        averageRating: averageRating,
      );
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

  Future<ReviewPageResponse> _safeReviews(String movieId) async {
    try {
      return await _reviewService.getByMovie(movieId, size: 20);
    } catch (_) {
      return const ReviewPageResponse.empty();
    }
  }

  Future<double> _safeAverageRating(String movieId) async {
    try {
      return await _reviewService.getAverageRating(movieId);
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _safeCurrentUsername() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        return null;
      }
      final user = await _authService.getCurrentUserResponse();
      final username = user?.username.trim();
      if (username == null || username.isEmpty) {
        return null;
      }
      return username;
    } catch (_) {
      return null;
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

  String _personRoleLabel(String value) {
    switch (value.toUpperCase()) {
      case 'ACTOR':
        return 'Diễn viên';
      case 'DIRECTOR':
        return 'Đạo diễn';
      case 'PRODUCER':
        return 'Nhà sản xuất';
      case 'WRITER':
        return 'Biên kịch';
      default:
        return value;
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

  Future<void> _openBookingFlow(MovieResponse movie) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingShowtimePage(
          movie: BookingMovieSnapshot(
            movieId: movie.id,
            title: movie.title,
            posterUrl: movie.posterUrl,
            ageRating: movie.ageRating,
            durationMinutes: movie.duration,
          ),
        ),
      ),
    );
  }

  List<_RatingBand> _ratingBands() {
    final reviews = _reviews;
    final total = reviews.isEmpty ? 1 : reviews.length;

    int countInRange(int min, int max) {
      return reviews
          .where((review) => review.rating >= min && review.rating <= max)
          .length;
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
    final scaled = width * 0.043;
    if (scaled < 13) {
      return 13;
    }
    if (scaled > 16) {
      return 16;
    }
    return scaled;
  }

  Future<void> _refreshReviews() async {
    final results = await Future.wait<dynamic>([
      _safeReviews(widget.movieId),
      _safeAverageRating(widget.movieId),
      _safeCurrentUsername(),
    ]);

    if (!mounted) {
      return;
    }

    final reviewPage = results[0] as ReviewPageResponse;
    final averageRating = results[1] as double;
    setState(() {
      _reviews = reviewPage.items;
      _reviewTotal = reviewPage.totalElements;
      _reviewDetails.clear();
      _averageRating = averageRating;
      _currentUsername = results[2] as String?;
      _aiReviewSummary = null;
      _aiReviewSummaryError = null;
      _aiReviewSummaryAt = null;
      _aiReviewSourceCount = reviewPage.items.length;
      _aiReviewSummaryLoading = false;
    });

    final movie = _movie;
    if (movie != null) {
      await _loadAiReviewSummary(
        movie: movie,
        reviews: reviewPage.items,
        averageRating: averageRating,
      );
    }
  }

  Future<void> _loadAiReviewSummary({
    required MovieResponse movie,
    required List<ReviewSummaryResponse> reviews,
    required double averageRating,
    bool forceRefresh = false,
  }) async {
    if (!_reviewAiSummaryService.isConfigured || reviews.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _aiReviewSummaryLoading = false;
        _aiReviewSummary = null;
        _aiReviewSummaryError = null;
        _aiReviewSummaryAt = null;
        _aiReviewSourceCount = reviews.length;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _aiReviewSummaryLoading = true;
        _aiReviewSummaryError = null;
        _aiReviewSourceCount = reviews.length;
      });
    }

    try {
      final result = await _reviewAiSummaryService.summarizeMovieReviews(
        movieId: movie.id,
        movieTitle: movie.title,
        reviews: reviews,
        averageRating: averageRating,
        forceRefresh: forceRefresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _aiReviewSummaryLoading = false;
        _aiReviewSummary = result?.summary;
        _aiReviewSummaryAt = result?.generatedAt;
        _aiReviewSourceCount = result?.sourceCount ?? reviews.length;
        _aiReviewSummaryError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _aiReviewSummaryLoading = false;
        _aiReviewSourceCount = reviews.length;
        _aiReviewSummaryError = _reviewAiSummaryService.friendlyError(error);
      });
    }
  }

  Future<void> _refreshAiReviewSummary() async {
    final movie = _movie;
    if (movie == null) {
      return;
    }
    await _loadAiReviewSummary(
      movie: movie,
      reviews: _reviews,
      averageRating: _averageRating,
      forceRefresh: true,
    );
  }

  String _formatAiSummaryTime(DateTime? value) {
    if (value == null) {
      return '--';
    }
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  ReviewSummaryResponse? _findMyReviewSummary([String? username]) {
    final current = (username ?? _currentUsername)?.trim().toLowerCase();
    if (current == null || current.isEmpty) {
      return null;
    }

    for (final review in _reviews) {
      if (review.username.trim().toLowerCase() == current) {
        return review;
      }
    }
    return null;
  }

  bool _isMyReview(ReviewSummaryResponse review) {
    final current = _currentUsername?.trim().toLowerCase();
    if (current == null || current.isEmpty) {
      return false;
    }
    return review.username.trim().toLowerCase() == current;
  }

  String _errorText(Object error, String fallback) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return fallback;
    }

    final cleaned = text.replaceFirst('Exception: ', '');
    if (cleaned.toLowerCase().contains('dioexception')) {
      return fallback;
    }
    return cleaned;
  }

  void _showMessage(String message, {Color backgroundColor = AppColors.info}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _promptLoginForReview() async {
    final shouldOpenLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Dang nhap de danh gia',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ban can dang nhap de viet binh luan va danh gia phim.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('De sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Dang nhap'),
          ),
        ],
      ),
    );

    if (shouldOpenLogin == true && mounted) {
      context.goNamed('login');
    }
  }

  Future<ReviewResponse> _loadReviewDetail(String reviewId) async {
    final cached = _reviewDetails[reviewId];
    if (cached != null) {
      return cached;
    }

    final detail = await _reviewService.getById(reviewId);
    _reviewDetails[reviewId] = detail;
    return detail;
  }

  Future<void> _submitReview({
    String? reviewId,
    required int rating,
    required String comment,
  }) async {
    final normalizedComment = comment.trim();
    if (reviewId == null) {
      await _reviewService.create(
        movieId: widget.movieId,
        rating: rating,
        comment: normalizedComment,
      );
    } else {
      await _reviewService.update(
        reviewId,
        movieId: widget.movieId,
        rating: rating,
        comment: normalizedComment,
      );
    }

    await _refreshReviews();
    _showMessage(
      reviewId == null
          ? 'Da dang danh gia thanh cong.'
          : 'Da Cập nhật đánh giá.',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _openReviewComposer() async {
    final username = _currentUsername ?? await _safeCurrentUsername();
    if (!mounted) {
      return;
    }

    if (username == null) {
      await _promptLoginForReview();
      return;
    }

    ReviewResponse? existingReview;
    final reviewSummary = _findMyReviewSummary(username);
    if (reviewSummary != null) {
      try {
        existingReview = await _loadReviewDetail(reviewSummary.id);
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage(
          _errorText(error, 'Khong the tai danh gia cua ban.'),
          backgroundColor: AppColors.error,
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewComposerSheet(
        title: existingReview == null ? 'Viet danh gia' : 'Sửa đánh giá',
        submitLabel:
            existingReview == null ? 'Dang danh gia' : 'Cập nhật đánh giá',
        initialRating: existingReview?.rating ?? 0,
        initialComment: existingReview?.comment ?? '',
        onSubmit: (rating, comment) => _submitReview(
          reviewId: existingReview?.id,
          rating: rating,
          comment: comment,
        ),
      ),
    );
  }

  Future<void> _handleWriteReview() async {
    await _openReviewComposer();
  }

  Future<void> _editReview(ReviewSummaryResponse review) async {
    try {
      final detail = await _loadReviewDetail(review.id);
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReviewComposerSheet(
          title: 'Sửa đánh giá',
          submitLabel: 'Cập nhật đánh giá',
          initialRating: detail.rating,
          initialComment: detail.comment,
          onSubmit: (rating, comment) => _submitReview(
            reviewId: detail.id,
            rating: rating,
            comment: comment,
          ),
        ),
      );
    } catch (error) {
      _showMessage(
        _errorText(error, 'Khong the tai danh gia de chinh sua.'),
        backgroundColor: AppColors.error,
      );
    }
  }

  Future<void> _deleteReview(ReviewSummaryResponse review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Xoa danh gia',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ban co chac muon xoa danh gia nay khong?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _reviewService.delete(review.id);
      await _refreshReviews();
      _showMessage(
        'Da xoa danh gia.',
        backgroundColor: AppColors.success,
      );
    } catch (error) {
      _showMessage(
        _errorText(error, 'Khong the xoa danh gia.'),
        backgroundColor: AppColors.error,
      );
    }
  }

  Future<void> _showReviewDetails(ReviewSummaryResponse review) async {
    try {
      final detail = await _loadReviewDetail(review.id);
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReviewDetailSheet(
          review: detail,
          createdAtLabel: _formatReviewDate(detail.createdAt),
        ),
      );
    } catch (error) {
      _showMessage(
        _errorText(error, 'Khong the tai chi tiet danh gia.'),
        backgroundColor: AppColors.error,
      );
    }
  }

  String _formatReviewDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Moi cap nhat';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return _formatDate(value.split('T').first);
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  bool _shouldShowReadMore(ReviewSummaryResponse review) {
    final comment = review.commentTruncated.trim();
    if (comment.isEmpty) {
      return false;
    }
    return comment.endsWith('...') ||
        comment.endsWith('…') ||
        comment.length >= 110;
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null || movie == null
              ? _ErrorState(
                  message: _error ?? 'Không tải được thông tin phim',
                  onRetry: _loadMovie)
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
                      if (_images.isNotEmpty ||
                          (movie.trailerUrl?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 22),
                        _buildMediaSection(movie),
                      ],
                      const SizedBox(height: 22),
                      _buildReviewsSection(),
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
                    onPressed: () => _openBookingFlow(movie),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
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
                              fontSize: 24,
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
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Phim được phổ biến đến người xem phù hợp với phân loại tuổi hiện tại.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
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
                                label: compact
                                    ? 'Thích'
                                    : (_liked ? 'Đã thích' : 'Yêu thích'),
                                icon: _liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                onPressed: () =>
                                    setState(() => _liked = !_liked),
                                foregroundColor: Colors.white,
                                borderColor:
                                    Colors.white.withValues(alpha: 0.16),
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeaderActionButton(
                                label: 'Trailer',
                                icon: Icons.play_circle_outline,
                                onPressed:
                                    (movie.trailerUrl?.isNotEmpty ?? false)
                                        ? _openTrailer
                                        : null,
                                foregroundColor: AppColors.secondary,
                                borderColor:
                                    AppColors.secondary.withValues(alpha: 0.5),
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
    final reviewCount = _reviewTotal;
    final isFeatured = score >= 8;
    final bands = _ratingBands();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
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
                child: const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.secondary),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reviewCount > 0
                          ? '$reviewCount đánh giá từ khán giả đã xem phim'
                          : 'Chưa có đủ dữ liệu đánh giá từ khán giả',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
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
                    const Icon(Icons.star_rounded,
                        color: AppColors.secondary, size: 42),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: score.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(
                            text: '/10',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewCount > 0
                          ? '($reviewCount đánh giá)'
                          : 'Chưa có đánh giá',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
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
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.star_border_rounded,
                                  color: Colors.white24, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 9,
                                    value: band.count,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.08),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.secondary),
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

  Widget _buildAiSummaryCard() {
    final summaryText = _aiReviewSummary?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tom tat AI (Gemini)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    _aiReviewSummaryLoading ? null : _refreshAiReviewSummary,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lam moi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_aiReviewSummaryLoading)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dang tong hop review...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            )
          else if (summaryText.isNotEmpty)
            Text(
              summaryText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.45,
              ),
            )
          else
            const Text(
              'Chua co du du lieu de tao tom tat AI.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          if (!_aiReviewSummaryLoading && _aiReviewSummaryError != null) ...[
            const SizedBox(height: 8),
            Text(
              _aiReviewSummaryError!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (!_aiReviewSummaryLoading) ...[
            const SizedBox(height: 8),
            Text(
              'Nguon $_aiReviewSourceCount review - cap nhat ${_formatAiSummaryTime(_aiReviewSummaryAt)}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final myReview = _findMyReviewSummary();

    return _SectionCard(
      title: 'Bình luận khán giả',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _reviews.isEmpty
                      ? 'Chưa có bình luận nào. Hãy là người đầu tiên đánh giá phim này.'
                      : 'Các nhận xét được hiển thị từ đánh giá thực tế của khán giả.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _handleWriteReview,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  myReview == null ? 'Viết đánh giá' : 'Sửa đánh giá',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_reviewAiSummaryService.isConfigured && _reviews.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildAiSummaryCard(),
          ],
          if (_reviews.isEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Đăng nhập để viết review và xem ý kiến của bạn hiện ngay trong danh sách này.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            for (var index = 0; index < _reviews.length; index++) ...[
              _ReviewCard(
                review: _reviews[index],
                isOwner: _isMyReview(_reviews[index]),
                dateLabel: _formatReviewDate(_reviews[index].createdAt),
                showReadMore: _shouldShowReadMore(_reviews[index]),
                onReadMore: () => _showReviewDetails(_reviews[index]),
                onEdit: () => _editReview(_reviews[index]),
                onDelete: () => _deleteReview(_reviews[index]),
              ),
              if (index < _reviews.length - 1) const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOverview(MovieResponse movie) {
    final overview = movie.description.trim();
    final words = overview.split(RegExp(r'\s+'));
    final isLong = words.length > 50;
    final displayed = !_expandedOverview && isLong
        ? '${words.take(50).join(' ')}...'
        : overview;

    return _SectionCard(
      title: 'Nội dung phim',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overview.isEmpty ? 'Chưa có mô tả cho phim này.' : displayed,
            style: const TextStyle(
                color: Colors.white70, fontSize: 16, height: 1.7),
          ),
          if (isLong) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  setState(() => _expandedOverview = !_expandedOverview),
              child: Text(
                _expandedOverview ? 'Thu gọn ▲' : 'Xem thêm ▼',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        height: 198,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _people.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final person = _people[index];
            return SizedBox(
              width: 114,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AppNetworkImage(
                      url: person.avatarUrl,
                      width: 114,
                      height: 128,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.person_outline,
                      backgroundColor: AppColors.cardDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    person.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _personRoleLabel(person.role),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.2,
                    ),
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
    final mediaCount =
        _images.length + ((movie.trailerUrl?.isNotEmpty ?? false) ? 1 : 0);
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
      builder: (dialogContext) => Dialog(
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
                onPressed: () => Navigator.of(dialogContext).pop(),
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
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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
    final fontSize = compact ? 11.0 : 13.0;
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
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 48),
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
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewSummaryResponse review;
  final bool isOwner;
  final String dateLabel;
  final bool showReadMore;
  final VoidCallback onReadMore;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.isOwner,
    required this.dateLabel,
    required this.showReadMore,
    required this.onReadMore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final comment = review.commentTruncated.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewAvatar(username: review.username),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username.isEmpty ? 'Nguoi dung' : review.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ScoreBadge(score: review.rating),
              if (isOwner) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  tooltip: 'Tuy chon danh gia',
                  color: AppColors.surfaceDark,
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                      return;
                    }
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Sua'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Xoa'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            comment.isEmpty ? 'Nguoi dung chua de lai noi dung.' : comment,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (showReadMore) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReadMore,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xem them',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  final String username;

  const _ReviewAvatar({required this.username});

  @override
  Widget build(BuildContext context) {
    final trimmed = username.trim();
    final initial =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.secondary, size: 16),
          const SizedBox(width: 4),
          Text(
            '$score/10',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewComposerSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final int initialRating;
  final String initialComment;
  final Future<void> Function(int rating, String comment) onSubmit;

  const _ReviewComposerSheet({
    required this.title,
    required this.submitLabel,
    required this.initialRating,
    required this.initialComment,
    required this.onSubmit,
  });

  @override
  State<_ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<_ReviewComposerSheet> {
  late final TextEditingController _commentController;
  late int _selectedRating;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.initialComment);
    _selectedRating = widget.initialRating;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (_selectedRating < 1 || _selectedRating > 10) {
      setState(() => _error = 'Vui lòng chọn số điểm từ 1 đến 10.');
      return;
    }
    if (comment.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung đánh giá.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(_selectedRating, comment);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cham diem phim tu 1 den 10 va de lai nhan xet cua ban.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  10,
                  (index) => _RatingChoiceChip(
                    score: index + 1,
                    selected: _selectedRating == index + 1,
                    onTap: () => setState(() => _selectedRating = index + 1),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nội dung cảm nhận của bạn về bộ phim...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.submitLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingChoiceChip extends StatelessWidget {
  final int score;
  final bool selected;
  final VoidCallback onTap;

  const _RatingChoiceChip({
    required this.score,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 16,
              color: selected ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: TextStyle(
                color: selected ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDetailSheet extends StatelessWidget {
  final ReviewResponse review;
  final String createdAtLabel;

  const _ReviewDetailSheet({
    required this.review,
    required this.createdAtLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewAvatar(username: review.username),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.username.isEmpty
                              ? 'Nguoi dung'
                              : review.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAtLabel,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ScoreBadge(score: review.rating),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Nội dung đánh giá',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                review.comment.trim().isEmpty
                    ? 'Người dùng chưa để lại nội dung.'
                    : review.comment.trim(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
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
