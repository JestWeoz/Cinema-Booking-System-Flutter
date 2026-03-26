import 'package:cinema_booking_system_app/features/booking/domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.movieId,
    required super.movieTitle,
    required super.cinemaName,
    required super.showtime,
    required super.seats,
    required super.totalAmount,
    required super.status,
    required super.bookedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    List<String> parseSeats(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      movieId: json['movieId']?.toString() ?? json['movie_id']?.toString() ?? '',
      movieTitle: json['movieTitle'] as String? ?? json['movie_title'] as String? ?? '',
      cinemaName: json['cinemaName'] as String? ?? json['cinema_name'] as String? ?? '',
      showtime: json['showtime'] != null
          ? DateTime.parse(json['showtime'] as String)
          : json['showtimeStart'] != null
              ? DateTime.parse(json['showtimeStart'] as String)
              : DateTime.now(),
      seats: parseSeats(json['seats']),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      bookedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['booked_at'] != null
              ? DateTime.parse(json['booked_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'movieTitle': movieTitle,
      'cinemaName': cinemaName,
      'showtime': showtime.toIso8601String(),
      'seats': seats,
      'totalAmount': totalAmount,
      'status': status,
      'bookedAt': bookedAt.toIso8601String(),
    };
  }
}
