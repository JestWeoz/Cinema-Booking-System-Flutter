import 'package:cinema_booking_system_app/models/enums.dart';

String _buildMovieSlug(String title) {
  final normalized = title
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^\w\s-]', unicode: true), ' ')
      .replaceAll(RegExp(r'[_\s]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return normalized.isEmpty ? 'movie' : normalized;
}

class CreateMovieRequest {
  final String title;
  final String? slug;
  final String? description;
  final int duration;
  final DateTime releaseDate;
  final AgeRating ageRating;
  final String language;
  final String posterUrl;
  final String trailerUrl;
  final List<String> categoryIds;

  const CreateMovieRequest({
    required this.title,
    this.slug,
    this.description,
    required this.duration,
    required this.releaseDate,
    required this.ageRating,
    required this.language,
    required this.posterUrl,
    required this.trailerUrl,
    required this.categoryIds,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'slug': (slug == null || slug!.trim().isEmpty)
            ? _buildMovieSlug(title)
            : slug!.trim(),
        'description': description,
        'duration': duration,
        'releaseDate': releaseDate.toIso8601String().split('T').first,
        'ageRating': ageRating.name,
        'language': language,
        'posterUrl': posterUrl,
        'trailerUrl': trailerUrl,
        'categoryIds': categoryIds,
      };
}
