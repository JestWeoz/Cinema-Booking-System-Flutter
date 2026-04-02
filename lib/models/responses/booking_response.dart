// Booking Responses — khớp với backend DTO/Response/Booking/
import '../enums.dart';

// ─── Booking Detail Response ─────────────────────────────────────────────

class BookingShowtimeInfo {
  final String showtimeId;
  final String movieTitle;
  final String roomName;
  final String cinemaName;
  final String startTime;

  const BookingShowtimeInfo({
    required this.showtimeId,
    required this.movieTitle,
    required this.roomName,
    required this.cinemaName,
    required this.startTime,
  });

  factory BookingShowtimeInfo.fromJson(Map<String, dynamic> json) =>
      BookingShowtimeInfo(
        showtimeId: json['showtimeId'] ?? '',
        movieTitle: json['movieTitle'] ?? '',
        roomName: json['roomName'] ?? '',
        cinemaName: json['cinemaName'] ?? '',
        startTime: json['startTime'] ?? '',
      );
}

class BookingTicketInfo {
  final String ticketCode;
  final String seatRow;
  final int seatNumber;
  final SeatTypeEnum? seatType;
  final double price;
  final TicketStatus? status;

  const BookingTicketInfo({
    required this.ticketCode,
    required this.seatRow,
    required this.seatNumber,
    this.seatType,
    required this.price,
    this.status,
  });

  factory BookingTicketInfo.fromJson(Map<String, dynamic> json) =>
      BookingTicketInfo(
        ticketCode: json['ticketCode'] ?? '',
        seatRow: json['seatRow'] ?? '',
        seatNumber: json['seatNumber'] ?? 0,
        seatType: json['seatType'] != null
            ? SeatTypeEnum.values.byName(json['seatType'])
            : null,
        price: (json['price'] ?? 0).toDouble(),
        status: json['status'] != null
            ? TicketStatus.values.byName(json['status'])
            : null,
      );
}

class BookingProductInfo {
  final String itemId;
  final String itemName;
  final ItemType? itemType;
  final double itemPrice;
  final int quantity;
  final double subtotal;

  const BookingProductInfo({
    required this.itemId,
    required this.itemName,
    this.itemType,
    required this.itemPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory BookingProductInfo.fromJson(Map<String, dynamic> json) =>
      BookingProductInfo(
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
        itemType: json['itemType'] != null
            ? ItemType.values.byName(json['itemType'])
            : null,
        itemPrice: (json['itemPrice'] ?? 0).toDouble(),
        quantity: json['quantity'] ?? 0,
        subtotal: (json['subtotal'] ?? 0).toDouble(),
      );
}

class BookingResponse {
  final String bookingId;
  final String bookingCode;
  final BookingStatus? status;
  final BookingShowtimeInfo? showtime;
  final List<BookingTicketInfo> tickets;
  final List<BookingProductInfo> products;
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final String? expiredAt;
  final String? paymentUrl;

  const BookingResponse({
    required this.bookingId,
    required this.bookingCode,
    this.status,
    this.showtime,
    required this.tickets,
    required this.products,
    required this.totalPrice,
    required this.discountAmount,
    required this.finalPrice,
    this.expiredAt,
    this.paymentUrl,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) =>
      BookingResponse(
        bookingId: json['bookingId'] ?? '',
        bookingCode: json['bookingCode'] ?? '',
        status: json['status'] != null
            ? BookingStatus.values.byName(json['status'])
            : null,
        showtime: json['showtime'] != null
            ? BookingShowtimeInfo.fromJson(json['showtime'])
            : null,
        tickets: (json['tickets'] as List<dynamic>?)
                ?.map((e) => BookingTicketInfo.fromJson(e))
                .toList() ??
            [],
        products: (json['products'] as List<dynamic>?)
                ?.map((e) => BookingProductInfo.fromJson(e))
                .toList() ??
            [],
        totalPrice: (json['totalPrice'] ?? 0).toDouble(),
        discountAmount: (json['discountAmount'] ?? 0).toDouble(),
        finalPrice: (json['finalPrice'] ?? 0).toDouble(),
        expiredAt: json['expiredAt'],
        paymentUrl: json['paymentUrl'],
      );
}

// ─── Booking Summary Response ─────────────────────────────────────────────

class BookingSummaryResponse {
  final String bookingId;
  final String bookingCode;
  final String movieTitle;
  final String startTime;
  final int seatCount;
  final double finalPrice;
  final BookingStatus? status;
  final String? createdAt;

  const BookingSummaryResponse({
    required this.bookingId,
    required this.bookingCode,
    required this.movieTitle,
    required this.startTime,
    required this.seatCount,
    required this.finalPrice,
    this.status,
    this.createdAt,
  });

  factory BookingSummaryResponse.fromJson(Map<String, dynamic> json) =>
      BookingSummaryResponse(
        bookingId: json['bookingId'] ?? '',
        bookingCode: json['bookingCode'] ?? '',
        movieTitle: json['movieTitle'] ?? '',
        startTime: json['startTime'] ?? '',
        seatCount: json['seatCount'] ?? 0,
        finalPrice: (json['finalPrice'] ?? 0).toDouble(),
        status: json['status'] != null
            ? BookingStatus.values.byName(json['status'])
            : null,
        createdAt: json['createdAt'],
      );
}
