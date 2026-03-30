/// Generic API wrapper — Spring Boot thường trả về dạng:
/// { "status": 200, "message": "OK", "data": { ... } }
class ApiResponse<T> {
  final int? status;
  final String? message;
  final T? data;

  const ApiResponse({
    this.status,
    this.message,
    this.data,
  });

  bool get isSuccess => status != null && status! >= 200 && status! < 300;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse<T>(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : json['data'] as T?,
    );
  }
}
