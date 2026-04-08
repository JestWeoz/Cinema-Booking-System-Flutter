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

class UpdateMovieRequest {
  final String? title;
  final String? slug;
  final String? description;
  final int? duration;
  final DateTime? releaseDate;
  final AgeRating? ageRating;
  final String? language;
  final String? posterUrl;
  final String? trailerUrl;
  final List<String>? categoryIds;

  const UpdateMovieRequest({
    this.title,
    this.slug,
    this.description,
    this.duration,
    this.releaseDate,
    this.ageRating,
    this.language,
    this.posterUrl,
    this.trailerUrl,
    this.categoryIds,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (title != null) {
      map['slug'] = (slug == null || slug!.trim().isEmpty)
          ? _buildMovieSlug(title!)
          : slug!.trim();
    } else if (slug != null) {
      map['slug'] = slug!.trim();
    }
    if (description != null) map['description'] = description;
    if (duration != null) map['duration'] = duration;
    if (releaseDate != null) {
      map['releaseDate'] = releaseDate!.toIso8601String().split('T').first;
    }
    if (ageRating != null) map['ageRating'] = ageRating!.name;
    if (language != null) map['language'] = language;
    if (posterUrl != null) map['posterUrl'] = posterUrl;
    if (trailerUrl != null) map['trailerUrl'] = trailerUrl;
    if (categoryIds != null) map['categoryIds'] = categoryIds;
    return map;
  }
}
