import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';

class ComboService {
  ComboService._();
  static final ComboService instance = ComboService._();

  final Dio _dio = DioClient.instance;

  List<ComboResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => ComboResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => ComboResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      if (d['items'] is List) {
        return (d['items'] as List)
            .map((e) => ComboResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (d is List) {
        return (d as List)
            .map((e) => ComboResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  ComboResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return ComboResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return ComboResponse.fromJson(data as Map<String, dynamic>);
  }

  PaginatedResponse<ComboResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<ComboResponse>(
        content: items
            .map((e) => ComboResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return PaginatedResponse<ComboResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /combos/active — Lấy combo đang hoạt động cho người dùng
  Future<List<ComboResponse>> getActive() async {
    final response = await _dio.get(ComboPaths.active);
    return _parseList(response.data);
  }

  /// GET /combos — Lấy tất cả combo (ADMIN)
  Future<PaginatedResponse<ComboResponse>> getAll({
    int page = 1,
    int size = 10,
  }) async {
    final response = await _dio.get(ComboPaths.base, queryParameters: {
      'page': page,
      'size': size,
    });
    return _page(response.data);
  }

  /// GET /combos/{id} — Lấy combo theo id
  Future<ComboResponse> getById(String id) async {
    final response = await _dio.get(ComboPaths.byId(id));
    return _parse(response.data);
  }

  /// POST /combos — Tạo combo (ADMIN)
  Future<ComboResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(ComboPaths.base, data: data);
    return _parse(response.data);
  }

  /// PUT /combos/{id} — Cập nhật combo (ADMIN)
  Future<ComboResponse> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ComboPaths.byId(id), data: data);
    return _parse(response.data);
  }

  /// DELETE /combos/{id} — Xóa combo (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(ComboPaths.byId(id));
  }

  /// PATCH /combos/{comboId}/toggle-active — Chuyển trạng thái hoạt động của combo (ADMIN)
  Future<void> toggleActive(String comboId) async {
    await _dio.patch(ComboPaths.toggleActive(comboId));
  }

  // ─── Upload-integrated helpers ─────────────────────────────────────

  /// Mở picker → upload ảnh combo → trả URL
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

  /// Tạo combo kèm upload ảnh:
  Future<ComboResponse> createWithImage(
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
      if (url != null) data = {...data, 'imageUrl': url};
    }
    return create(data);
  }
}
