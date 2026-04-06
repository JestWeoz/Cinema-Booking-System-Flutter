// Showtime Responses — khớp với backend DTO/Response/Showtime/
import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';
import '../enums.dart';

class ShowtimeSummaryResponse {
  final String id;
  final String movieId;
  final String movieTitle;
  final String? posterUrl;
  final int durationMinutes;
  final String roomId;
  final String roomName;
  final String cinemaId;
  final String cinemaName;
  final String startTime; // ISO datetime
  final String endTime;
  final double basePrice;
  final Language? language;
  final ShowTimeStatus? status;
  final int availableSeats;
  final bool bookable;

  const ShowtimeSummaryResponse({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    this.posterUrl,
    required this.durationMinutes,
    required this.roomId,
    required this.roomName,
    required this.cinemaId,
    required this.cinemaName,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    this.language,
    this.status,
    required this.availableSeats,
    required this.bookable,
  });

  factory ShowtimeSummaryResponse.fromJson(Map<String, dynamic> json) =>
      ShowtimeSummaryResponse(
        id: json['id'] ?? '',
        movieId: json['movieId'] ?? '',
        movieTitle: json['movieTitle'] ?? '',
        posterUrl: ImageUrlResolver.pick(json, keys: const ['posterUrl']),
        durationMinutes: json['durationMinutes'] ?? 0,
        roomId: json['roomId'] ?? '',
        roomName: json['roomName'] ?? '',
        cinemaId: json['cinemaId'] ?? '',
        cinemaName: json['cinemaName'] ?? '',
        startTime: json['startTime'] ?? '',
        endTime: json['endTime'] ?? '',
        basePrice: (json['basePrice'] ?? 0).toDouble(),
        language: languageFromJson(json['language']),
        status: showTimeStatusFromJson(json['status']),
        availableSeats: json['availableSeats'] ?? 0,
        bookable: json['bookable'] ?? false,
      );
}

class ShowtimeDetailResponse {
  final String id;
  final String movieId;
  final String movieTitle;
  final String? posterUrl;
  final int durationMinutes;
  final String? category;
  final String? rating;
  final String roomId;
  final String roomName;
  final RoomType? roomType;
  final String cinemaId;
  final String cinemaName;
  final String? cinemaAddress;
  final String startTime;
  final String endTime;
  final double basePrice;
  final Language? language;
  final ShowTimeStatus? status;
  final int availableSeats;
  final bool bookable;
  final bool ongoing;
  final bool finished;

  const ShowtimeDetailResponse({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    this.posterUrl,
    required this.durationMinutes,
    this.category,
    this.rating,
    required this.roomId,
    required this.roomName,
    this.roomType,
    required this.cinemaId,
    required this.cinemaName,
    this.cinemaAddress,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    this.language,
    this.status,
    required this.availableSeats,
    required this.bookable,
    required this.ongoing,
    required this.finished,
  });

  factory ShowtimeDetailResponse.fromJson(Map<String, dynamic> json) =>
      ShowtimeDetailResponse(
        id: json['id'] ?? '',
        movieId: json['movieId'] ?? '',
        movieTitle: json['movieTitle'] ?? '',
        posterUrl: ImageUrlResolver.pick(json, keys: const ['posterUrl']),
        durationMinutes: json['durationMinutes'] ?? 0,
        category: json['category'],
        rating: json['rating'],
        roomId: json['roomId'] ?? '',
        roomName: json['roomName'] ?? '',
        roomType: roomTypeFromJson(json['roomType']),
        cinemaId: json['cinemaId'] ?? '',
        cinemaName: json['cinemaName'] ?? '',
        cinemaAddress: json['cinemaAddress'],
        startTime: json['startTime'] ?? '',
        endTime: json['endTime'] ?? '',
        basePrice: (json['basePrice'] ?? 0).toDouble(),
        language: languageFromJson(json['language']),
        status: showTimeStatusFromJson(json['status']),
        availableSeats: json['availableSeats'] ?? 0,
        bookable: json['bookable'] ?? false,
        ongoing: json['ongoing'] ?? false,
        finished: json['finished'] ?? false,
      );
}

class ShowtimeSeatResponse {
  final String showtimeSeatId;
  final String seatId;
  final String seatRow;
  final int seatNumber;
  final SeatTypeEnum? seatType;
  final double finalPrice;
  final SeatStatus? status;
  final String? lockedUntil;
  final String? lockedByUser;

  const ShowtimeSeatResponse({
    required this.showtimeSeatId,
    required this.seatId,
    required this.seatRow,
    required this.seatNumber,
    this.seatType,
    required this.finalPrice,
    this.status,
    this.lockedUntil,
    this.lockedByUser,
  });

  factory ShowtimeSeatResponse.fromJson(Map<String, dynamic> json) =>
      ShowtimeSeatResponse(
        showtimeSeatId: json['showtimeSeatId'] ?? '',
        seatId: json['seatId'] ?? '',
        seatRow: json['seatRow'] ?? '',
        seatNumber: json['seatNumber'] ?? 0,
        seatType: json['seatType'] != null
            ? SeatTypeEnum.values.byName(json['seatType'])
            : null,
        finalPrice: (json['finalPrice'] ?? 0).toDouble(),
        status: json['status'] != null
            ? SeatStatus.values.byName(json['status'])
            : null,
        lockedUntil: json['lockedUntil'],
        lockedByUser: json['lockedByUser'],
      );
}

class SeatMapResponse {
  final String showtimeId;
  final int totalSeats;
  final int availableSeats;
  final Map<String, List<ShowtimeSeatResponse>> seatMap;

  const SeatMapResponse({
    required this.showtimeId,
    required this.totalSeats,
    required this.availableSeats,
    required this.seatMap,
  });

  factory SeatMapResponse.fromJson(Map<String, dynamic> json) {
    final rawMap = json['seatMap'] as Map<String, dynamic>? ?? {};
    final parsedMap = <String, List<ShowtimeSeatResponse>>{};
    rawMap.forEach((row, seats) {
      parsedMap[row] = (seats as List<dynamic>)
          .map((s) => ShowtimeSeatResponse.fromJson(s))
          .toList();
    });
    return SeatMapResponse(
      showtimeId: json['showtimeId'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      seatMap: parsedMap,
    );
  }
}
