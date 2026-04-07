import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';

// ─── Response Models ──────────────────────────────────────────────────────

class PeopleResponse {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? biography;
  final String? dob; // ISO date
  final String? nationality;

  const PeopleResponse({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.biography,
    this.dob,
    this.nationality,
  });

  factory PeopleResponse.fromJson(Map<String, dynamic> json) => PeopleResponse(
        id: json['id'] ?? '',
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
        avatarUrl: ImageUrlResolver.pick(json, keys: const ['avatarUrl']),
      biography: json['biography']?.toString(),
      dob: json['dob']?.toString(),
      nationality: (json['nationality'] ?? json['nation'])?.toString(),
      );
}

// ─── Service ──────────────────────────────────────────────────────────────

class PeopleService {
  PeopleService._();
  static final PeopleService instance = PeopleService._();

  final Dio _dio = DioClient.instance;


  PeopleResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return PeopleResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return PeopleResponse.fromJson(data as Map<String, dynamic>);
  }

  PaginatedResponse<PeopleResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<PeopleResponse>(
        content: items
            .map((e) => PeopleResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return PaginatedResponse<PeopleResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /people — Lấy danh sách người tham gia
  Future<PaginatedResponse<PeopleResponse>> getAll({
    int page = 0,
    int size = 20,
    String? keyword,
  }) async {
    final response = await _dio.get(PeoplePaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (keyword != null && keyword.isNotEmpty) 'key': keyword,
    });
    return _page(response.data);
  }

  /// GET /people/{id} — Lấy thông tin người tham gia theo ID
  Future<PeopleResponse> getById(String id) async {
    final response = await _dio.get(PeoplePaths.byId(id));
    return _parse(response.data);
  }

  /// POST /people — Tạo người tham gia mới (ADMIN)
  Future<PeopleResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(PeoplePaths.base, data: data);
    return _parse(response.data);
  }

  /// PUT /people/{id} — Cập nhật người tham gia (ADMIN)
  Future<PeopleResponse> update(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(PeoplePaths.byId(id), data: data);
    return _parse(response.data);
  }

  /// DELETE /people/{id}  /// Xóa người tham gia (ADMIN)
  Future<void> delete(String id) async {
    await _dio.delete(PeoplePaths.byId(id));
  }

  /// Lấy phìm của người tham gia
  Future<List<Map<String, dynamic>>> getMoviesByPeople(String peopleId) async {
    final response = await _dio.get(PeoplePaths.moviesByPeople(peopleId));
    final data = response.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ─── Upload-integrated helpers ────────────────────────────────────────

  /// Mở picker → upload avatar diễn viên/đạo diễn lên Cloudinary → trả URL
  Future<String?> pickAndUploadAvatar({
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) =>
      MediaUploadHelper.pickAndUploadImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
        onUploading: onUploading,
        onError: onError,
      );

  /// Tạo người tham gia và upload avatar trong một bước:
  /// Nếu [avatarFilePath] == null thì sử dụng [data]['avatarUrl'] sẵn có nếu có
  Future<PeopleResponse> createWithAvatar(
    Map<String, dynamic> data, {
    String? avatarFilePath,
    void Function(bool)? onUploading,
    void Function(String)? onError,
  }) async {
    if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
      final url = await MediaUploadHelper.pickAndUploadImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
        onUploading: onUploading,
        onError: onError,
      );
      if (url != null) data = {...data, 'avatarUrl': url};
    }
    return create(data);
  }
}
