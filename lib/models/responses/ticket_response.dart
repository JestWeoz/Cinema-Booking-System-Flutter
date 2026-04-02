// Ticket Response — khớp với backend DTO/Response/Ticket/TicketResponse.java
import '../enums.dart';

class TicketSeatInfo {
  final String seatRow;
  final int seatNumber;
  final SeatTypeEnum? seatType;

  const TicketSeatInfo({
    required this.seatRow,
    required this.seatNumber,
    this.seatType,
  });

  factory TicketSeatInfo.fromJson(Map<String, dynamic> json) => TicketSeatInfo(
        seatRow: json['seatRow'] ?? '',
        seatNumber: json['seatNumber'] ?? 0,
        seatType: json['seatType'] != null
            ? SeatTypeEnum.values.byName(json['seatType'])
            : null,
      );
}

class TicketShowtimeInfo {
  final String movieTitle;
  final String cinemaName;
  final String roomName;
  final String startTime;

  const TicketShowtimeInfo({
    required this.movieTitle,
    required this.cinemaName,
    required this.roomName,
    required this.startTime,
  });

  factory TicketShowtimeInfo.fromJson(Map<String, dynamic> json) =>
      TicketShowtimeInfo(
        movieTitle: json['movieTitle'] ?? '',
        cinemaName: json['cinemaName'] ?? '',
        roomName: json['roomName'] ?? '',
        startTime: json['startTime'] ?? '',
      );
}

class TicketResponse {
  final String ticketId;
  final String ticketCode;
  final TicketStatus? status;
  final double price;
  final TicketSeatInfo? seat;
  final TicketShowtimeInfo? showtime;
  final String? checkedInAt;

  const TicketResponse({
    required this.ticketId,
    required this.ticketCode,
    this.status,
    required this.price,
    this.seat,
    this.showtime,
    this.checkedInAt,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) => TicketResponse(
        ticketId: json['ticketId'] ?? '',
        ticketCode: json['ticketCode'] ?? '',
        status: json['status'] != null
            ? TicketStatus.values.byName(json['status'])
            : null,
        price: (json['price'] ?? 0).toDouble(),
        seat: json['seat'] != null
            ? TicketSeatInfo.fromJson(json['seat'])
            : null,
        showtime: json['showtime'] != null
            ? TicketShowtimeInfo.fromJson(json['showtime'])
            : null,
        checkedInAt: json['checkedInAt'],
      );
}
