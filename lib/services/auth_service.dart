import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/constants/storage_keys.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/models/requests/auth_requests.dart';
import 'package:cinema_booking_system_app/models/requests/user_requests.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/models/user_model.dart';

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

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final inner = map['data'];
    if (inner is Map<String, dynamic>) return inner;
    return map;
  }

  UserModel _toUserModel(UserResponse userResp) {
    return UserModel(
      id: userResp.id,
      name:
          userResp.fullName.isNotEmpty ? userResp.fullName : userResp.username,
      email: userResp.email,
      phone: userResp.phone,
      avatarUrl: userResp.avatarUrl,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel> login(LoginRequest request) async {
    final response = await _dio.post(AuthPaths.login, data: request.toJson());
    final loginResponse = LoginResponse.fromJson(_unwrap(response.data));
    if (loginResponse.accessToken != null) {
      await _saveTokens(loginResponse.accessToken!);
    }

    final user = await getCurrentUser();
    if (user != null) return user;

    final info = loginResponse.userInfoResponse;
    return UserModel(
      id: '',
      name: info != null && info.fullName.isNotEmpty
          ? info.fullName
          : request.username,
      email: info?.email ?? '',
      phone: info?.phone,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel> register(RegisterRequest request) async {
    final response =
        await _dio.post(AuthPaths.register, data: request.toJson());
    final registerResponse = RegisterResponse.fromJson(_unwrap(response.data));
    if (registerResponse.accessToken != null) {
      await _saveTokens(registerResponse.accessToken!);
    }

    final user = registerResponse.user;
    if (user != null) {
      await _saveRoles(user.roles);
      return _toUserModel(user);
    }

    return UserModel(
      id: '',
      name: request.fullName.isNotEmpty ? request.fullName : request.username,
      email: request.email,
      phone: request.phone,
      createdAt: DateTime.now(),
    );
  }

  Future<void> logout() async {
    final token = await _storage.read(key: StorageKeys.accessToken) ?? '';
    final request = LogoutRequest(token: token);
    try {
      await _dio.post(
        AuthPaths.logout,
        data: request.toJson(),
        options: Options(
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<UserResponse?> getCurrentUserResponse() async {
    try {
      final response = await _dio.get(UserPaths.me);
      final data = _unwrap(response.data);
      final userResp = UserResponse.fromJson(data);
      await _saveRoles(userResp.roles);
      return userResp;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final userResp = await getCurrentUserResponse();
    if (userResp == null) return null;
    return _toUserModel(userResp);
  }

  Future<UserModel?> updateProfile(UpdateProfileRequest request) async {
    final response = await _dio.put(UserPaths.me, data: request.toJson());
    final userResp = UserResponse.fromJson(_unwrap(response.data));
    await _saveRoles(userResp.roles);
    return _toUserModel(userResp);
  }

  Future<UserModel?> changeAvatar(ChangeAvatarRequest request) async {
    final response =
        await _dio.put(UserPaths.changeAvatar, data: request.toJson());
    final userResp = UserResponse.fromJson(_unwrap(response.data));
    await _saveRoles(userResp.roles);
    return _toUserModel(userResp);
  }

  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: StorageKeys.userRoles);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  Future<bool> isAdmin() async {
    final roles = await getRoles();
    return roles.any((r) => r.toUpperCase().contains('ADMIN'));
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    await _dio.put(UserPaths.changePassword, data: request.toJson());
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    await _dio.post(AuthPaths.forgotPassword, data: request.toJson());
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }
}
