import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/showtime_service.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/pages/seat_selection_page.dart';

/// Trang Lịch Chiếu — tìm theo phim hoặc theo rạp
class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Chiếu'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.movie_outlined), text: 'Theo Phim'),
            Tab(icon: Icon(Icons.location_on_outlined), text: 'Theo Rạp'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ByMovieTab(),
          _ByCinemaTab(),
        ],
      ),
    );
  }
}

// ── Dải chọn ngày nằm ngang ─────────────────────────────────────────────────
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(14, (i) => today.add(Duration(days: i)));
    final dayFmt = DateFormat('EEE', 'vi');
    final dateFmt = DateFormat('dd/MM');

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: dates.length,
        itemBuilder: (_, i) {
          final d = dates[i];
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;

          return GestureDetector(
            onTap: () => onDateSelected(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    i == 0 ? 'Hôm nay' : dayFmt.format(d),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFmt.format(d),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
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

// ── Tab: Theo Phim ──────────────────────────────────────────────────────────
class _ByMovieTab extends StatefulWidget {
  const _ByMovieTab();

  @override
  State<_ByMovieTab> createState() => _ByMovieTabState();
}

class _ByMovieTabState extends State<_ByMovieTab>
    with AutomaticKeepAliveClientMixin {
  final _movieService = MovieService.instance;
  final _showtimeService = ShowtimeService.instance;

  List<MovieModel> _movies = [];
  bool _loadingMovies = true;
  String? _errorMovies;

  // Phim được chọn hiện tại
  MovieModel? _selectedMovie;
  DateTime _selectedDate = DateTime.now();

  // Suất chiếu theo phim
  List<ShowtimeSummaryResponse> _showtimes = [];
  bool _loadingShowtimes = false;
  String? _errorShowtimes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _loadingMovies = true;
      _errorMovies = null;
    });
    try {
      final movies = await _movieService.getNowShowing(page: 1);
      setState(() {
        _movies = movies;
        _loadingMovies = false;
        if (movies.isNotEmpty) {
          _selectedMovie = movies.first;
          _loadShowtimesByMovie();
        }
      });
    } catch (e) {
      setState(() {
        _loadingMovies = false;
        _errorMovies = 'Không thể tải danh sách phim: $e';
      });
    }
  }

  Future<void> _loadShowtimesByMovie() async {
    if (_selectedMovie == null) return;
    setState(() {
      _loadingShowtimes = true;
      _errorShowtimes = null;
    });
    try {
      final dateFmt = DateFormat('yyyy-MM-dd');
      final showtimes = await _showtimeService.getByMovie(
        _selectedMovie!.id,
        date: dateFmt.format(_selectedDate),
      );
      setState(() {
        _showtimes = showtimes;
        _loadingShowtimes = false;
      });
    } catch (e) {
      setState(() {
        _loadingShowtimes = false;
        _errorShowtimes = 'Không thể tải suất chiếu: $e';
      });
    }
  }

  void _onMovieSelected(MovieModel movie) {
    setState(() => _selectedMovie = movie);
    _loadShowtimesByMovie();
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _loadShowtimesByMovie();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loadingMovies) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMovies != null) {
      return _ErrorView(message: _errorMovies!, onRetry: _loadMovies);
    }

    if (_movies.isEmpty) {
      return const _EmptyView(message: 'Không có phim đang chiếu');
    }

    return Column(
      children: [
        // ── Movie selector (horizontal scroll) ──
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _movies.length,
            itemBuilder: (_, i) {
              final m = _movies[i];
              final isSelected = m.id == _selectedMovie?.id;
              return GestureDetector(
                onTap: () => _onMovieSelected(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: m.posterUrl.isNotEmpty
                            ? Image.network(
                                m.posterUrl,
                                width: 80,
                                height: 95,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 95,
                                  color: AppColors.dividerDark,
                                  child: const Icon(Icons.movie, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 95,
                                color: AppColors.dividerDark,
                                child: const Icon(Icons.movie, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // ── Date selector ──
        _DateSelector(
          selectedDate: _selectedDate,
          onDateSelected: _onDateChanged,
        ),

        const Divider(height: 1),

        // ── Showtime list ──
        Expanded(
          child: _loadingShowtimes
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorShowtimes != null
                  ? _ErrorView(
                      message: _errorShowtimes!,
                      onRetry: _loadShowtimesByMovie,
                    )
                  : _showtimes.isEmpty
                      ? const _EmptyView(message: 'Không có suất chiếu')
                      : _ShowtimeListByMovie(
                          movie: _selectedMovie!,
                          showtimes: _showtimes,
                        ),
        ),
      ],
    );
  }
}

// ── Hiển thị danh sách suất chiếu nhóm theo rạp (cho tab Theo Phim) ────────
class _ShowtimeListByMovie extends StatelessWidget {
  final MovieModel movie;
  final List<ShowtimeSummaryResponse> showtimes;

  const _ShowtimeListByMovie({
    required this.movie,
    required this.showtimes,
  });

  @override
  Widget build(BuildContext context) {
    // Nhóm theo cinemaName
    final grouped = <String, List<ShowtimeSummaryResponse>>{};
    for (final s in showtimes) {
      grouped.putIfAbsent(s.cinemaName, () => []).add(s);
    }

    final cinemaNames = grouped.keys.toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // parent sẽ handle
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cinemaNames.length,
        itemBuilder: (_, i) {
          final cinemaName = cinemaNames[i];
          final cinemaShowtimes = grouped[cinemaName]!;
          return _CinemaShowtimeCard(
            cinemaName: cinemaName,
            showtimes: cinemaShowtimes,
          );
        },
      ),
    );
  }
}

class _CinemaShowtimeCard extends StatelessWidget {
  final String cinemaName;
  final List<ShowtimeSummaryResponse> showtimes;

  const _CinemaShowtimeCard({
    required this.cinemaName,
    required this.showtimes,
  });

  String _formatTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  String _formatPrice(double price) {
    final fmt = NumberFormat('#,###', 'vi');
    return '${fmt.format(price)}đ';
  }

  @override
  Widget build(BuildContext context) {
    // Nhóm theo roomName
    final byRoom = <String, List<ShowtimeSummaryResponse>>{};
    for (final s in showtimes) {
      byRoom.putIfAbsent(s.roomName, () => []).add(s);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cinema header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.theaters, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cinemaName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Showtimes per room
            ...byRoom.entries.map((entry) {
              final roomName = entry.key;
              final roomShowtimes = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          roomName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: roomShowtimes.map((s) {
                        final isBookable = s.bookable;
                        return GestureDetector(
                          onTap: isBookable
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SeatSelectionPage(),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isBookable
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isBookable
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _formatTime(s.startTime),
                                  style: TextStyle(
                                    color: isBookable
                                        ? AppColors.primary
                                        : Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(s.basePrice),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isBookable
                                        ? AppColors.secondary
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${s.availableSeats} ghế',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: s.availableSeats > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Theo Rạp ───────────────────────────────────────────────────────────
class _ByCinemaTab extends StatefulWidget {
  const _ByCinemaTab();

  @override
  State<_ByCinemaTab> createState() => _ByCinemaTabState();
}

class _ByCinemaTabState extends State<_ByCinemaTab>
    with AutomaticKeepAliveClientMixin {
  final _cinemaService = CinemaService.instance;
  final _showtimeService = ShowtimeService.instance;

  List<CinemaResponse> _cinemas = [];
  bool _loadingCinemas = true;
  String? _errorCinemas;

  CinemaResponse? _selectedCinema;
  DateTime _selectedDate = DateTime.now();

  List<ShowtimeSummaryResponse> _showtimes = [];
  bool _loadingShowtimes = false;
  String? _errorShowtimes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  Future<void> _loadCinemas() async {
    setState(() {
      _loadingCinemas = true;
      _errorCinemas = null;
    });
    try {
      final cinemas = await _cinemaService.getAll();
      setState(() {
        _cinemas = cinemas;
        _loadingCinemas = false;
        if (cinemas.isNotEmpty) {
          _selectedCinema = cinemas.first;
          _loadShowtimesByCinema();
        }
      });
    } catch (e) {
      setState(() {
        _loadingCinemas = false;
        _errorCinemas = 'Không thể tải danh sách rạp: $e';
      });
    }
  }

  Future<void> _loadShowtimesByCinema() async {
    if (_selectedCinema == null) return;
    setState(() {
      _loadingShowtimes = true;
      _errorShowtimes = null;
    });
    try {
      final dateFmt = DateFormat('yyyy-MM-dd');
      final showtimes = await _showtimeService.getByCinema(
        _selectedCinema!.id,
        date: dateFmt.format(_selectedDate),
      );
      setState(() {
        _showtimes = showtimes;
        _loadingShowtimes = false;
      });
    } catch (e) {
      setState(() {
        _loadingShowtimes = false;
        _errorShowtimes = 'Không thể tải suất chiếu: $e';
      });
    }
  }

  void _onCinemaSelected(CinemaResponse cinema) {
    setState(() => _selectedCinema = cinema);
    _loadShowtimesByCinema();
  }

  void _onDateChanged(DateTime date) {
    setState(() => _selectedDate = date);
    _loadShowtimesByCinema();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loadingCinemas) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorCinemas != null) {
      return _ErrorView(message: _errorCinemas!, onRetry: _loadCinemas);
    }

    if (_cinemas.isEmpty) {
      return const _EmptyView(message: 'Không có rạp nào');
    }

    return Column(
      children: [
        // ── Cinema selector (horizontal chips) ──
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _cinemas.length,
            itemBuilder: (_, i) {
              final c = _cinemas[i];
              final isSelected = c.id == _selectedCinema?.id;
              return GestureDetector(
                onTap: () => _onCinemaSelected(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade700,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Cinema info ──
        if (_selectedCinema != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _selectedCinema!.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_selectedCinema!.hotline != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCinema!.hotline!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 4),
        const Divider(height: 1),

        // ── Date selector ──
        _DateSelector(
          selectedDate: _selectedDate,
          onDateSelected: _onDateChanged,
        ),

        const Divider(height: 1),

        // ── Showtime list grouped by movie ──
        Expanded(
          child: _loadingShowtimes
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : _errorShowtimes != null
                  ? _ErrorView(
                      message: _errorShowtimes!,
                      onRetry: _loadShowtimesByCinema,
                    )
                  : _showtimes.isEmpty
                      ? const _EmptyView(message: 'Không có suất chiếu')
                      : _ShowtimeListByCinema(showtimes: _showtimes),
        ),
      ],
    );
  }
}

// ── Hiển thị danh sách suất chiếu nhóm theo phim (cho tab Theo Rạp) ────────
class _ShowtimeListByCinema extends StatelessWidget {
  final List<ShowtimeSummaryResponse> showtimes;

  const _ShowtimeListByCinema({required this.showtimes});

  @override
  Widget build(BuildContext context) {
    // Nhóm theo movieTitle
    final grouped = <String, List<ShowtimeSummaryResponse>>{};
    for (final s in showtimes) {
      grouped.putIfAbsent(s.movieTitle, () => []).add(s);
    }

    final movieTitles = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movieTitles.length,
      itemBuilder: (_, i) {
        final title = movieTitles[i];
        final movieShowtimes = grouped[title]!;
        final first = movieShowtimes.first;

        return _MovieShowtimeCard(
          movieTitle: title,
          posterUrl: first.posterUrl,
          durationMinutes: first.durationMinutes,
          showtimes: movieShowtimes,
        );
      },
    );
  }
}

class _MovieShowtimeCard extends StatelessWidget {
  final String movieTitle;
  final String? posterUrl;
  final int durationMinutes;
  final List<ShowtimeSummaryResponse> showtimes;

  const _MovieShowtimeCard({
    required this.movieTitle,
    this.posterUrl,
    required this.durationMinutes,
    required this.showtimes,
  });

  String _formatTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  String _formatPrice(double price) {
    final fmt = NumberFormat('#,###', 'vi');
    return '${fmt.format(price)}đ';
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    // Nhóm theo roomName
    final byRoom = <String, List<ShowtimeSummaryResponse>>{};
    for (final s in showtimes) {
      byRoom.putIfAbsent(s.roomName, () => []).add(s);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterUrl != null
                      ? Image.network(
                          posterUrl!,
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 70,
                            color: AppColors.dividerDark,
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 70,
                          color: AppColors.dividerDark,
                          child: const Icon(Icons.movie, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movieTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(durationMinutes),
                            style: const TextStyle(
                                color: AppColors.secondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Showtimes per room
            ...byRoom.entries.map((entry) {
              final roomName = entry.key;
              final roomShowtimes = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          roomName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: roomShowtimes.map((s) {
                        final isBookable = s.bookable;
                        return GestureDetector(
                          onTap: isBookable
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SeatSelectionPage(),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isBookable
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isBookable
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _formatTime(s.startTime),
                                  style: TextStyle(
                                    color: isBookable
                                        ? AppColors.primary
                                        : Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(s.basePrice),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isBookable
                                        ? AppColors.secondary
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${s.availableSeats} ghế',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: s.availableSeats > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
