import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';
import 'package:cinema_booking_system_app/models/enums.dart';

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
  final AgeRating? ageRating;

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
    this.ageRating,
  });

  MovieModel copyWith({
    String? id,
    String? title,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    int? durationMinutes,
    String? releaseDate,
    List<String>? genres,
    String? status,
    AgeRating? ageRating,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      ageRating: ageRating ?? this.ageRating,
    );
  }

  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    List<String> parseGenres(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) {
              if (e is Map<String, dynamic>) {
                return (e['name'] ?? '').toString();
              }
              return e.toString();
            })
            .where((value) => value.isNotEmpty)
            .toList();
      }
      if (raw is String) return raw.split(',').map((e) => e.trim()).toList();
      return [];
    }

    AgeRating? parseAgeRating(dynamic raw) {
      final value = raw?.toString().trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      try {
        return AgeRating.values.byName(value);
      } catch (_) {
        return null;
      }
    }

    return MovieModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      overview:
          json['description'] as String? ?? json['overview'] as String? ?? '',
      posterUrl: ImageUrlResolver.pick(json,
              keys: const ['posterUrl', 'poster_url']) ??
          '',
      backdropUrl: ImageUrlResolver.pick(
        json,
        keys: const ['backdropUrl', 'backdrop_url'],
      ),
      rating: ((json['averageRating'] ?? json['rating']) as num?)?.toDouble() ??
          0.0,
      durationMinutes:
          json['duration'] as int? ?? json['durationMinutes'] as int? ?? 0,
      releaseDate: json['releaseDate'] as String? ??
          json['release_date'] as String? ??
          '',
      genres: parseGenres(json['genres'] ?? json['categories']),
      status: json['status'] as String? ?? 'now_showing',
      ageRating: parseAgeRating(json['ageRating']),
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
      'ageRating': ageRating?.name,
    };
  }
}
