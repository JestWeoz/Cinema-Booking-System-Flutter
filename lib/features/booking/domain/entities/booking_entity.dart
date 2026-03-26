import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String movieId;
  final String movieTitle;
  final String cinemaName;
  final DateTime showtime;
  final List<String> seats;
  final double totalAmount;
  final String status; // 'pending' | 'confirmed' | 'cancelled'
  final DateTime bookedAt;

  const BookingEntity({
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

  @override
  List<Object?> get props => [id];
}
