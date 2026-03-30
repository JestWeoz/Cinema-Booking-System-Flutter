import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/booking_model.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final Dio _dio = DioClient.instance;

  List<BookingModel> _parseList(dynamic data) {
    if (data is List) {
      return data.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Đặt vé
  Future<BookingModel> createBooking({
    required String showtimeId,
    required List<String> seatIds,
    required String paymentMethod,
    String? promotionCode,
  }) async {
    final response = await _dio.post(
      BookingPaths.base,
      data: {
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        'paymentMethod': paymentMethod,
        if (promotionCode != null) 'promotionCode': promotionCode,
      },
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Vé của tôi
  Future<List<BookingModel>> getMyBookings() async {
    final response = await _dio.get(BookingPaths.my);
    return _parseList(response.data);
  }

  /// Chi tiết vé theo ID
  Future<BookingModel> getById(String id) async {
    final response = await _dio.get(BookingPaths.byId(id));
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Hủy vé
  Future<void> cancelBooking(String id) async {
    await _dio.put(BookingPaths.cancel(id));
  }
}
