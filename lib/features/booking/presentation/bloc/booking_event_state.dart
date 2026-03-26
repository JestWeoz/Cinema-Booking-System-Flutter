import 'package:equatable/equatable.dart';
import 'package:cinema_booking_system_app/features/booking/domain/entities/booking_entity.dart';

// ─── Events ────────────────────────────────────────────────────────────────

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyBookings extends BookingEvent {
  const LoadMyBookings();
}

class CreateBooking extends BookingEvent {
  final String movieId;
  final String showtimeId;
  final List<String> seatIds;
  final String paymentMethod;
  final String? promotionCode;

  const CreateBooking({
    required this.movieId,
    required this.showtimeId,
    required this.seatIds,
    required this.paymentMethod,
    this.promotionCode,
  });

  @override
  List<Object?> get props => [movieId, showtimeId, seatIds, paymentMethod];
}

class CancelBooking extends BookingEvent {
  final String bookingId;
  const CancelBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class LoadBookingById extends BookingEvent {
  final String bookingId;
  const LoadBookingById(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

// ─── States ────────────────────────────────────────────────────────────────

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class MyBookingsLoaded extends BookingState {
  final List<BookingEntity> bookings;
  const MyBookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingDetailLoaded extends BookingState {
  final BookingEntity booking;
  const BookingDetailLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingCreated extends BookingState {
  final BookingEntity booking;
  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingCancelled extends BookingState {
  const BookingCancelled();
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
