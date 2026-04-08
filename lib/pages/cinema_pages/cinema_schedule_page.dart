import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_detail_view.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_models.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_utils.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:cinema_booking_system_app/services/room_seat_service.dart';
import 'package:cinema_booking_system_app/services/showtime_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CinemaSchedulePage extends StatefulWidget {
  final String cinemaId;

  const CinemaSchedulePage({
    super.key,
    required this.cinemaId,
  });

  @override
  State<CinemaSchedulePage> createState() => _CinemaSchedulePageState();
}

class _CinemaSchedulePageState extends State<CinemaSchedulePage> {
  final CinemaService _cinemaService = CinemaService.instance;
  final ShowtimeService _showtimeService = ShowtimeService.instance;
  final RoomService _roomService = RoomService.instance;

  CinemaResponse? _cinema;
  DateTime _selectedDate = DateTime.now();
  CinemaTimeFilter _selectedFilter = CinemaTimeFilter.all;
  List<ShowtimeSummaryResponse> _showtimes = const [];
  List<MovieResponse> _movies = const [];
  Map<String, int> _roomTotalSeatsById = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCinemaSchedule();
  }

  Future<CinemaResponse?> _tryGetCinema() async {
    try {
      return await _cinemaService.getById(widget.cinemaId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCinemaSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await Future.wait<dynamic>([
        _tryGetCinema(),
        _showtimeService.getByCinema(widget.cinemaId, date: date),
        _cinemaService
            .getMoviesByCinema(widget.cinemaId, date: date)
            .catchError((_) => <MovieResponse>[]),
        _roomService
            .getByCinema(widget.cinemaId)
            .catchError((_) => <RoomResponse>[]),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _cinema = results[0] as CinemaResponse?;
        _showtimes = results[1] as List<ShowtimeSummaryResponse>;
        _movies = results[2] as List<MovieResponse>;
        final rooms = results[3] as List<RoomResponse>;
        _roomTotalSeatsById = {
          for (final room in rooms)
            if (room.id.isNotEmpty) room.id: room.totalSeats,
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Không thể tải suất chiếu của rạp này.';
      });
    }
  }

  String get _appBarTitle {
    if (_cinema?.name.isNotEmpty == true) {
      return _cinema!.name;
    }
    if (_showtimes.isNotEmpty && _showtimes.first.cinemaName.isNotEmpty) {
      return _showtimes.first.cinemaName;
    }
    return 'Lịch chiếu rạp';
  }

  List<ShowtimeSummaryResponse> get _filteredShowtimes {
    final items = [..._showtimes]..sort((a, b) =>
        parseShowtimeDateTime(a.startTime)
            .compareTo(parseShowtimeDateTime(b.startTime)));

    if (_selectedFilter == CinemaTimeFilter.all) {
      return items;
    }

    return items.where((showtime) {
      final hour = parseShowtimeDateTime(showtime.startTime).hour;
      return switch (_selectedFilter) {
        CinemaTimeFilter.all => true,
        CinemaTimeFilter.noon => hour >= 12 && hour < 15,
        CinemaTimeFilter.afternoon => hour >= 15 && hour < 18,
        CinemaTimeFilter.evening => hour >= 18 || hour < 1,
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
      final items = [...entry.value]..sort((a, b) =>
          parseShowtimeDateTime(a.startTime)
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
    return Scaffold(
      backgroundColor: cinemaPageBackground,
      appBar: AppBar(
        backgroundColor: cinemaPageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          _appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: cinemaPageText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: cinemaPageAccent),
      );
    }

    if (_error != null) {
      return CinemaStatusView(
        icon: Icons.error_outline_rounded,
        message: _error!,
        onRetry: _loadCinemaSchedule,
      );
    }

    return CinemaDetailView(
      selectedDate: _selectedDate,
      onDateChanged: (date) {
        setState(() => _selectedDate = date);
        _loadCinemaSchedule();
      },
      selectedFilter: _selectedFilter,
      onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
      movieGroups: _movieGroups,
      roomTotalSeatsById: _roomTotalSeatsById,
      onRefresh: _loadCinemaSchedule,
    );
  }
}
