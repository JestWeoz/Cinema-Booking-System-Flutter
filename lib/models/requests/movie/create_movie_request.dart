import 'package:cinema_booking_system_app/models/enums.dart';

class CreateMovieRequest {
  final String title;
  final String slug;
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
    required this.slug,
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
        'slug': slug,
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
