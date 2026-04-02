import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/storage_keys.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';
import 'package:cinema_booking_system_app/models/requests/auth_requests.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Dio _dio = DioClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _saveTokens(String accessToken) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
  }

  Future<void> _saveRoles(List<String> roles) async {
    await _storage.write(key: StorageKeys.userRoles, value: jsonEncode(roles));
  }

  /// Backend trả về {success, code, data: {...}}
  /// Nếu có 'data' thì unwrap, không thì dùng luôn.
  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final inner = map['data'];
    if (inner is Map<String, dynamic>) return inner;
    return map;
  }

  /// Đăng nhập — sau đó fetch /users/me để lấy roles
  Future<UserModel> login(LoginRequest request) async {
    final response = await _dio.post('/auth/login', data: request.toJson());
    final loginResponse = LoginResponse.fromJson(_unwrap(response.data));
    if (loginResponse.accessToken != null) {
      await _saveTokens(loginResponse.accessToken!);
    }
    // Fetch full user info (includes roles)
    final user = await getCurrentUser();
    if (user != null) return user;
    final info = loginResponse.userInfoResponse;
    return UserModel(
      id: '',
      name: info != null && info.fullName.isNotEmpty ? info.fullName : request.username,
      email: info?.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Đăng ký
  Future<UserModel> register(RegisterRequest request) async {
    final response = await _dio.post('/auth/register', data: request.toJson());
    final registerResponse = RegisterResponse.fromJson(_unwrap(response.data));
    if (registerResponse.accessToken != null) {
      await _saveTokens(registerResponse.accessToken!);
      print(2);
    }
    final user = registerResponse.user;
    if (user != null) {
      await _saveRoles(user.roles);
      return UserModel(
        id: user.id,
        name: user.fullName.isNotEmpty ? user.fullName : user.username,
        email: user.email,
        createdAt: DateTime.now(),
      );
    }
    
    return UserModel(
      id: '',
      name: request.fullName.isNotEmpty ? request.fullName : request.username,
      email: request.email,
      createdAt: DateTime.now(),
    );
  }

  /// Đăng xuất
  Future<void> logout() async {
    final request = LogoutRequest(
      token: await _storage.read(key: StorageKeys.accessToken) ?? '',
    );
    try {
      await _dio.post('/auth/logout',data: request.toJson(),options: Options(headers: {'Authorization': 'Bearer ${request.token}'}));

    } catch (_) {}
    await _storage.deleteAll();
  }

  /// Lấy thông tin user hiện tại (đồng thời lưu roles)
  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: StorageKeys.accessToken);
      final response = await _dio.get(
        '/users/me',
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      final data = _unwrap(response.data);
      final userResp = UserResponse.fromJson(data);
      await _saveRoles(userResp.roles);
      return UserModel(
        id: userResp.id,
        name: userResp.fullName.isNotEmpty ? userResp.fullName : userResp.username,
        email: userResp.email,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lấy roles từ storage
  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: StorageKeys.userRoles);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  /// Kiểm tra có phải Admin không
  Future<bool> isAdmin() async {
    final roles = await getRoles();
    return roles.any((r) => r.toUpperCase().contains('ADMIN'));
  }

  /// Đổi mật khẩu
  Future<void> changePassword(ChangePasswordRequest request) async {
    await _dio.post('/users/change-password', data: request.toJson());
  }

  /// Quên mật khẩu
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    await _dio.post('/auth/forgot-password', data: request.toJson());
  }

  /// Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }
}
