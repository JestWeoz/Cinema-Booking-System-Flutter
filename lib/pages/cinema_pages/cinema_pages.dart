import 'dart:async';

import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_detail_view.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_list_view.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_models.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_utils.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:cinema_booking_system_app/services/showtime_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CinemaPages extends StatefulWidget {
  const CinemaPages({super.key});

  @override
  State<CinemaPages> createState() => _CinemaPagesState();
}

class _CinemaPagesState extends State<CinemaPages> {
  final _cinemaService = CinemaService.instance;
  final _showtimeService = ShowtimeService.instance;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<CinemaResponse> _cinemas = [];
  bool _loading = true;
  String? _error;
  String _keyword = '';
  String _selectedBrand = '__all__';
  final Set<String> _favoriteCinemaIds = <String>{};

  CinemaResponse? _selectedCinema;
  DateTime _selectedDate = DateTime.now();
  CinemaTimeFilter _selectedFilter = CinemaTimeFilter.all;
  List<ShowtimeSummaryResponse> _showtimes = [];
  List<MovieResponse> _movies = [];
  bool _detailLoading = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCinemas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cinemas = await _cinemaService.getAll();
      cinemas.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _cinemas = cinemas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không thể tải danh sách rạp.';
      });
    }
  }

  Future<void> _loadCinemaDetail() async {
    final cinema = _selectedCinema;
    if (cinema == null) return;

    setState(() {
      _detailLoading = true;
      _detailError = null;
    });

    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await Future.wait([
        _showtimeService.getByCinema(cinema.id, date: date),
        _cinemaService.getMoviesByCinema(cinema.id, date: date),
      ]);

      if (!mounted) return;
      setState(() {
        _showtimes = results[0] as List<ShowtimeSummaryResponse>;
        _movies = results[1] as List<MovieResponse>;
        _detailLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detailLoading = false;
        _detailError = 'Không thể tải lịch chiếu.';
      });
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _keyword = value.trim().toLowerCase());
    });
  }

  Future<void> _openDirection(CinemaResponse cinema) async {
    final query = Uri.encodeComponent('${cinema.name} ${cinema.address}');
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  void _openCinema(CinemaResponse cinema) {
    setState(() {
      _selectedCinema = cinema;
      _selectedDate = DateTime.now();
      _selectedFilter = CinemaTimeFilter.all;
    });
    _loadCinemaDetail();
  }

  void _closeCinemaDetail() {
    setState(() {
      _selectedCinema = null;
      _showtimes = [];
      _movies = [];
      _detailError = null;
    });
  }

  List<CinemaResponse> get _filteredCinemas {
    return _cinemas.where((cinema) {
      final brandOk =
          _selectedBrand == '__all__' || cinemaBrandOf(cinema) == _selectedBrand;
      final keyword = _keyword;
      final textOk = keyword.isEmpty ||
          cinema.name.toLowerCase().contains(keyword) ||
          cinema.address.toLowerCase().contains(keyword);
      return brandOk && textOk;
    }).toList();
  }

  List<CinemaBrandItem> get _brands {
    final seen = <String>{};
    final items = <CinemaBrandItem>[
      const CinemaBrandItem(key: '__all__', label: 'Đề xuất'),
    ];

    for (final cinema in _cinemas) {
      final brand = cinemaBrandOf(cinema);
      if (seen.add(brand)) {
        items.add(CinemaBrandItem(
          key: brand,
          label: brand,
          logoUrl: cinema.logoUrl,
        ));
      }
    }
    return items;
  }

  List<ShowtimeSummaryResponse> get _filteredShowtimes {
    final items = [..._showtimes]
      ..sort((a, b) => parseShowtimeDateTime(a.startTime)
          .compareTo(parseShowtimeDateTime(b.startTime)));

    if (_selectedFilter == CinemaTimeFilter.all) return items;

    return items.where((showtime) {
      final hour = parseShowtimeDateTime(showtime.startTime).hour;
      return switch (_selectedFilter) {
        CinemaTimeFilter.all => true,
        CinemaTimeFilter.day => hour >= 9 && hour < 15,
        CinemaTimeFilter.evening => hour >= 15 && hour < 21,
        CinemaTimeFilter.late => hour >= 21 || hour < 2,
      };
    }).toList();
  }

  List<CinemaMovieGroup> get _movieGroups {
    final movieMap = {for (final movie in _movies) movie.id: movie};
    final grouped = <String, List<ShowtimeSummaryResponse>>{};

    for (final showtime in _filteredShowtimes) {
      final key =
          showtime.movieId.isNotEmpty ? showtime.movieId : showtime.movieTitle;
      grouped.putIfAbsent(key, () => []).add(showtime);
    }

    final groups = grouped.entries.map((entry) {
      final items = [...entry.value]
        ..sort((a, b) => parseShowtimeDateTime(a.startTime)
            .compareTo(parseShowtimeDateTime(b.startTime)));
      return CinemaMovieGroup(
        movieId: entry.key,
        movie: movieMap[entry.key],
        showtimes: items,
      );
    }).toList();

    groups.sort((a, b) => parseShowtimeDateTime(a.showtimes.first.startTime)
        .compareTo(parseShowtimeDateTime(b.showtimes.first.startTime)));

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final showingDetail = _selectedCinema != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed:
              showingDetail ? _closeCinemaDetail : () => context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          showingDetail ? _selectedCinema!.name : 'Chọn rạp',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedCinema == null) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return CinemaStatusView(
          icon: Icons.error_outline_rounded,
          message: _error!,
          onRetry: _loadCinemas,
        );
      }
      return CinemaListView(
        key: const ValueKey('cinema-list'),
        searchController: _searchController,
        onSearchChanged: _handleSearchChanged,
        brands: _brands,
        selectedBrand: _selectedBrand,
        onBrandChanged: (value) => setState(() => _selectedBrand = value),
        cinemas: _filteredCinemas,
        favoriteCinemaIds: _favoriteCinemaIds,
        onFavoriteToggle: (id) => setState(() {
          if (_favoriteCinemaIds.contains(id)) {
            _favoriteCinemaIds.remove(id);
          } else {
            _favoriteCinemaIds.add(id);
          }
        }),
        onRefresh: _loadCinemas,
        onOpenCinema: _openCinema,
        onOpenDirection: _openDirection,
      );
    }

    if (_detailLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_detailError != null) {
      return CinemaStatusView(
        icon: Icons.error_outline_rounded,
        message: _detailError!,
        onRetry: _loadCinemaDetail,
      );
    }

    return CinemaDetailView(
      key: ValueKey('cinema-detail-${_selectedCinema!.id}'),
      selectedDate: _selectedDate,
      onDateChanged: (date) {
        setState(() => _selectedDate = date);
        _loadCinemaDetail();
      },
      selectedFilter: _selectedFilter,
      onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
      movieGroups: _movieGroups,
      onRefresh: _loadCinemaDetail,
    );
  }
}
