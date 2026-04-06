import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/payment_response.dart';
import 'package:cinema_booking_system_app/models/requests/payment_requests.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final Dio _dio = DioClient.instance;

  PaymentResponse _parse(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] != null) {
      return PaymentResponse.fromJson(data['data'] as Map<String, dynamic>);
    }
    return PaymentResponse.fromJson(data as Map<String, dynamic>);
  }

  /// POST /payments — Tạo thanh toán mới
  Future<PaymentResponse> createPayment(CreatePaymentRequest request) async {
    final response = await _dio.post(PaymentPaths.base, data: request.toJson());
    return _parse(response.data);
  }

  /// GET /payments/booking/{bookingId} — Lấy thông tin thanh toán theo booking
  Future<PaymentResponse> getByBooking(String bookingId) async {
    final response = await _dio.get(PaymentPaths.byBooking(bookingId));
    return _parse(response.data);
  }

  /// POST /payments/booking/{bookingId}/refund — Hoàn tiền cho booking
  Future<PaymentResponse> refund(String bookingId) async {
    final response = await _dio.post(PaymentPaths.refund(bookingId));
    return _parse(response.data);
  }
}
