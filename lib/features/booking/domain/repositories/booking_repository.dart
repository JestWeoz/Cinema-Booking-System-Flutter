import 'package:dartz/dartz.dart';
import 'package:cinema_booking_system_app/core/errors/failures.dart';
import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<Either<Failure, BookingEntity>> createBooking({
    required String movieId,
    required String showtimeId,
    required List<String> seatIds,
    required String paymentMethod,
  });

  Future<Either<Failure, List<BookingEntity>>> getMyBookings();
  Future<Either<Failure, BookingEntity>> getBookingById(String id);
  Future<Either<Failure, void>> cancelBooking(String id);
}
