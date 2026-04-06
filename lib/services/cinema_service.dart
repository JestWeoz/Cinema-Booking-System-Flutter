import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';

class CinemaService {
  CinemaService._();
  static final CinemaService instance = CinemaService._();

  final Dio _dio = DioClient.instance;

  CinemaResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return CinemaResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return CinemaResponse.fromJson(data as Map<String, dynamic>);
  }

  List<CinemaResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => CinemaResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => CinemaResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      if (d['items'] is List) {
        return (d['items'] as List)
            .map((e) => CinemaResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  PaginatedResponse<CinemaResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<CinemaResponse>(
        content: items
            .map((e) => CinemaResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return PaginatedResponse<CinemaResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /cinema — Lấy danh sách rạp
  Future<List<CinemaResponse>> getAll({String? keyword}) async {
    final response = await _dio.get(
      CinemaPaths.base,
      queryParameters: {
        'page': 1,
        'size': 50,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
    );
    return _parseList(response.data);
  }

  /// GET /cinema — Lấy tất cả rạp với phân trang (ADMIN)
  Future<PaginatedResponse<CinemaResponse>> getAllPaginated({
    int page = 1,
    int size = 10,
    String? keyword,
  }) async {
    final response = await _dio.get(CinemaPaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    return _page(response.data);
  }

  /// GET /cinema/{id} — Lấy chi tiết rạp
  Future<CinemaResponse> getById(String id) async {
    final response = await _dio.get(CinemaPaths.byId(id));
    return _parse(response.data);
  }

  /// POST /cinema — Tạo rạp chiếu (ADMIN)
  Future<CinemaResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(CinemaPaths.base, data: data);
    return _parse(response.data);
  }

  /// PUT /cinema/{id} — Cập nhật rạp chiếu (ADMIN)
  Future<CinemaResponse> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(CinemaPaths.byId(id), data: data);
    return _parse(response.data);
  }

  /// DELETE /cinema/{id} — Xóa rạp chiếu (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(CinemaPaths.byId(id));
  }

  /// PATCH /cinema/{id}/toggle-status — Chuyển trạng thái hoạt động (ADMIN)
  Future<void> toggleStatus(String id) async {
    await _dio.patch(CinemaPaths.toggleStatus(id));
  }

  /// GET /cinema/{cinemaId}/movies — Lấy danh sách phim theo rạp và ngày chiếu
  Future<List<MovieResponse>> getMoviesByCinema(
    String cinemaId, {
    String? date,
  }) async {
    final response = await _dio.get(
      CinemaPaths.moviesByCinema(cinemaId),
      queryParameters: {
        if (date != null) 'date': date,
      },
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => MovieResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => MovieResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
