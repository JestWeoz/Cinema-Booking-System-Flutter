import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

/// Automatically attaches Bearer token + handles token refresh
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final opts = err.requestOptions;
          final token = await _storage.read(key: StorageKeys.accessToken);
          opts.headers['Authorization'] = 'Bearer $token';
          final response = await dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Refresh failed – clear tokens
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    if (refreshToken == null) return false;
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final newToken = response.data['access_token'] as String?;
      if (newToken != null) {
        await _storage.write(key: StorageKeys.accessToken, value: newToken);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
