import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';
import 'package:cinema_booking_system_app/models/enums.dart';

// ─── Response Models ──────────────────────────────────────────────────────

class SeatTypeResponse {
  final String id;
  final String name;
  final double priceModifier;

  const SeatTypeResponse({
    required this.id,
    required this.name,
    required this.priceModifier,
  });

  factory SeatTypeResponse.fromJson(Map<String, dynamic> json) =>
      SeatTypeResponse(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        priceModifier: (json['priceModifier'] ?? 0).toDouble(),
      );
}

class RoomResponse {
  final String id;
  final String name;
  final String cinemaId;
  final String? cinemaName;
  final RoomType? roomType;
  final Status? status;
  final int totalSeats;
  final String? createdAt;
  final String? updatedAt;

  const RoomResponse({
    required this.id,
    required this.name,
    required this.cinemaId,
    this.cinemaName,
    this.roomType,
    this.status,
    required this.totalSeats,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomResponse.fromJson(Map<String, dynamic> json) => RoomResponse(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        cinemaId: json['cinemaId'] ?? '',
        cinemaName: json['cinemaName'],
        roomType: roomTypeFromJson(json['roomType']),
        status: json['status'] != null
            ? Status.values.byName(json['status'])
            : null,
        totalSeats: json['totalSeats'] ?? 0,
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );
}

class SeatResponse {
  final String id;
  final String roomId;
  final String seatRow;
  final int seatNumber;
  final bool active;
  final String seatTypeId;
  final String? seatTypeName;
  final double priceModifier;

  const SeatResponse({
    required this.id,
    required this.roomId,
    required this.seatRow,
    required this.seatNumber,
    required this.active,
    required this.seatTypeId,
    this.seatTypeName,
    required this.priceModifier,
  });

  factory SeatResponse.fromJson(Map<String, dynamic> json) => SeatResponse(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        seatRow: json['seatRow'] ?? '',
        seatNumber: json['seatNumber'] ?? 0,
        active: json['active'] ?? json['isActive'] ?? true,
        seatTypeId: json['seatTypeId'] ?? '',
        seatTypeName: json['seatTypeName'],
        priceModifier: (json['priceModifier'] ?? 0).toDouble(),
      );
}

// ─── Room Service ─────────────────────────────────────────────────────────

class RoomService {
  RoomService._();
  static final RoomService instance = RoomService._();

  final Dio _dio = DioClient.instance;

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return data['data'];
    }
    return data;
  }

