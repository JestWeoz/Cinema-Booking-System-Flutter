import 'package:dio/dio.dart';
import '../errors/failures.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add common headers or modify requests
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

/// Maps DioException to app Failure types
Failure dioExceptionToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final message = _extractMessage(e.response?.data) ?? e.message ?? 'Server error';
      return switch (statusCode) {
        401 => const UnauthorizedFailure(),
        403 => const ForbiddenFailure(),
        404 => const NotFoundFailure(),
        422 => ValidationFailure(message: message, statusCode: statusCode),
        _ => ServerFailure(message: message, statusCode: statusCode),
      };
    default:
      return const UnknownFailure();
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['message'] as String? ?? data['error'] as String?;
  }
  return null;
}
