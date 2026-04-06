import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_models.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_utils.dart';
import 'package:cinema_booking_system_app/pages/seat_selection_page.dart';
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
  final Future<void> Function() onRefresh;

  const CinemaDetailView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.movieGroups,
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
            itemCount: 7,
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
                    color: selected ? AppColors.primary : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        index == 0 ? 'Hôm nay' : weekdayLabel(date),
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chọn suất chiếu phù hợp và đặt vé nhanh ngay trong hôm nay.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Text(
            'Danh sách phim',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
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
                  color: AppColors.primary,
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: movieGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, index) =>
                        _CinemaMovieCard(group: movieGroups[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CinemaMovieCard extends StatelessWidget {
  final CinemaMovieGroup group;

  const _CinemaMovieCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final first = group.showtimes.first;
    final movie = group.movie;
    final categories = movie != null && movie.categories.isNotEmpty
        ? movie.categories.map((item) => item.name).join(', ')
        : null;

    final byRoom = <String, List<ShowtimeSummaryResponse>>{};
    for (final item in group.showtimes) {
      byRoom.putIfAbsent(item.roomName, () => []).add(item);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  movie?.title ?? first.movieTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (movie != null)
                TextButton(
                  onPressed: () => context.push('/movies/${movie.id}'),
                  child: const Text('Chi tiết'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (movie?.ageRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.18),
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
                Text(categories, style: const TextStyle(color: Colors.white70)),
              Text('|', style: TextStyle(color: Colors.white.withValues(alpha: 0.24))),
              Text(
                movie?.language?.isNotEmpty == true
                    ? movie!.language!
                    : languageLabel(null, first.language),
                style: const TextStyle(color: Colors.white70),
              ),
              Text('|', style: TextStyle(color: Colors.white.withValues(alpha: 0.24))),
              Text(
                durationLabel(movie?.duration ?? first.durationMinutes),
                style: const TextStyle(color: Colors.white70),
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
                    backgroundColor: AppColors.dividerDark,
                    fallbackIcon: Icons.movie_creation_outlined,
                  ),
                  if (movie?.trailerUrl?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => context.push('/movies/${movie!.id}'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_display_outlined,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Trailer',
                            style: TextStyle(
                              color: AppColors.primary,
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
                  children: byRoom.entries.map((roomEntry) {
                    final roomShowtimes = [...roomEntry.value]
                      ..sort((a, b) => parseShowtimeDateTime(a.startTime)
                          .compareTo(parseShowtimeDateTime(b.startTime)));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomEntry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: roomShowtimes.map((showtime) {
                              final start =
                                  parseShowtimeDateTime(showtime.startTime);
                              final end = parseShowtimeDateTime(showtime.endTime);
                              return InkWell(
                                onTap: showtime.bookable
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SeatSelectionPage(),
                                          ),
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  width: 136,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: showtime.bookable
                                        ? AppColors.surfaceDark
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: showtime.bookable
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.white.withValues(alpha: 0.04),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('HH:mm').format(start),
                                        style: TextStyle(
                                          color: showtime.bookable
                                              ? Colors.white
                                              : Colors.white38,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '~${DateFormat('HH:mm').format(end)}',
                                        style: TextStyle(
                                          color: showtime.bookable
                                              ? Colors.white60
                                              : Colors.white30,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        moneyLabel(showtime.basePrice),
                                        style: TextStyle(
                                          color: showtime.bookable
                                              ? AppColors.primary
                                              : Colors.white30,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
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
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
