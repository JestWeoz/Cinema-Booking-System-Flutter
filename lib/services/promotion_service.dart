import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';

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
    // Handle nested data structure
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

  /// GET /promotions/active — Lấy khuyến mãi đang hoạt động cho người dùng
  Future<List<PromotionResponse>> getActive() async {
    final response = await _dio.get(PromotionPaths.active);
    return _parseList(response.data);
  }

  /// GET /promotions/{id} — Lấy chi tiết khuyến mãi
  Future<PromotionResponse> getById(String id) async {
    final response = await _dio.get(PromotionPaths.byId(id));
    return PromotionResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /promotions/code/{code} — Lấy chi tiết khuyến mãi theo code
  Future<PromotionResponse> getByCode(String code) async {
    final response = await _dio.get(PromotionPaths.byCode(code));
    return PromotionResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /promotions/apply — Áp dụng khuyến mãi
  Future<Map<String, dynamic>> apply({
    required String code,
    required double orderTotal,
  }) async {
    final response = await _dio.post(
      PromotionPaths.apply,
      data: {
        'code': code,
        'orderTotal': orderTotal,
      },
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
      data: {
        'code': code,
        'orderTotal': orderTotal,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
