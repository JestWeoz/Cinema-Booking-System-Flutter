import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/errors/failures.dart';
import 'package:cinema_booking_system_app/core/network/api_interceptor.dart';
import 'package:cinema_booking_system_app/features/booking/domain/entities/booking_entity.dart';
import 'package:cinema_booking_system_app/features/booking/domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepositoryImpl({required BookingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String movieId,
    required String showtimeId,
    required List<String> seatIds,
    required String paymentMethod,
  }) async {
    try {
      final booking = await _remoteDataSource.createBooking(
        showtimeId: showtimeId,
        seatIds: seatIds,
        paymentMethod: paymentMethod,
      );
      return Right(booking);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getMyBookings() async {
    try {
      final bookings = await _remoteDataSource.getMyBookings();
      return Right(bookings);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async {
    try {
      final booking = await _remoteDataSource.getBookingById(id);
      return Right(booking);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(String id) async {
    try {
      await _remoteDataSource.cancelBooking(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
