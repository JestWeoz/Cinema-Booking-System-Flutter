// Auth & User Responses — khớp với backend DTO/Response/Auth/ và DTO/Response/User/
import '../enums.dart';

// ─── Auth Responses ───────────────────────────────────────────────────────

class UserInfoResponse {
  final String username;
  final String fullName;
  final String email;
  final String phone;

  const UserInfoResponse({
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) =>
      UserInfoResponse(
        username: json['username'] ?? '',
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
      );
}

class LoginResponse {
  final String? accessToken;
  final UserInfoResponse? userInfoResponse;
  final String? error;
  final bool success;

  const LoginResponse({
    this.accessToken,
    this.userInfoResponse,
    this.error,
    required this.success,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: (json['AccessToken'] ?? json['accessToken']) as String?,
        userInfoResponse: json['userInfoResponse'] != null
            ? UserInfoResponse.fromJson(json['userInfoResponse'])
            : null,
        error: json['error'],
        success: json['success'] ?? false,
      );
}

class RefreshResponse {
  final bool? success;
  final String? accessToken;

  const RefreshResponse({this.success, this.accessToken});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      RefreshResponse(
        success: json['success'],
        accessToken: json['accessToken'],
      );
}

// ─── User Response ────────────────────────────────────────────────────────

class UserResponse {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? dob; // ISO date
  final Gender? gender;
  final bool status;
  final List<String> roles;

  const UserResponse({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.dob,
    this.gender,
    required this.status,
    required this.roles,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        avatarUrl: json['avatarUrl'],
        dob: json['dob'],
        gender: json['gender'] != null
            ? Gender.values.byName(json['gender'])
            : null,
        status: json['status'] ?? true,
        roles: List<String>.from(json['roles'] ?? []),
      );
}

class RegisterResponse {
  final String? accessToken;
  final UserResponse? user;
  final String? error;
  final bool success;

  const RegisterResponse({
    this.accessToken,
    this.user,
    this.error,
    required this.success,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => RegisterResponse(
        accessToken: json['AccessToken'],
        user: json['user'] != null
            ? UserResponse.fromJson(json['user'])
            : null,
        error: json['error'],
        success: json['success'] ?? false,
      );
}
