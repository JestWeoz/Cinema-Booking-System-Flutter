import 'package:cinema_booking_system_app/models/user_model.dart';

/// Response trả về từ /auth/login và /auth/register
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserModel? user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      user: userJson != null ? UserModel.fromJson(userJson) : null,
    );
  }
}
