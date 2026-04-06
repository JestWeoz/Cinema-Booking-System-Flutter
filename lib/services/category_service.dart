import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final Dio _dio = DioClient.instance;

  List<CategoryResponse> _parseList(dynamic data) {
    // Case 1: direct list
    if (data is List) {
      return data
          .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      // Case 2: { "data": { "items": [...] } }  ← cấu trúc thực tế của backend
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        final list = inner['items'] ?? inner['content'];
        if (list is List) {
          return list
              .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      // Case 3: { "data": [...] }
      if (inner is List) {
        return inner
            .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Case 4: { "content": [...] }  (Spring Data style)
      final content = data['content'];
      if (content is List) {
        return content
            .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Case 5: { "items": [...] }
      final items = data['items'];
      if (items is List) {
        return items
            .map((e) => CategoryResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// GET /categories — Lấy tất cả thể loại
  Future<List<CategoryResponse>> getAll() async {
    final response = await _dio.get(CategoryPaths.base);
    return _parseList(response.data);
  }

  /// GET /categories/{id} — Lấy chi tiết thể loại
  Future<CategoryResponse> getById(String id) async {
    final response = await _dio.get(CategoryPaths.byId(id));
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return CategoryResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return CategoryResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /categories — Thêm thể loại mới (ADMIN)
  Future<CategoryResponse> create(String name) async {
    final response = await _dio.post(CategoryPaths.base, data: {'name': name});
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return CategoryResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return CategoryResponse.fromJson(data as Map<String, dynamic>);
  }

  /// PUT /categories/{id} — Cập nhật thể loại (ADMIN)
  Future<CategoryResponse> update(String id, String name) async {
    final response = await _dio.put(CategoryPaths.byId(id), data: {'name': name});
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return CategoryResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return CategoryResponse.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /categories/{id} — Xóa thể loại (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(CategoryPaths.byId(id));
  }
}
