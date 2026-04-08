import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';

class CinemaBrandItem {
  final String key;
  final String label;
  final String? logoUrl;

  const CinemaBrandItem({
    required this.key,
    required this.label,
    this.logoUrl,
  });
}

class CinemaMovieGroup {
  final String movieId;
  final MovieResponse? movie;
  final List<ShowtimeSummaryResponse> showtimes;

  const CinemaMovieGroup({
    required this.movieId,
    required this.movie,
    required this.showtimes,
  });
}

enum CinemaTimeFilter {
  all('Tất cả'),
  noon('12:00 - 15:00'),
  afternoon('15:00 - 18:00'),
  evening('18:00 - 24:00');

  final String label;

  const CinemaTimeFilter(this.label);
}

String cinemaBrandOf(CinemaResponse cinema) {
  final upper = cinema.name.toUpperCase();
  if (upper.contains('CGV')) return 'CGV';
  if (upper.contains('LOTTE')) return 'Lotte';
  if (upper.contains('GALAXY')) return 'Galaxy';
  if (upper.contains('BETA')) return 'Beta';
  if (upper.contains('BHD')) return 'BHD';
  if (upper.contains('CINESTAR')) return 'Cinestar';
  return cinema.name.split(' ').first;
}
