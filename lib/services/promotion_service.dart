import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';

class PromotionService {
  PromotionService._();
  static final PromotionService instance = PromotionService._();

  final Dio _dio = DioClient.instance;

  List<PromotionResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => PromotionResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => PromotionResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      if (d['items'] is List) {
        return (d['items'] as List)
            .map((e) => PromotionResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  PromotionResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return PromotionResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return PromotionResponse.fromJson(data as Map<String, dynamic>);
  }

  PaginatedResponse<PromotionResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<PromotionResponse>(
        content: items
            .map((e) => PromotionResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return PaginatedResponse<PromotionResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /promotions/active — Lấy khuyến mãi đang hoạt động cho người dùng
  Future<List<PromotionResponse>> getActive() async {
    final response = await _dio.get(PromotionPaths.active);
    return _parseList(response.data);
  }

  /// GET /promotions — Lấy tất cả khuyến mãi (ADMIN, phân trang)
  Future<PaginatedResponse<PromotionResponse>> getAll({
    int page = 1,
    int size = 10,
  }) async {
    final response = await _dio.get(PromotionPaths.base,
        queryParameters: {'page': page, 'size': size});
    return _page(response.data);
  }

  /// GET /promotions/{id} — Lấy chi tiết khuyến mãi
  Future<PromotionResponse> getById(String id) async {
    final response = await _dio.get(PromotionPaths.byId(id));
    return _parse(response.data);
  }

  /// GET /promotions/code/{code} — Lấy chi tiết khuyến mãi theo code
  Future<PromotionResponse> getByCode(String code) async {
    final response = await _dio.get(PromotionPaths.byCode(code));
    return _parse(response.data);
  }

  /// POST /promotions — Tạo khuyến mãi mới (ADMIN)
  Future<PromotionResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(PromotionPaths.base, data: data);
    return _parse(response.data);
  }

  /// PUT /promotions/{id} — Cập nhật khuyến mãi (ADMIN)
  Future<PromotionResponse> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(PromotionPaths.byId(id), data: data);
    return _parse(response.data);
  }

  /// DELETE /promotions/{id} — Xóa khuyến mãi (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(PromotionPaths.byId(id));
  }

  /// POST /promotions/apply — Áp dụng khuyến mãi
  Future<Map<String, dynamic>> apply({
    required String code,
    required double orderTotal,
  }) async {
    final response = await _dio.post(
      PromotionPaths.apply,
      data: {'code': code, 'orderTotal': orderTotal},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /promotions/preview — Xem trước khuyến mãi
  Future<Map<String, dynamic>> preview({
    required String code,
    required double orderTotal,
  }) async {
    final response = await _dio.post(
      PromotionPaths.preview,
      data: {'code': code, 'orderTotal': orderTotal},
    );
    return response.data as Map<String, dynamic>;
  }
}
