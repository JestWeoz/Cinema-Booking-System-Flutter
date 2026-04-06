import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  final Dio _dio = DioClient.instance;

  String _extractUrl(dynamic raw) {
    if (raw == null) {
      return '';
    }
    if (raw is String) {
      return ImageUrlResolver.normalize(raw) ?? '';
    }
    if (raw is Map<String, dynamic>) {
      final direct = ImageUrlResolver.pick(
        raw,
        keys: const ['url', 'secureUrl', 'secure_url', 'imageUrl'],
      );
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
      return _extractUrl(raw['data']);
    }
    if (raw is List) {
      for (final item in raw) {
        final url = _extractUrl(item);
        if (url.isNotEmpty) {
          return url;
        }
      }
    }
    return '';
  }

  /// POST /cloudinary/upload/image — Upload ảnh lên Cloudinary
  /// [file] là MultipartFile từ dio
  Future<String> uploadImage(MultipartFile file) async {
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post(
      CloudinaryPaths.uploadImage,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _extractUrl(response.data);
  }

  /// POST /cloudinary/upload/video — Upload video lên Cloudinary
  Future<String> uploadVideo(MultipartFile file) async {
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post(
      CloudinaryPaths.uploadVideo,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _extractUrl(response.data);
  }

  /// DELETE /cloudinary/delete — Xóa file trên Cloudinary
  Future<void> delete(String publicId) async {
    await _dio.delete(
      CloudinaryPaths.delete,
      data: {'publicId': publicId},
    );
  }
}
