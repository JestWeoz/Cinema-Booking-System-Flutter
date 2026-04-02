// Auth Requests — khớp với backend DTO/Request/Auth/

class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}
class RegisterRequest {
  final String username;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String email;
  final String phone;

  const RegisterRequest({
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'fullName': fullName,
        'email': email,
        'phone': phone,
      };
}

class RefreshTokenRequest {
  final String token;

  const RefreshTokenRequest({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}

class LogoutRequest {
  final String token;

  const LogoutRequest({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}

class ResetPasswordRequest {
  final String token;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

class IntrospectRequest {
  final String token;

  const IntrospectRequest({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}

