import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/models/requests/showtime_requests.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';

class ShowtimeService {
  ShowtimeService._();

  static final ShowtimeService instance = ShowtimeService._();

  final Dio _dio = DioClient.instance;

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return data['data'];
    }
    return data;
  }

  List<ShowtimeSummaryResponse> _parseSummaryList(dynamic data) {
    final raw = _unwrap(data);
    if (raw is List) {
      return raw
          .map((item) => ShowtimeSummaryResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic> && raw['items'] is List) {
      return (raw['items'] as List)
          .map((item) => ShowtimeSummaryResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic> && raw['content'] is List) {
      return (raw['content'] as List)
          .map((item) => ShowtimeSummaryResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  PaginatedResponse<ShowtimeSummaryResponse> _parsePage(dynamic data) {
    final raw = _unwrap(data);
    if (raw is Map<String, dynamic>) {
      final items = raw['items'] as List? ?? const [];
      final page = raw['page'] as int? ?? 0;
      final totalPages = raw['totalPages'] as int? ?? 0;
      return PaginatedResponse<ShowtimeSummaryResponse>(
        content: items
            .map((item) => ShowtimeSummaryResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalElements: raw['totalElements'] as int? ?? 0,
        totalPages: totalPages,
        size: raw['size'] as int? ?? 20,
        number: page,
        first: page == 0,
        last: totalPages <= 1 || page >= totalPages - 1,
      );
    }

    return const PaginatedResponse<ShowtimeSummaryResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      size: 20,
      number: 0,
      first: true,
      last: true,
    );
  }

  Future<PaginatedResponse<ShowtimeSummaryResponse>> getPaginated({
    ShowtimeFilterRequest? filter,
  }) async {
    final response = await _dio.get(
      ShowtimePaths.base,
      queryParameters: filter?.toQueryParams(),
    );
    return _parsePage(response.data);
  }

  Future<List<ShowtimeSummaryResponse>> getAll({
    ShowtimeFilterRequest? filter,
  }) async {
    final page = await getPaginated(filter: filter);
    return page.content;
  }

  Future<ShowtimeDetailResponse> getById(String id) async {
    final response = await _dio.get(ShowtimePaths.byId(id));
    return ShowtimeDetailResponse.fromJson(
      _unwrap(response.data) as Map<String, dynamic>,
    );
  }

  Future<ShowtimeDetailResponse> create(CreateShowtimeRequest request) async {
    final response = await _dio.post(
      ShowtimePaths.base,
      data: request.toJson(),
    );
    return ShowtimeDetailResponse.fromJson(
      _unwrap(response.data) as Map<String, dynamic>,
    );
  }

  Future<List<ShowtimeDetailResponse>> createMany(
    List<CreateShowtimeRequest> requests,
  ) async {
    final created = <ShowtimeDetailResponse>[];
    for (final request in requests) {
      created.add(await create(request));
    }
    return created;
  }

  Future<ShowtimeDetailResponse> update(
    String id,
    UpdateShowtimeRequest request,
  ) async {
    final response = await _dio.put(
      ShowtimePaths.byId(id),
      data: request.toJson(),
    );
    return ShowtimeDetailResponse.fromJson(
      _unwrap(response.data) as Map<String, dynamic>,
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete(ShowtimePaths.byId(id));
  }

  Future<ShowtimeDetailResponse> cancel(String id) async {
    final response = await _dio.patch(ShowtimePaths.cancel(id));
    return ShowtimeDetailResponse.fromJson(
      _unwrap(response.data) as Map<String, dynamic>,
    );
  }

  Future<List<ShowtimeSummaryResponse>> getByCinema(
    String cinemaId, {
    String? date,
  }) async {
    final response = await _dio.get(
      ShowtimePaths.byCinema(cinemaId),
      queryParameters: {
        if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
      },
    );
    return _parseSummaryList(response.data);
  }

  Future<List<ShowtimeSummaryResponse>> getByMovie(
    String movieId, {
    String? date,
  }) async {
    final response = await _dio.get(
      ShowtimePaths.byMovie(movieId),
      queryParameters: {
        if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
      },
    );
    return _parseSummaryList(response.data);
  }

  Future<SeatMapResponse> getSeatMap(String showtimeId) async {
    final response = await _dio.get(ShowtimePaths.seats(showtimeId));
    return SeatMapResponse.fromJson(
      _unwrap(response.data) as Map<String, dynamic>,
    );
  }

  Future<List<ShowtimeSeatResponse>> lockSeats(
    String showtimeId,
    List<String> seatIds,
  ) async {
    final response = await _dio.post(
      ShowtimePaths.lockSeats(showtimeId),
      data: {'seatIds': seatIds},
    );
    final raw = _unwrap(response.data);
    if (raw is List) {
      return raw
          .map((item) => ShowtimeSeatResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  Future<void> unlockSeats(
    String showtimeId,
    List<String> seatIds,
  ) async {
    await _dio.post(
      ShowtimePaths.unlockSeats(showtimeId),
      data: {'seatIds': seatIds},
    );
  }

  Future<List<ShowtimeSeatResponse>> getMyLockedSeats(String showtimeId) async {
    final response = await _dio.get(ShowtimePaths.myLockedSeats(showtimeId));
    final raw = _unwrap(response.data);
    if (raw is List) {
      return raw
          .map((item) => ShowtimeSeatResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}
