import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';

class MovieModel {
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

  const MovieModel({
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

  factory MovieModel.fromJson(Map<String, dynamic> json) {
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
      posterUrl: ImageUrlResolver.pick(json, keys: const ['posterUrl', 'poster_url']) ?? '',
      backdropUrl: ImageUrlResolver.pick(
        json,
        keys: const ['backdropUrl', 'backdrop_url'],
      ),
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
