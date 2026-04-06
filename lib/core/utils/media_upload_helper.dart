
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cinema_booking_system_app/services/cloudinary_service.dart';

/// Kết quả upload — chứa URL cuối cùng từ Cloudinary
class UploadResult {
  final String url;
  const UploadResult(this.url);
}

/// Helper tập trung cho toàn bộ flow: chọn file → upload → trả URL
///
/// Cách dùng (trong một StatefulWidget, ví dụ):
/// ```dart
/// final url = await MediaUploadHelper.pickAndUploadImage(
///   source: ImageSource.gallery,
///   onUploading: (v) => setState(() => _uploading = v),
/// );
/// if (url != null) setState(() => avatarUrl = url);
/// ```
class MediaUploadHelper {
  MediaUploadHelper._();

  static final _picker = ImagePicker();

  // ─── Image ────────────────────────────────────────────────────────────────

  /// Mở picker ảnh, upload lên Cloudinary, trả về URL.
  /// Trả về `null` nếu user huỷ hoặc upload thất bại.
  static Future<String?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth = 1280,
    double? maxHeight = 1280,
    int? imageQuality = 85,
    void Function(bool uploading)? onUploading,
    void Function(String error)? onError,
  }) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      if (picked == null) return null;

      onUploading?.call(true);

      final MultipartFile multipart;
      if (kIsWeb) {
        // Web: dùng bytes
        final bytes = await picked.readAsBytes();
        multipart = MultipartFile.fromBytes(
          bytes,
          filename: picked.name,
        );
      } else {
        // Mobile/Desktop: dùng path
        multipart = await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        );
      }

      final url = await CloudinaryService.instance.uploadImage(multipart);
      return url.isNotEmpty ? url : null;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    } finally {
      onUploading?.call(false);
    }
  }

  // ─── Multiple Images ──────────────────────────────────────────────────────

  /// Chọn nhiều ảnh cùng lúc, upload tuần tự, trả về danh sách URL.
  static Future<List<String>> pickAndUploadMultipleImages({
    int? imageQuality = 85,
    void Function(bool uploading)? onUploading,
    void Function(int done, int total)? onProgress,
    void Function(String error)? onError,
  }) async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: imageQuality,
      );
      if (picked.isEmpty) return [];

      onUploading?.call(true);
      final List<String> urls = [];

      for (int i = 0; i < picked.length; i++) {
        final xFile = picked[i];
        try {
          final MultipartFile multipart;
          if (kIsWeb) {
            final bytes = await xFile.readAsBytes();
            multipart = MultipartFile.fromBytes(bytes, filename: xFile.name);
          } else {
            multipart = await MultipartFile.fromFile(
              xFile.path,
              filename: xFile.name,
            );
          }
          final url = await CloudinaryService.instance.uploadImage(multipart);
          if (url.isNotEmpty) urls.add(url);
          onProgress?.call(i + 1, picked.length);
        } catch (e) {
          onError?.call('Lỗi upload ảnh ${xFile.name}: $e');
        }
      }

      return urls;
    } catch (e) {
      onError?.call(e.toString());
      return [];
    } finally {
      onUploading?.call(false);
    }
  }

  // ─── Video ────────────────────────────────────────────────────────────────

  /// Mở picker video, upload lên Cloudinary, trả về URL.
  static Future<String?> pickAndUploadVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
    void Function(bool uploading)? onUploading,
    void Function(String error)? onError,
  }) async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      if (picked == null) return null;

      onUploading?.call(true);

      final MultipartFile multipart;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        multipart = MultipartFile.fromBytes(bytes, filename: picked.name);
      } else {
        multipart = await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        );
      }

      final url = await CloudinaryService.instance.uploadVideo(multipart);
      return url.isNotEmpty ? url : null;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    } finally {
      onUploading?.call(false);
    }
  }

  // ─── Convenience: chỉ upload bytes (dùng khi đã có bytes) ─────────────────

  /// Upload raw bytes ảnh — hữu ích khi đã có bytes từ camera/crop
  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'upload.jpg',
    void Function(bool uploading)? onUploading,
    void Function(String error)? onError,
  }) async {
    try {
      onUploading?.call(true);
      final multipart = MultipartFile.fromBytes(bytes, filename: filename);
      final url = await CloudinaryService.instance.uploadImage(multipart);
      return url.isNotEmpty ? url : null;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    } finally {
      onUploading?.call(false);
    }
  }
}
