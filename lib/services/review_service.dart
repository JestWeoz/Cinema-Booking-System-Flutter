import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final Dio _dio = DioClient.instance;

  ReviewResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return ReviewResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return ReviewResponse.fromJson(data as Map<String, dynamic>);
  }

  List<ReviewResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => ReviewResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => ReviewResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => ReviewResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /reviews/movies/{movieId} — Lấy danh sách đánh giá theo phim
  Future<List<ReviewResponse>> getByMovie(String movieId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      ReviewPaths.byMovie(movieId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parseList(response.data);
  }

  /// GET /reviews/{reviewId} — Lấy thông tin đánh giá
  Future<ReviewResponse> getById(String reviewId) async {
    final response = await _dio.get(ReviewPaths.byId(reviewId));
    return _parse(response.data);
  }

  /// POST /reviews — Tạo đánh giá mới
  Future<ReviewResponse> create({
    required String movieId,
    required int rating,
    required String comment,
  }) async {
    final response = await _dio.post(ReviewPaths.base, data: {
      'movieId': movieId,
      'rating': rating,
      'comment': comment,
    });
    return _parse(response.data);
  }

  /// PUT /reviews/{reviewId} — Cập nhật đánh giá
  Future<ReviewResponse> update(String reviewId, {
    int? rating,
    String? comment,
  }) async {
    final response = await _dio.put(ReviewPaths.byId(reviewId), data: {
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
    });
    return _parse(response.data);
  }

  /// DELETE /reviews/{reviewId} — Xóa đánh giá
  Future<void> delete(String reviewId) async {
    await _dio.delete(ReviewPaths.byId(reviewId));
  }

  /// GET /reviews/movies/{movieId}/average-rating — Lấy điểm đánh giá trung bình của phim
  Future<double> getAverageRating(String movieId) async {
    final response = await _dio.get(ReviewPaths.averageByMovie(movieId));
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ((data['data'] ?? data['averageRating'] ?? 0) as num).toDouble();
    }
    if (data is num) return data.toDouble();
    return 0.0;
  }
}
