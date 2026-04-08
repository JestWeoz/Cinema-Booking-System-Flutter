import '../enums.dart';

SeatTypeEnum? _parseSeatType(String raw) {
  for (final value in SeatTypeEnum.values) {
    if (value.name == raw) return value;
  }
  return null;
}

TicketStatus? _parseTicketStatus(String raw) {
  for (final value in TicketStatus.values) {
    if (value.name == raw) return value;
  }
  return null;
}

class CheckInTicketInfo {
  final String ticketCode;
  final String seatRow;
  final int seatNumber;
  final SeatTypeEnum? seatType;
  final TicketStatus? status;
  final String? checkedInAt;

  const CheckInTicketInfo({
    required this.ticketCode,
    required this.seatRow,
    required this.seatNumber,
    this.seatType,
    this.status,
    this.checkedInAt,
  });

  factory CheckInTicketInfo.fromJson(Map<String, dynamic> json) {
    final seatTypeRaw = (json['seatType'] ?? '').toString();
    final statusRaw = (json['status'] ?? '').toString();
    return CheckInTicketInfo(
      ticketCode: (json['ticketCode'] ?? '').toString(),
      seatRow: (json['seatRow'] ?? '').toString(),
      seatNumber: (json['seatNumber'] ?? 0) is num
          ? (json['seatNumber'] as num).toInt()
          : int.tryParse((json['seatNumber'] ?? '0').toString()) ?? 0,
      seatType: seatTypeRaw.isNotEmpty ? _parseSeatType(seatTypeRaw) : null,
      status: statusRaw.isNotEmpty ? _parseTicketStatus(statusRaw) : null,
      checkedInAt: json['checkedInAt']?.toString(),
    );
  }
}

class CheckInProductInfo {
  final String itemName;
  final String itemType;
  final int quantity;

  const CheckInProductInfo({
    required this.itemName,
    required this.itemType,
    required this.quantity,
  });

  factory CheckInProductInfo.fromJson(Map<String, dynamic> json) {
    return CheckInProductInfo(
      itemName: (json['itemName'] ?? '').toString(),
      itemType: (json['itemType'] ?? '').toString(),
      quantity: (json['quantity'] ?? 0) is num
          ? (json['quantity'] as num).toInt()
          : int.tryParse((json['quantity'] ?? '0').toString()) ?? 0,
    );
  }
}

class CheckInResponse {
  final String bookingCode;
  final String movieTitle;
  final String roomName;
  final String? showtimeAt;
  final List<CheckInTicketInfo> tickets;
  final List<CheckInProductInfo> products;

  const CheckInResponse({
    required this.bookingCode,
    required this.movieTitle,
    required this.roomName,
    this.showtimeAt,
    required this.tickets,
    required this.products,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    final rawTickets = json['tickets'];
    final rawProducts = json['products'];
    return CheckInResponse(
      bookingCode: (json['bookingCode'] ?? '').toString(),
      movieTitle: (json['movieTitle'] ?? '').toString(),
      roomName: (json['roomName'] ?? '').toString(),
      showtimeAt: json['showtimeAt']?.toString(),
      tickets: rawTickets is List
          ? rawTickets
              .whereType<Map<String, dynamic>>()
              .map(CheckInTicketInfo.fromJson)
              .toList()
          : const [],
      products: rawProducts is List
          ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(CheckInProductInfo.fromJson)
              .toList()
          : const [],
    );
  }
}
