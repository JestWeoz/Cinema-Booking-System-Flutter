// ignore_for_file: comment_references

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final Dio _dio = DioClient.instance;

  List<ProductResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      if (d['items'] is List) {
        return (d['items'] as List)
            .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (d['content'] is List) {
        return (d['content'] as List)
            .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  ProductResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return ProductResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return ProductResponse.fromJson(data as Map<String, dynamic>);
  }

  PaginatedResponse<ProductResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<ProductResponse>(
        content: items
            .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return const PaginatedResponse<ProductResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /products/active — Lấy danh sách sản phẩm đang hoạt động cho người dùng
  Future<List<ProductResponse>> getActive() async {
    final response = await _dio.get(ProductPaths.active);
    return _parseList(response.data);
  }

  /// GET /products — Lấy danh sách sản phẩm (ADMIN)
  Future<PaginatedResponse<ProductResponse>> getAll({
    int page = 0,
    int size = 10,
    String? keyword,
  }) async {
    final response = await _dio.get(ProductPaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    return _page(response.data);
  }

  /// GET /products/{id} — Lấy chi tiết sản phẩm
  Future<ProductResponse> getById(String id) async {
    final response = await _dio.get(ProductPaths.byId(id));
    return _parse(response.data);
  }

  /// POST /products — Tạo sản phẩm mới (ADMIN)
  Future<ProductResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(ProductPaths.base, data: data);
    return _parse(response.data);
  }

  /// PUT /products/{id} — Cập nhật sản phẩm (ADMIN)
  Future<ProductResponse> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ProductPaths.byId(id), data: data);
    return _parse(response.data);
  }

  /// DELETE /products/{id} — Xóa sản phẩm (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(ProductPaths.byId(id));
  }

  /// PATCH /products/{id}/toggle-active — Chuyển trạng thái hoạt động (ADMIN)
  Future<void> toggleActive(String id) async {
    await _dio.patch(ProductPaths.toggleActive(id));
  }

  // ─── Upload-integrated helpers ─────────────────────────────────────

  /// Mở picker → upload ảnh sản phẩm → trả URL
  Future<String?> pickAndUploadImage({
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) =>
      MediaUploadHelper.pickAndUploadImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        onUploading: onUploading,
        onError: onError,
      );

  /// Tạo sản phẩm kèm upload ảnh:
  /// Nếu [imageUrl] trong [data] trống rỗng, mở picker và upload trước
  Future<ProductResponse> createWithImage(
    Map<String, dynamic> data, {
    bool openPicker = true,
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) async {
    if (openPicker) {
      final url = await pickAndUploadImage(
        onUploading: onUploading,
        onError: onError,
      );
      if (url != null) data = {...data, 'image': url};
    }
    return create(data);
  }
}
