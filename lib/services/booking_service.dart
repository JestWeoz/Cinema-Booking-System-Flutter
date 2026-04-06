import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/booking_model.dart';
import 'package:cinema_booking_system_app/models/responses/booking_response.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final Dio _dio = DioClient.instance;

  // ─── Internal helpers ─────────────────────────────────────────────────────

  /// Unwrap nested "data" envelope if present
  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final inner = map['data'];
    if (inner is Map<String, dynamic>) return inner;
    return map;
  }

  List<BookingModel> _parseList(dynamic data) {
    List raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        raw = inner;
      } else if (inner is Map<String, dynamic>) {
        final items = inner['items'];
        if (items is List) raw = items;
      } else if (data['content'] is List) {
        raw = data['content'] as List;
      }
    }
    return raw
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  BookingModel _parse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return BookingModel.fromJson(_unwrap(data));
    }
    return BookingModel.fromJson(data as Map<String, dynamic>);
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// POST /bookings — Tạo đặt vé mới
  /// Returns [BookingResponse] với đầy đủ thông tin (paymentUrl, tickets, v.v.)
  Future<BookingResponse> createBookingFull({
    required String showtimeId,
    required List<String> seatIds,
    required String paymentMethod,
    String? promotionCode,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await _dio.post(
      BookingPaths.base,
      data: {
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        'paymentMethod': paymentMethod,
        if (promotionCode != null) 'promotionCode': promotionCode,
        if (items != null) 'items': items,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return BookingResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return BookingResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /bookings — Tạo đặt vé (legacy — trả về BookingModel)
  Future<BookingModel> createBooking({
    required String showtimeId,
    required List<String> seatIds,
    required String paymentMethod,
    String? promotionCode,
    List<Map<String, dynamic>>? items,
  }) async {
    final response = await _dio.post(
      BookingPaths.base,
      data: {
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        'paymentMethod': paymentMethod,
        if (promotionCode != null) 'promotionCode': promotionCode,
        if (items != null) 'items': items,
      },
    );
    return _parse(response.data);
  }

  /// GET /bookings/my — Lấy vé của tôi
  Future<List<BookingModel>> getMyBookings() async {
    final response = await _dio.get(BookingPaths.my);
    return _parseList(response.data);
  }

  /// GET /bookings/{bookingId} — Chi tiết đặt vé (full BookingResponse)
  Future<BookingResponse> getDetailById(String id) async {
    final response = await _dio.get(BookingPaths.byId(id));
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return BookingResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return BookingResponse.fromJson(data as Map<String, dynamic>);
  }

  /// GET /bookings/{bookingId} — Chi tiết đặt vé (legacy BookingModel)
  Future<BookingModel> getById(String id) async {
    final response = await _dio.get(BookingPaths.byId(id));
    return _parse(response.data);
  }

  /// PATCH /bookings/{bookingId}/cancel — Hủy đặt vé
  Future<void> cancelBooking(String id) async {
    await _dio.patch(BookingPaths.cancel(id));
  }
}
