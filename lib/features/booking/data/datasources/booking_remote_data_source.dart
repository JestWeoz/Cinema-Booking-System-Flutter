import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/features/booking/data/models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> createBooking({
    required String showtimeId,
    required List<String> seatIds,
    required String paymentMethod,
    String? promotionCode,
  });
  Future<List<BookingModel>> getMyBookings();
  Future<BookingModel> getBookingById(String id);
  Future<void> cancelBooking(String id);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final Dio _dio;
  BookingRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
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

  @override
  Future<List<BookingModel>> getMyBookings() async {
    final response = await _dio.get(BookingPaths.my);
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<BookingModel> getBookingById(String id) async {
    final response = await _dio.get(BookingPaths.byId(id));
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> cancelBooking(String id) async {
    await _dio.put(BookingPaths.cancel(id));
  }
}
