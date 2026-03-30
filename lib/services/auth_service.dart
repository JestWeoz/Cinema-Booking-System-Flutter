import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/storage_keys.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';
import 'package:cinema_booking_system_app/models/requests/login_request.dart';
import 'package:cinema_booking_system_app/models/requests/register_request.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final Dio _dio = DioClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Lưu token sau khi login/register
  Future<void> _saveTokens(AuthResponse authResponse) async {
    await _storage.write(key: StorageKeys.accessToken, value: authResponse.accessToken);
    if (authResponse.refreshToken != null) {
      await _storage.write(key: StorageKeys.refreshToken, value: authResponse.refreshToken!);
    }
  }

  /// Đăng nhập
  Future<UserModel> login(LoginRequest request) async {
    final response = await _dio.post('/auth/login', data: request.toJson());
    final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(authResponse);
    return authResponse.user ??
        await getCurrentUser() ??
        UserModel(
          id: '',
          name: request.email.split('@').first,
          email: request.email,
          createdAt: DateTime.now(),
        );
  }

  /// Đăng ký
  Future<UserModel> register(RegisterRequest request) async {
    final response = await _dio.post('/auth/register', data: request.toJson());
    final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _saveTokens(authResponse);
    return authResponse.user ??
        UserModel(
          id: '',
          name: request.name,
          email: request.email,
          createdAt: DateTime.now(),
        );
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
  }

  /// Lấy thông tin user hiện tại
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
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
