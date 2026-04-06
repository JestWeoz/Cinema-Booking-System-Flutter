import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/responses/ticket_response.dart';

class TicketService {
  TicketService._();
  static final TicketService instance = TicketService._();

  final Dio _dio = DioClient.instance;

  List<TicketResponse> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => TicketResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => TicketResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => TicketResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /tickets/my — Lấy danh sách vé của tôi
  Future<List<TicketResponse>> getMyTickets() async {
    final response = await _dio.get(TicketPaths.my);
    return _parseList(response.data);
  }

  /// GET /tickets/booking/{bookingId} — Lấy vé theo booking
  Future<List<TicketResponse>> getByBooking(String bookingId) async {
    final response = await _dio.get(TicketPaths.byBooking(bookingId));
    return _parseList(response.data);
  }

  /// GET /tickets/{bookingCode}/qr — Lấy QR code (base64)
  Future<String> getQrCode(String bookingCode) async {
    final response = await _dio.get(TicketPaths.qr(bookingCode));
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data'] ?? data['qr'] ?? '').toString();
    }
    return data?.toString() ?? '';
  }

  /// POST /tickets/check-in — Check-in nhiều vé
  Future<void> checkIn(List<String> ticketCodes) async {
    await _dio.post(
      TicketPaths.checkIn,
      data: {'ticketCodes': ticketCodes},
    );
  }
}
