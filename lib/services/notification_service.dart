import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final Dio _dio = DioClient.instance;

  List<NotificationResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => NotificationResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => NotificationResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => NotificationResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /notifications — Lấy thông báo của tôi
  Future<List<NotificationResponse>> getMyNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      NotificationPaths.base,
      queryParameters: {'page': page, 'size': size},
    );
    return _parseList(response.data);
  }

  /// GET /notifications/{id} — Lấy chi tiết thông báo
  Future<NotificationResponse> getById(String id) async {
    final response = await _dio.get(NotificationPaths.byId(id));
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return NotificationResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return NotificationResponse.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /notifications/{id}/read — Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(String id) async {
    await _dio.patch(NotificationPaths.markRead(id));
  }

  /// PATCH /notifications/mark-all-read — Đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead() async {
    await _dio.patch(NotificationPaths.markAllRead);
  }

  /// GET /notifications/unread-count — Đếm số lượng thông báo chưa đọc
  Future<int> getUnreadCount() async {
    final response = await _dio.get(NotificationPaths.unreadCount);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data'] ?? data['count'] ?? 0) as int;
    }
    if (data is int) return data;
    return 0;
  }
}