  PaginatedResponse<RoomResponse> _page(dynamic data) {
    final raw = _unwrap(data);
    if (raw is Map<String, dynamic>) {
      final d = raw;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<RoomResponse>(
        content: items
            .map((e) => RoomResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return const PaginatedResponse<RoomResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /rooms — Lấy danh sách phòng chiếu
  Future<PaginatedResponse<RoomResponse>> getAll({
    int page = 1,
    int size = 20,
    String? keyword,
  }) async {
    final resolvedPage = page > 0 ? page - 1 : 0;
    final response = await _dio.get(RoomPaths.base,
        queryParameters: {
          'page': resolvedPage,
          'size': size,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        });
    return _page(response.data);
  }

  /// GET /rooms/{id} — Lấy thông tin phòng chiếu
  Future<RoomResponse> getById(String id) async {
    final response = await _dio.get(RoomPaths.byId(id));
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return RoomResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return RoomResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /rooms — Tạo phòng chiếu mới (ADMIN)
  Future<RoomResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(RoomPaths.base, data: data);
    final d = response.data;
    if (d is Map<String, dynamic> && d['data'] != null) {
      return RoomResponse.fromJson(d['data'] as Map<String, dynamic>);
    }
    return RoomResponse.fromJson(d as Map<String, dynamic>);
  }

  /// PUT /rooms/{id} — Cập nhật phòng chiếu (ADMIN)
  Future<RoomResponse> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(RoomPaths.byId(id), data: data);
    final d = response.data;
    if (d is Map<String, dynamic> && d['data'] != null) {
      return RoomResponse.fromJson(d['data'] as Map<String, dynamic>);
    }
    return RoomResponse.fromJson(d as Map<String, dynamic>);
  }

  /// DELETE /rooms/{id} — Xóa phòng chiếu (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(RoomPaths.byId(id));
  }

  /// PATCH /rooms/{id}/toggle-status — Bật/tắt trạng thái phòng chiếu (ADMIN)
  Future<void> toggleStatus(String id) async {
    await _dio.patch(RoomPaths.toggleStatus(id));
  }

  /// GET /cinema/{cinemaId}/rooms — Lấy danh sách phòng theo rạp
  Future<List<RoomResponse>> getByCinema(String cinemaId, {
    int page = 1,
    int size = 20,
    String? keyword,
  }) async {
    final result = await getByCinemaPaginated(
      cinemaId,
      page: page,
      size: size,
      keyword: keyword,
    );
    return result.content;
  }

  Future<PaginatedResponse<RoomResponse>> getByCinemaPaginated(
    String cinemaId, {
    int page = 1,
    int size = 20,
    String? keyword,
  }) async {
    final resolvedPage = page > 0 ? page - 1 : 0;
    final response = await _dio.get(
      RoomPaths.byCinema(cinemaId),
      queryParameters: {
        'page': resolvedPage,
        'size': size,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      },
    );
    return _page(response.data);
  }
}

// ─── Seat Service ─────────────────────────────────────────────────────────

class SeatService {
  SeatService._();
  static final SeatService instance = SeatService._();

  final Dio _dio = DioClient.instance;

  List<SeatResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => SeatResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => SeatResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => SeatResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /seats/rooms/{roomId} — Lấy danh sách ghế theo phòng chiếu
  Future<List<SeatResponse>> getByRoom(String roomId) async {
    final response = await _dio.get(SeatPaths.byRoom(roomId));
    return _parseList(response.data);
  }

  /// GET /seats/{seatId} — Lấy thông tin ghế
  Future<SeatResponse> getById(String seatId) async {
    final response = await _dio.get(SeatPaths.byId(seatId));
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return SeatResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return SeatResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /seats — Tạo ghế mới (ADMIN)
  Future<SeatResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(SeatPaths.base, data: data);
    final d = response.data;
    if (d is Map<String, dynamic> && d['data'] != null) {
      return SeatResponse.fromJson(d['data'] as Map<String, dynamic>);
    }
    return SeatResponse.fromJson(d as Map<String, dynamic>);
  }

  /// POST /seats/rooms/{roomId}/bulk — Tạo nhiều ghế (ADMIN)
  Future<List<SeatResponse>> bulkCreate(String roomId, Map<String, dynamic> data) async {
    final response = await _dio.post(SeatPaths.bulkByRoom(roomId), data: data);
    return _parseList(response.data);
  }

  /// PUT /seats/{seatId} — Cập nhật thông tin ghế (ADMIN)
  Future<SeatResponse> update(String seatId, Map<String, dynamic> data) async {
    final response = await _dio.put(SeatPaths.byId(seatId), data: data);
    final d = response.data;
    if (d is Map<String, dynamic> && d['data'] != null) {
      return SeatResponse.fromJson(d['data'] as Map<String, dynamic>);
    }
    return SeatResponse.fromJson(d as Map<String, dynamic>);
  }

  /// DELETE /seats/{seatId} — Xóa ghế (ADMIN)
  Future<void> delete(String seatId) async {
    await _dio.delete(SeatPaths.byId(seatId));
  }
}

// ─── SeatType Service ─────────────────────────────────────────────────────

class SeatTypeService {
  SeatTypeService._();
  static final SeatTypeService instance = SeatTypeService._();

  final Dio _dio = DioClient.instance;

  List<SeatTypeResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => SeatTypeResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => SeatTypeResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /seat-types — Lấy tất cả loại ghế
  Future<List<SeatTypeResponse>> getAll() async {
    final response = await _dio.get(SeatTypePaths.base);
    return _parseList(response.data);
  }

  /// GET /seat-types/{id} — Lấy loại ghế theo ID
  Future<SeatTypeResponse> getById(String id) async {
    final response = await _dio.get(SeatTypePaths.byId(id));
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return SeatTypeResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return SeatTypeResponse.fromJson(data as Map<String, dynamic>);
  }
}
