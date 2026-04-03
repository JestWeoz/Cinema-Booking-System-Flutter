import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';

class CinemaService {
  CinemaService._();
  static final CinemaService instance = CinemaService._();

  final Dio _dio = DioClient.instance;

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
    // Handle nested data structure
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

  /// GET /cinema/{id} — Lấy chi tiết rạp
  Future<CinemaResponse> getById(String id) async {
    final response = await _dio.get(CinemaPaths.byId(id));
    return CinemaResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
