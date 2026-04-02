// Movie Responses — khớp với backend DTO/Response/Movie/
import '../enums.dart';

class CategoryResponse {
  final String id;
  final String name;

  const CategoryResponse({required this.id, required this.name});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) =>
      CategoryResponse(id: json['id'] ?? '', name: json['name'] ?? '');
}

class MovieResponse {
  final String id;
  final String title;
  final String slug;
  final String description;
  final int duration;
  final String? releaseDate; // ISO date: "yyyy-MM-dd"
  final AgeRating? ageRating;
  final String? language;
  final String? posterUrl;
  final String? trailerUrl;
  final MovieStatus? status;
  final List<CategoryResponse> categories;

  const MovieResponse({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.duration,
    this.releaseDate,
    this.ageRating,
    this.language,
    this.posterUrl,
    this.trailerUrl,
    this.status,
    required this.categories,
  });

  factory MovieResponse.fromJson(Map<String, dynamic> json) => MovieResponse(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        slug: json['slug'] ?? '',
        description: json['description'] ?? '',
        duration: json['duration'] ?? 0,
        releaseDate: json['releaseDate'],
        ageRating: json['ageRating'] != null
            ? AgeRating.values.byName(json['ageRating'])
            : null,
        language: json['language'],
        posterUrl: json['posterUrl'],
        trailerUrl: json['trailerUrl'],
        status: json['status'] != null
            ? MovieStatus.values.byName(json['status'])
            : null,
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => CategoryResponse.fromJson(e))
                .toList() ??
            [],
      );
}

class ReviewResponse {
  final String id;
  final String movieId;
  final String movieTitle;
  final String userId;
  final int rating;
  final String comment;
  final String username;
  final String? createdAt;
  final String? updatedAt;
  final bool deleted;

  const ReviewResponse({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.username,
    this.createdAt,
    this.updatedAt,
    required this.deleted,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) => ReviewResponse(
        id: json['id'] ?? '',
        movieId: json['movieId'] ?? '',
        movieTitle: json['movieTitle'] ?? '',
        userId: json['userId'] ?? '',
        rating: json['rating'] ?? 0,
        comment: json['comment'] ?? '',
        username: json['username'] ?? '',
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
        deleted: json['deleted'] ?? false,
      );
}

class ReviewSummaryResponse {
  final String id;
  final int rating;
  final String commentTruncated;
  final String username;
  final String? createdAt;

  const ReviewSummaryResponse({
    required this.id,
    required this.rating,
    required this.commentTruncated,
    required this.username,
    this.createdAt,
  });

  factory ReviewSummaryResponse.fromJson(Map<String, dynamic> json) =>
      ReviewSummaryResponse(
        id: json['id'] ?? '',
        rating: json['rating'] ?? 0,
        commentTruncated: json['commentTruncated'] ?? '',
        username: json['username'] ?? '',
        createdAt: json['createdAt'],
      );
}
