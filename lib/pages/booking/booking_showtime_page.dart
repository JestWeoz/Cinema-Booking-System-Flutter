import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_seat_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/services/showtime_service.dart';

class BookingShowtimePage extends StatefulWidget {
  final BookingMovieSnapshot movie;

  const BookingShowtimePage({
    super.key,
    required this.movie,
  });

  @override
  State<BookingShowtimePage> createState() => _BookingShowtimePageState();
}

class _BookingShowtimePageState extends State<BookingShowtimePage> {
  final ShowtimeService _showtimeService = ShowtimeService.instance;
  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  List<ShowtimeSummaryResponse> _showtimes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(
      6,
      (index) => DateTime(now.year, now.month, now.day + index),
    );
    _selectedDate = _dates.first;
    _loadShowtimes();
  }

  String get _selectedDateIso =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _loadShowtimes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final showtimes = await _showtimeService.getByMovie(
        widget.movie.movieId,
        date: _selectedDateIso,
      );
      showtimes.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _showtimes = showtimes.where((item) => item.bookable).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được suất chiếu: $e';
      });
    }
  }

  Map<String, List<ShowtimeSummaryResponse>> get _groupedByCinema {
    final grouped = <String, List<ShowtimeSummaryResponse>>{};
    for (final item in _showtimes) {
      grouped.putIfAbsent(item.cinemaName, () => []).add(item);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      for (final entry in entries)
        entry.key: entry.value
          ..sort((a, b) => a.startTime.compareTo(b.startTime)),
    };
  }

  void _openSeatSelection(ShowtimeSummaryResponse showtime) {
    final draft = BookingFlowDraft(
      movie: widget.movie,
      showtime: showtime,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingSeatPage(draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BookingPageScaffold(
      title: 'Chọn suất chiếu',
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadShowtimes,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            BookingMovieStrip(
              title: widget.movie.title,
              posterUrl: widget.movie.posterUrl,
              ageRating: widget.movie.ageRating,
              subtitle: 'Chọn ngày xem và suất chiếu theo từng rạp phù hợp.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final date = _dates[index];
                  final selected = date == _selectedDate;
                  final isToday = index == 0;
                  return InkWell(
                    onTap: () {
                      if (selected) return;
                      setState(() => _selectedDate = date);
                      _loadShowtimes();
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 86,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.white12,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            bookingFormatDate(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isToday ? 'H.nay' : bookingFormatWeekday(date),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              BookingSectionCard(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _loadShowtimes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại'),
                    ),
                  ],
                ),
              )
            else if (_showtimes.isEmpty)
              const BookingSectionCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 34),
                  child: Column(
                    children: [
                      Icon(Icons.movie_filter_outlined,
                          color: Colors.white38, size: 42),
                      SizedBox(height: 10),
                      Text(
                        'Ngày này chưa có suất chiếu phù hợp.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Rạp đang chiếu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${_groupedByCinema.length} rạp',
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._groupedByCinema.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: BookingSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${entry.value.length} suất chiếu đang mở bán',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: entry.value.map((showtime) {
                            final soldOut = showtime.availableSeats <= 0 ||
                                !showtime.bookable;
                            return InkWell(
                              onTap: soldOut
                                  ? null
                                  : () => _openSeatSelection(showtime),
                              borderRadius: BorderRadius.circular(18),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 138,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: soldOut
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: soldOut
                                        ? Colors.white10
                                        : AppColors.primary
                                            .withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookingFormatTime(showtime.startTime),
                                      style: TextStyle(
                                        color: soldOut
                                            ? Colors.white38
                                            : Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bookingFormatTime(showtime.endTime),
                                      style: TextStyle(
                                        color: soldOut
                                            ? Colors.white30
                                            : Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      bookingFormatCurrency(showtime.basePrice),
                                      style: TextStyle(
                                        color: soldOut
                                            ? Colors.white30
                                            : AppColors.secondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      soldOut
                                          ? 'Hết ghế'
                                          : 'Còn ${showtime.availableSeats} ghế',
                                      style: TextStyle(
                                        color: soldOut
                                            ? Colors.white30
                                            : Colors.white60,
                                        fontSize: 11,
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
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
