// ignore_for_file: comment_references

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';
import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/services/cloudinary_service.dart';
import 'package:cinema_booking_system_app/services/review_service.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/create_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/update_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/add_people_to_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/people_role_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/update_movie_people_request.dart';

// ─── Image / People Response ───────────────────────────────────────────────

class MovieImageResponse {
  final String imageId;
  final String imageUrl;
  final bool isPrimary;

  const MovieImageResponse({
    required this.imageId,
    required this.imageUrl,
    required this.isPrimary,
  });

  factory MovieImageResponse.fromJson(Map<String, dynamic> json) =>
      MovieImageResponse(
        imageId: (json['imageId'] ?? json['id'] ?? '').toString(),
        imageUrl: ImageUrlResolver.pick(json, keys: const ['imageUrl']) ?? '',
        isPrimary: json['isPrimary'] ?? false,
      );
}

class MoviePersonResponse {
  final String peopleId;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String? character;

  const MoviePersonResponse({
    required this.peopleId,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.character,
  });

  factory MoviePersonResponse.fromJson(Map<String, dynamic> json) =>
      MoviePersonResponse(
        peopleId: (json['peopleId'] ?? json['id'] ?? '').toString(),
        fullName: (json['fullName'] ?? json['peopleName'] ?? json['name'] ?? '')
            .toString(),
        avatarUrl: ImageUrlResolver.pick(
          json,
          keys: const ['avatarUrl', 'peopleAvatar'],
        ),
        role: (json['role'] ?? json['movieRole'] ?? '').toString(),
        character: (json['character'] ?? json['characterName'])?.toString(),
      );
}

// ─── MovieService ──────────────────────────────────────────────────────────

class MovieService {
  MovieService._();
  static final MovieService instance = MovieService._();

  final Dio _dio = DioClient.instance;
  final ReviewService _reviewService = ReviewService.instance;

  // ─── Internal helpers ─────────────────────────────────────────────────────

