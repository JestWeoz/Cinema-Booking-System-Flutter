// User Requests — khớp với backend DTO/Request/User/
import '../enums.dart';


class UpdateProfileRequest {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? dob; // ISO date string: "yyyy-MM-dd"
  final Gender? gender;

  const UpdateProfileRequest({
    this.fullName,
    this.email,
    this.phone,
    this.dob,
    this.gender,
  });

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender!.name,
      };
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ChangeAvatarRequest {
  // Multipart form-data — file sẽ được gửi riêng qua FormData
  // Class này chỉ là placeholder
  const ChangeAvatarRequest();
}
