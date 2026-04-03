import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/models/requests/showtime_requests.dart';

class ShowtimeService {
  ShowtimeService._();
  static final ShowtimeService instance = ShowtimeService._();

  final Dio _dio = DioClient.instance;

  List<ShowtimeSummaryResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) =>
              ShowtimeSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) =>
              ShowtimeSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /showtimes — Lấy danh sách suất chiếu (có filter)
  Future<List<ShowtimeSummaryResponse>> getAll({
    ShowtimeFilterRequest? filter,
  }) async {
    final response = await _dio.get(
      ShowtimePaths.base,
      queryParameters: filter?.toQueryParams(),
    );
    return _parseList(response.data);
  }

  /// GET /showtimes/{id} — Lấy chi tiết suất chiếu
  Future<ShowtimeDetailResponse> getById(String id) async {
    final response = await _dio.get(ShowtimePaths.byId(id));
    return ShowtimeDetailResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// POST /showtimes — Tạo suất chiếu
  Future<ShowtimeDetailResponse> create(CreateShowtimeRequest request) async {
    final response = await _dio.post(
      ShowtimePaths.base,
      data: request.toJson(),
    );
    return ShowtimeDetailResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// PUT /showtimes/{id} — Cập nhật suất chiếu
  Future<ShowtimeDetailResponse> update(
      String id, UpdateShowtimeRequest request) async {
    final response = await _dio.put(
      ShowtimePaths.byId(id),
      data: request.toJson(),
    );
    return ShowtimeDetailResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// DELETE /showtimes/{id} — Xóa suất chiếu
  Future<void> delete(String id) async {
    await _dio.delete(ShowtimePaths.byId(id));
  }

  /// PATCH /showtimes/{id}/cancel — Hủy suất chiếu
  Future<void> cancel(String id) async {
    await _dio.patch(ShowtimePaths.cancel(id));
  }

  /// GET /showtimes/by-cinema/{cinemaId} — Lấy suất chiếu theo rạp và ngày
  Future<List<ShowtimeSummaryResponse>> getByCinema(
    String cinemaId, {
    String? date,
  }) async {
    final response = await _dio.get(
      ShowtimePaths.byCinema(cinemaId),
      queryParameters: {
        if (date != null) 'date': date,
      },
    );
    return _parseList(response.data);
  }

  /// GET /showtimes/by-movie/{movieId} — Lấy suất chiếu theo phim và ngày
  Future<List<ShowtimeSummaryResponse>> getByMovie(
    String movieId, {
    String? date,
  }) async {
    final response = await _dio.get(
      ShowtimePaths.byMovie(movieId),
      queryParameters: {
        if (date != null) 'date': date,
      },
    );
    return _parseList(response.data);
  }
}
