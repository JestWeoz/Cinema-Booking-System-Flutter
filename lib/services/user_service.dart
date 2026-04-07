import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final Dio _dio = DioClient.instance;

  UserResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return UserResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return UserResponse.fromJson(data as Map<String, dynamic>);
  }

  PaginatedResponse<UserResponse> _page(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map) {
      final d = data['data'] as Map<String, dynamic>;
      final items = d['items'] as List? ?? [];
      return PaginatedResponse<UserResponse>(
        content: items
            .map((e) => UserResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: d['totalElements'] ?? 0,
        totalPages: d['totalPages'] ?? 1,
        number: d['page'] ?? 0,
        size: d['size'] ?? 10,
        first: (d['page'] ?? 0) == 0,
        last: true,
      );
    }
    return PaginatedResponse<UserResponse>(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: 0,
      size: 10,
      first: true,
      last: true,
    );
  }

  /// GET /users/me — Lấy thông tin người dùng hiện tại
  Future<UserResponse> getMe() async {
    final response = await _dio.get(UserPaths.me);
    return _parse(response.data);
  }

  /// PUT /users/me — Cập nhật hồ sơ
  Future<UserResponse> updateMe(UpdateProfileRequest request) async {
    final response = await _dio.put(UserPaths.me, data: request.toJson());
    return _parse(response.data);
  }

  /// PUT /users/change-avatar — Cập nhật avatar
  Future<UserResponse> changeAvatar(ChangeAvatarRequest request) async {
    final response =
        await _dio.put(UserPaths.changeAvatar, data: request.toJson());
    return _parse(response.data);
  }

  /// PUT /users/change-password — Đổi mật khẩu
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _dio.put(UserPaths.changePassword, data: request.toJson());
  }

  /// GET /users — Lấy danh sách người dùng (ADMIN)
  Future<PaginatedResponse<UserResponse>> getAll({
    int page = 0,
    int size = 10,
    String? key,
  }) async {
    final response = await _dio.get(UserPaths.base, queryParameters: {
      'page': page,
      'size': size,
      if (key != null && key.isNotEmpty) 'key': key,
    });
    return _page(response.data);
  }

  /// GET /users/{id} — Lấy người dùng theo id (ADMIN)
  Future<UserResponse> getById(String id) async {
    final response = await _dio.get(UserPaths.byId(id));
    return _parse(response.data);
  }

  /// GET /users/{username} — Lấy người dùng theo username (ADMIN)
  Future<UserResponse> getByUsername(String username) async {
    final response = await _dio.get(UserPaths.byUsername(username));
    return _parse(response.data);
  }

  /// GET /users/staff — Lấy danh sách nhân viên (ADMIN)
  Future<PaginatedResponse<UserResponse>> getStaff({
    int page = 0,
    int size = 10,
    String? key,
  }) async {
    final response = await _dio.get(UserPaths.staff, queryParameters: {
      'page': page,
      'size': size,
      if (key != null && key.isNotEmpty) 'key': key,
    });
    return _page(response.data);
  }

  /// POST /users — Tạo người dùng mới (ADMIN)
  Future<UserResponse> create(Map<String, dynamic> data) async {
    final response = await _dio.post(UserPaths.base, data: data);
    return _parse(response.data);
  }

  /// PUT /users/lock/{id} — Khóa người dùng (ADMIN)
  Future<void> lock(String id) async {
    await _dio.put(UserPaths.lock(id));
  }

  /// PUT /users/unlock/{id} — Mở khóa người dùng (ADMIN)
  Future<void> unlock(String id) async {
    await _dio.put(UserPaths.unlock(id));
  }
}
