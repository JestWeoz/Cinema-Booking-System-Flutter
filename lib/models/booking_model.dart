class BookingModel {
  final String id;
  final String movieId;
  final String movieTitle;
  final String cinemaName;
  final DateTime showtime;
  final List<String> seats;
  final double totalAmount;
  final String status; // 'pending' | 'confirmed' | 'cancelled'
  final DateTime bookedAt;

  const BookingModel({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.cinemaName,
    required this.showtime,
    required this.seats,
    required this.totalAmount,
    required this.status,
    required this.bookedAt,
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
