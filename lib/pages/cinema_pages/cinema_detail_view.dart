import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_seat_page.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_models.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_utils.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CinemaDetailView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final CinemaTimeFilter selectedFilter;
  final ValueChanged<CinemaTimeFilter> onFilterChanged;
  final List<CinemaMovieGroup> movieGroups;
  final Map<String, int> roomTotalSeatsById;
  final Future<void> Function() onRefresh;

  const CinemaDetailView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.movieGroups,
    required this.roomTotalSeatsById,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final now = DateTime.now();
              final date = DateTime(now.year, now.month, now.day + index);
              final selected = isSameDate(date, selectedDate);
              return GestureDetector(
                onTap: () => onDateChanged(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 92,
                  decoration: BoxDecoration(
                    color: selected ? cinemaPageAccent : cinemaPageCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? cinemaPageAccent : cinemaPageBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd/MM').format(date),
                        style: TextStyle(
                          color: selected ? Colors.white : cinemaPageText,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        index == 0 ? 'H.nay' : weekdayLabel(date),
                        style: TextStyle(
                          color: selected ? Colors.white : cinemaPageMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: CinemaTimeFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final filter = CinemaTimeFilter.values[index];
              final selected = filter == selectedFilter;
              return GestureDetector(
                onTap: () => onFilterChanged(filter),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? cinemaPageAccent : cinemaPageCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected ? cinemaPageAccent : cinemaPageBorder,
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      color: selected ? Colors.white : cinemaPageText,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Text(
            'DANH SÁCH PHIM',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cinemaPageText,
                ),
          ),
        ),
        Expanded(
          child: movieGroups.isEmpty
              ? const CinemaStatusView(
                  icon: Icons.event_busy_outlined,
                  message: 'Hiện chưa có lịch chiếu phù hợp.',
                )
              : RefreshIndicator(
                  color: cinemaPageAccent,
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: movieGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, index) => _CinemaMovieCard(
                      group: movieGroups[index],
                      roomTotalSeatsById: roomTotalSeatsById,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CinemaMovieCard extends StatelessWidget {
  final CinemaMovieGroup group;
  final Map<String, int> roomTotalSeatsById;

  const _CinemaMovieCard({
    required this.group,
    required this.roomTotalSeatsById,
  });

  void _openSeatSelection(
    BuildContext context,
    ShowtimeSummaryResponse showtime,
  ) {
    final movie = group.movie;
    final draft = BookingFlowDraft(
      movie: BookingMovieSnapshot(
        movieId: movie?.id.isNotEmpty == true ? movie!.id : showtime.movieId,
        title: movie?.title ?? showtime.movieTitle,
        posterUrl: movie?.posterUrl ?? showtime.posterUrl,
        ageRating: movie?.ageRating,
        durationMinutes: movie?.duration ?? showtime.durationMinutes,
      ),
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
    final first = group.showtimes.first;
    final movie = group.movie;
    final categories = movie != null && movie.categories.isNotEmpty
        ? movie.categories.map((item) => item.name).join(', ')
        : null;
    final formatLabel = '2D ${languageLabel(movie?.language, first.language)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cinemaPageCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cinemaPageBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie?.title ?? first.movieTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cinemaPageText,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (movie?.ageRating != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFC107),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    ageLabel(movie!.ageRating!),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (categories != null && categories.isNotEmpty)
                Text(
                  categories,
                  style: const TextStyle(color: cinemaPageMuted),
                ),
              if (categories != null && categories.isNotEmpty)
                const Text('|', style: TextStyle(color: cinemaPageMuted)),
              Text(
                languageLabel(movie?.language, first.language),
                style: const TextStyle(color: cinemaPageMuted),
              ),
              const Text('|', style: TextStyle(color: cinemaPageMuted)),
              Text(
                durationLabel(movie?.duration ?? first.durationMinutes),
                style: const TextStyle(color: cinemaPageMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AppNetworkImage(
                    url: movie?.posterUrl ?? first.posterUrl,
                    width: 108,
                    height: 152,
                    borderRadius: 18,
                    fit: BoxFit.cover,
                    backgroundColor: cinemaPageCardAlt,
                    fallbackIcon: Icons.movie_creation_outlined,
                  ),
                  if (movie?.trailerUrl?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.push('/movies/${movie!.id}'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_display_outlined,
                            color: cinemaPageAccent,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Trailer',
                            style: TextStyle(
                              color: cinemaPageAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatLabel,
                      style: const TextStyle(
                        color: cinemaPageText,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: group.showtimes.map((showtime) {
                        final start = parseShowtimeDateTime(showtime.startTime);
                        final end = parseShowtimeDateTime(showtime.endTime);
                        final totalSeats =
                            roomTotalSeatsById[showtime.roomId] ?? 0;
                        final seatText = totalSeats > 0
                            ? '${showtime.availableSeats}/$totalSeats'
                            : 'Còn ${showtime.availableSeats} ghế';

                        return InkWell(
                          onTap: showtime.bookable
                              ? () => _openSeatSelection(context, showtime)
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            width: 132,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: showtime.bookable
                                  ? cinemaPageCardAlt
                                  : cinemaPageCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: showtime.bookable
                                    ? Colors.white.withValues(alpha: 0.72)
                                    : Colors.white.withValues(alpha: 0.26),
                                width: showtime.bookable ? 1.2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: DateFormat('HH:mm').format(start),
                                        style: TextStyle(
                                          color: showtime.bookable
                                              ? cinemaPageText
                                              : cinemaPageMuted,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' ~ ${DateFormat('HH:mm').format(end)}',
                                        style: const TextStyle(
                                          color: cinemaPageMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  seatText,
                                  style: TextStyle(
                                    color: showtime.bookable
                                        ? cinemaPageMuted
                                        : cinemaPageAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
            ],
          ),
        ],
      ),
    );
  }
}
