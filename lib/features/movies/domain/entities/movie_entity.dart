import 'package:equatable/equatable.dart';

class MovieEntity extends Equatable {
  final String id;
  final String title;
  final String overview;
  final String posterUrl;
  final String? backdropUrl;
  final double rating;
  final int durationMinutes;
  final String releaseDate;
  final List<String> genres;
  final String status; // 'now_showing' | 'coming_soon'

  const MovieEntity({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    this.backdropUrl,
    required this.rating,
    required this.durationMinutes,
    required this.releaseDate,
    required this.genres,
    required this.status,
  });

  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  List<Object?> get props => [id];
}
