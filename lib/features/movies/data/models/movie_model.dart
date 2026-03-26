import 'package:cinema_booking_system_app/features/movies/domain/entities/movie_entity.dart';

class MovieModel extends MovieEntity {
  const MovieModel({
    required super.id,
    required super.title,
    required super.overview,
    required super.posterUrl,
    super.backdropUrl,
    required super.rating,
    required super.durationMinutes,
    required super.releaseDate,
    required super.genres,
    required super.status,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    // Handle genres as List or comma-separated string
    List<String> parseGenres(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) return raw.split(',').map((e) => e.trim()).toList();
      return [];
    }

    return MovieModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      overview: json['description'] as String? ??
          json['overview'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ??
          json['poster_url'] as String? ?? '',
      backdropUrl: json['backdropUrl'] as String? ?? json['backdrop_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration'] as int? ??
          json['durationMinutes'] as int? ?? 0,
      releaseDate: json['releaseDate'] as String? ??
          json['release_date'] as String? ?? '',
      genres: parseGenres(json['genres']),
      status: json['status'] as String? ?? 'now_showing',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': overview,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'rating': rating,
      'duration': durationMinutes,
      'releaseDate': releaseDate,
      'genres': genres,
      'status': status,
    };
  }
}
