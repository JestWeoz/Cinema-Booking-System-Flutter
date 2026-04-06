import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/create_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/update_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/product/create_product_request.dart';
import 'package:cinema_booking_system_app/models/requests/product/update_product_request.dart';
import 'package:cinema_booking_system_app/models/requests/showtime_requests.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final Dio _dio = DioClient.instance;

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['content'] is List) {
      return (data['content'] as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  PaginatedResponse<T> _page<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
) {
  if (data is Map<String, dynamic>) {
    final d = data['data']; // 🔥 QUAN TRỌNG

    return PaginatedResponse<T>(
      content: (d['items'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: d['totalElements'] ?? 0,
      totalPages: d['totalPages'] ?? 1,
      number: d['page'] ?? 0,
      size: d['size'] ?? 10,
      first: (d['page'] ?? 0) == 0,
      last: true,
    );
  }

  return PaginatedResponse<T>(
    content: [],
    totalElements: 0,
    totalPages: 0,
    number: 0,
    size: 10,
    first: true,
    last: true,
  );
}

  // ─── Movies ──────────────────────────────────────────────────────────────

  Future<PaginatedResponse<MovieResponse>> getMovies({
    int page = 1,
    int size = 10,
    String? keyword,
    String? status,
  }) async {
    final resp = await _dio.get(MoviePaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null) 'status': status,
    });
    return _page<MovieResponse>(resp.data, MovieResponse.fromJson);
  }

  Future<MovieResponse> createMovie(CreateMovieRequest req) async {
    final resp = await _dio.post(MoviePaths.base, data: req.toJson());
    return MovieResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<MovieResponse> updateMovie(String id, UpdateMovieRequest req) async {
    final resp = await _dio.put(MoviePaths.byId(id), data: req.toJson());
    return MovieResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteMovie(String id) => _dio.delete(MoviePaths.byId(id));

  Future<void> updateMovieStatus(String id, String status) async {
    await _dio.patch(MoviePaths.updateStatus(id), data: {'status': status});
  }

  // ─── Showtimes ────────────────────────────────────────────────────────────

  Future<PaginatedResponse<ShowtimeSummaryResponse>> getShowtimes({
    int page = 1,
    int size = 20,
    String? movieId,
    String? cinemaId,
    String? date,
    String? status,
  }) async {
    final resp = await _dio.get(ShowtimePaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (movieId != null) 'movieId': movieId,
      if (cinemaId != null) 'cinemaId': cinemaId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    });
    return _page<ShowtimeSummaryResponse>(resp.data, ShowtimeSummaryResponse.fromJson);
  }

  Future<void> cancelShowtime(String id) => _dio.patch(ShowtimePaths.cancel(id));
  Future<void> deleteShowtime(String id) => _dio.delete(ShowtimePaths.byId(id));

  Future<void> createShowtime(CreateShowtimeRequest req) async {
    await _dio.post(ShowtimePaths.base, data: req.toJson());
  }

  // ─── Cinema ───────────────────────────────────────────────────────────────

  Future<PaginatedResponse<CinemaResponse>> getCinemas({int page = 1, int size = 10, String? keyword}) async {
    final resp = await _dio.get(CinemaPaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    return _page<CinemaResponse>(resp.data, CinemaResponse.fromJson);
  }

  Future<CinemaResponse> createCinema(Map<String, dynamic> data) async {
    final resp = await _dio.post(CinemaPaths.base, data: data);
    return CinemaResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteCinema(String id) => _dio.delete(CinemaPaths.byId(id));
  Future<void> toggleCinemaStatus(String id) => _dio.patch(CinemaPaths.toggleStatus(id));

  // ─── Rooms ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRoomsByCinema(String cinemaId,{int page = 1, int size = 20}) async {
    final resp = await _dio.get(
      RoomPaths.byCinema(cinemaId),
      queryParameters: {'page': page > 0 ? page - 1 : 0, 'size': size},
    );
    if (resp.data is Map<String, dynamic> &&
        resp.data['data'] is Map<String, dynamic> &&
        resp.data['data']['items'] is List) {
      return (resp.data['data']['items'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    return _list<Map<String, dynamic>>(resp.data, (e) => e);
  }

  Future<void> deleteRoom(String id) => _dio.delete(RoomPaths.byId(id));
  Future<void> toggleRoomStatus(String id) => _dio.patch(RoomPaths.toggleStatus(id));

  // ─── Users ────────────────────────────────────────────────────────────────

  Future<PaginatedResponse<UserResponse>> getUsers({int page = 0, int size = 10, String? key}) async {
    final resp = await _dio.get(UserPaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (key != null && key.isNotEmpty) 'key': key,
    });
    return _page<UserResponse>(resp.data, UserResponse.fromJson);
  }

  Future<void> lockUser(String id) => _dio.put(UserPaths.lock(id));
  Future<void> unlockUser(String id) => _dio.put(UserPaths.unlock(id));

  // ─── Promotions ───────────────────────────────────────────────────────────

  Future<PaginatedResponse<PromotionResponse>> getPromotions({int page = 1, int size = 10}) async {
    final resp = await _dio.get(PromotionPaths.base, queryParameters: {'page': page, 'size': size});
    return _page<PromotionResponse>(resp.data, PromotionResponse.fromJson);
  }

  Future<PromotionResponse> createPromotion(Map<String, dynamic> data) async {
    final resp = await _dio.post(PromotionPaths.base, data: data);
    return PromotionResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deletePromotion(String id) => _dio.delete(PromotionPaths.byId(id));

  // ─── Products ─────────────────────────────────────────────────────────────

  Future<PaginatedResponse<ProductResponse>> getProducts({int page = 0, int size = 10, String? keyword}) async {
    final resp = await _dio.get(ProductPaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    return _page<ProductResponse>(resp.data, ProductResponse.fromJson);
  }

  Future<ProductResponse> createProduct(CreateProductRequest req) async {
    final resp = await _dio.post(ProductPaths.base, data: req.toJson());
    return ProductResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ProductResponse> updateProduct(String id, UpdateProductRequest req) async {
    final resp = await _dio.put(ProductPaths.byId(id), data: req.toJson());
    return ProductResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) => _dio.delete(ProductPaths.byId(id));
  Future<void> toggleProductActive(String id) => _dio.patch(ProductPaths.toggleActive(id));

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<List<CategoryResponse>> getCategories() async {
    final resp = await _dio.get(CategoryPaths.base);
    return _list<CategoryResponse>(resp.data, CategoryResponse.fromJson);
  }
}