  List<MovieModel> _parseModelList(dynamic data) {
    final List raw = _extractList(data);
    return raw
        .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MovieModel>> _attachAverageRatings(
      List<MovieModel> movies) async {
    if (movies.isEmpty) {
      return movies;
    }

    final enriched = await Future.wait(
      movies.map((movie) async {
        if (movie.id.isEmpty) {
          return movie;
        }

        try {
          final averageRating = await _reviewService.getAverageRating(movie.id);
          return movie.copyWith(rating: averageRating);
        } catch (_) {
          return movie;
        }
      }),
    );

    return enriched;
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['content'] is List) return data['content'] as List;
      if (data['data'] is List) return data['data'] as List;
      if (data['data'] is Map) {
        final d = data['data'] as Map<String, dynamic>;
        if (d['items'] is List) return d['items'] as List;
      }
    }
    return [];
  }

  MovieResponse _parseResponse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return MovieResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return MovieResponse.fromJson(data as Map<String, dynamic>);
  }

  List<MovieImageResponse> _parseImageList(dynamic data) {
    final raw = _extractList(data);
    return raw
        .map((e) => MovieImageResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<MoviePersonResponse> _parsePeopleList(dynamic data) {
    final raw = _extractList(data);
    return raw
        .map((e) => MoviePersonResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  PaginatedResponse<MovieResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<MovieResponse>(
        content: items
            .map((e) => MovieResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return const PaginatedResponse<MovieResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  // ─── Public endpoints (backward-compatible — return MovieModel) ────────────

  /// GET /movies/now-showing — Phim đang chiếu
  Future<List<MovieModel>> getNowShowing({int page = 1, int size = 10}) async {
    final response = await _dio.get(
      MoviePaths.nowShowing,
      queryParameters: {'page': page - 1, 'size': size},
    );
    return _attachAverageRatings(_parseModelList(response.data));
  }

  /// GET /movies/coming-soon — Phim sắp chiếu
  Future<List<MovieModel>> getComingSoon({int page = 1, int size = 10}) async {
    final response = await _dio.get(
      MoviePaths.comingSoon,
      queryParameters: {'page': page - 1, 'size': size},
    );
    return _attachAverageRatings(_parseModelList(response.data));
  }

  /// GET /movies/recommend — Gợi ý phim
  Future<List<MovieModel>> getRecommended() async {
    final response = await _dio.get(MoviePaths.recommend);
    return _attachAverageRatings(_parseModelList(response.data));
  }

  /// GET /movies/search/{keyword} — Tìm kiếm phim
  Future<List<MovieModel>> search(String query,
      {int page = 0, int size = 10}) async {
    final response = await _dio.get(
      MoviePaths.searchByKeyword(query),
      queryParameters: {'page': page, 'size': size},
    );
    return _attachAverageRatings(_parseModelList(response.data));
  }

  /// GET /movies/{id} — Lấy chi tiết phim theo ID (legacy)
  Future<MovieModel> getById(String id) async {
    final response = await _dio.get(MoviePaths.byId(id));
    final r = _parseResponse(response.data);
    return MovieModel.fromJson({
      'id': r.id,
      'title': r.title,
      'description': r.description,
      'posterUrl': r.posterUrl ?? '',
      'rating': 0,
      'duration': r.duration,
      'releaseDate': r.releaseDate ?? '',
      'status': r.status?.name ?? 'NOW_SHOWING',
      'genres': r.categories.map((c) => c.name).toList(),
      'ageRating': r.ageRating?.name,
    });
  }

  /// GET /movies/slug/{slug} — Lấy chi tiết phim theo slug
  Future<MovieResponse> getDetail(String id) async {
    final response = await _dio.get(MoviePaths.byId(id));
    return _parseResponse(response.data);
  }

  Future<MovieResponse> getBySlug(String slug) async {
    final response = await _dio.get(MoviePaths.bySlug(slug));
    return _parseResponse(response.data);
  }

  // ─── Image endpoints ──────────────────────────────────────────────────────

  /// GET /movies/{movieId}/images — Lấy hình ảnh của phim
  Future<List<MovieImageResponse>> getImages(String movieId) async {
    final response = await _dio.get(MoviePaths.images(movieId));
    return _parseImageList(response.data);
  }

  /// POST /movies/{movieId}/images — Thêm một hoặc nhiều hình ảnh cho phim
  Future<List<MovieImageResponse>> addImages(
    String movieId,
    List<String> imageUrls,
  ) async {
    final normalized = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) {
      return getImages(movieId);
    }
    final response = await _dio.post(
      MoviePaths.images(movieId),
      data: {'imageUrls': normalized},
    );
    return _parseImageList(response.data);
  }

  /// POST /movies/{movieId}/images — Thêm hình ảnh cho phim
  Future<MovieImageResponse> addImage(
      String movieId, Map<String, dynamic> body) async {
    final rawUrls = body['imageUrls'];
    final imageUrls = rawUrls is List
        ? rawUrls.map((e) => e.toString()).toList()
        : [
            if ((body['imageUrl'] ?? '').toString().trim().isNotEmpty)
              body['imageUrl'].toString(),
          ];
    final images = await addImages(movieId, imageUrls);
    if (images.isNotEmpty) {
      final requested = imageUrls.toSet();
      for (final image in images.reversed) {
        if (requested.contains(image.imageUrl)) {
          return image;
        }
      }
      return images.last;
    }
    throw StateError('No movie image returned after upload');
  }

  /// PUT /movies/{movieId}/images — Cập nhật hình ảnh của phim
  Future<List<MovieImageResponse>> updateImages(
    String movieId,
    List<String> imageUrls,
  ) async {
    await _dio.put(
      MoviePaths.images(movieId),
      data: {'imageUrls': imageUrls},
    );
    return getImages(movieId);
  }

  /// DELETE /movies/{movieId}/images/{imageId} — Xóa hình ảnh của phim
  Future<void> deleteImage(String movieId, String imageId) async {
    await _dio.delete(MoviePaths.imageById(movieId, imageId));
  }

  // ─── People endpoints ─────────────────────────────────────────────────────

  /// GET /movies/{movieId}/people — Lấy cast của phim
  Future<List<MoviePersonResponse>> getPeople(String movieId) async {
    final response = await _dio.get(MoviePaths.people(movieId));
    return _parsePeopleList(response.data);
  }

  /// POST /movies/{movieId}/people — Thêm một hoặc nhiều người vào phim
  Future<List<MoviePersonResponse>> addPeopleToMovie(
    String movieId,
    AddPeopleToMovieRequest request,
  ) async {
    final response = await _dio.post(
      MoviePaths.people(movieId),
      data: request.toJson(),
    );
    return _parsePeopleList(response.data);
  }

  /// POST /movies/{movieId}/people — Thêm người vào phim
  Future<void> addPerson(String movieId, Map<String, dynamic> body) async {
    await _dio.post(MoviePaths.people(movieId), data: body);
  }

  /// PUT /movies/{movieId}/people — Cập nhật thông tin người trong phim
  Future<List<MoviePersonResponse>> replacePeople(
    String movieId,
    UpdateMoviePeopleRequest request,
  ) async {
    final response = await _dio.put(
      MoviePaths.people(movieId),
      data: request.toJson(),
    );
    return _parsePeopleList(response.data);
  }

  /// PUT /movies/{movieId}/people — Cập nhật thông tin người trong phim
  Future<void> updatePeople(
    String movieId,
    List<Map<String, dynamic>> people,
  ) async {
    await replacePeople(
      movieId,
      UpdateMoviePeopleRequest(
        people: people
            .map(
              (item) => PeopleRoleRequest(
                peopleId: (item['peopleId'] ?? '').toString(),
                role: _movieRoleFromRaw(item['role'] ?? item['movieRole']),
              ),
            )
            .toList(),
      ),
    );
  }

  /// DELETE /movies/{movieId}/people/{peopleId} — Xóa người khỏi phim
  Future<void> deletePerson(String movieId, String peopleId) async {
    await _dio.delete(MoviePaths.personById(movieId, peopleId));
  }

  /// DELETE /movies/{movieId}/people/bulk — Xóa nhiều người khỏi phim
  Future<void> deletePeopleBulk(String movieId, List<String> peopleIds) async {
    await _dio.delete(
      MoviePaths.peopleBulkDelete(movieId),
      data: {'peopleIds': peopleIds},
    );
  }

  // ─── Admin CRUD ───────────────────────────────────────────────────────────

  /// GET /movies — Lấy danh sách phim (có phân trang, filter)
  Future<PaginatedResponse<MovieResponse>> getAll({
    int page = 1,
    int size = 10,
    String? keyword,
    String? status,
  }) async {
    final response = await _dio.get(MoviePaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null) 'status': status,
    });
    return _page(response.data);
  }

  /// POST /movies — Tạo phim mới (ADMIN)
  Future<MovieResponse> create(CreateMovieRequest req) async {
    final response = await _dio.post(MoviePaths.base, data: req.toJson());
    return _parseResponse(response.data);
  }

  /// PUT /movies/{id} — Cập nhật thông tin phim (ADMIN)
  Future<MovieResponse> update(String id, UpdateMovieRequest req) async {
    final response = await _dio.put(MoviePaths.byId(id), data: req.toJson());
    return _parseResponse(response.data);
  }

  /// DELETE /movies/{id} — Xóa phim (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(MoviePaths.byId(id));
  }

  /// PATCH /movies/{id}/status — Cập nhật trạng thái phìm (ADMIN)
  Future<void> updateStatus(String id, String status) async {
    await _dio.patch(MoviePaths.updateStatus(id), data: {'status': status});
  }

  // ─── Upload-integrated helpers ─────────────────────────────────────────────

  /// Upload poster: mở picker → upload Cloudinary → trả URL
  Future<String?> pickAndUploadPoster({
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) =>
      MediaUploadHelper.pickAndUploadImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 85,
        onUploading: onUploading,
        onError: onError,
      );

  /// Upload trailer: mở picker → upload Cloudinary → trả URL
  Future<String?> pickAndUploadTrailer({
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) =>
      MediaUploadHelper.pickAndUploadVideo(
        source: ImageSource.gallery,
        onUploading: onUploading,
        onError: onError,
      );

  /// Upload backdrop/banner: mở picker → upload Cloudinary → trả URL
  Future<String?> pickAndUploadBackdrop({
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) =>
      MediaUploadHelper.pickAndUploadImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        onUploading: onUploading,
        onError: onError,
      );

  /// Tạo phìm kèm upload tự động:
  /// [posterLocalPath] và [trailerLocalPath] là đường dẫn local (tùy chọn).
  /// Nếu bạn đã có URL thì dùng [create] truyền thẳng.
  Future<MovieResponse> createWithUpload({
    required CreateMovieRequest request,
    String? posterFilePath, // local file path (mobile/desktop)
    String? trailerFilePath,
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) async {
    String posterUrl = request.posterUrl;
    String trailerUrl = request.trailerUrl;

    if (posterFilePath != null && posterFilePath.isNotEmpty) {
      onUploading?.call(true);
      final multipart = await MultipartFile.fromFile(
        posterFilePath,
        filename: posterFilePath.split('/').last,
      );
      try {
        final uploaded =
            await CloudinaryService.instance.uploadImage(multipart);
        if (uploaded.isNotEmpty) posterUrl = uploaded;
      } catch (e) {
        onError?.call('Lỗi upload poster: $e');
      } finally {
        onUploading?.call(false);
      }
    }

    if (trailerFilePath != null && trailerFilePath.isNotEmpty) {
      onUploading?.call(true);
      final multipart = await MultipartFile.fromFile(
        trailerFilePath,
        filename: trailerFilePath.split('/').last,
      );
      try {
        final uploaded =
            await CloudinaryService.instance.uploadVideo(multipart);
        if (uploaded.isNotEmpty) trailerUrl = uploaded;
      } catch (e) {
        onError?.call('Lỗi upload trailer: $e');
      } finally {
        onUploading?.call(false);
      }
    }

    // Tạo phìm với URL (có thể đã được thay thế bằng URL Cloudinary)
    return create(CreateMovieRequest(
      title: request.title,
      slug: request.slug,
      description: request.description,
      duration: request.duration,
      releaseDate: request.releaseDate,
      ageRating: request.ageRating,
      language: request.language,
      posterUrl: posterUrl,
      trailerUrl: trailerUrl,
      categoryIds: request.categoryIds,
    ));
  }

  MovieRole _movieRoleFromRaw(dynamic raw) {
    final value = raw?.toString().trim().toUpperCase();
    return MovieRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => MovieRole.ACTOR,
    );
  }
}
