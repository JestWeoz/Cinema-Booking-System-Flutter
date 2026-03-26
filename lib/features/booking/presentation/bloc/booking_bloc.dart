import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinema_booking_system_app/features/booking/domain/repositories/booking_repository.dart';
import 'booking_event_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  BookingBloc({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository,
        super(const BookingInitial()) {
    on<LoadMyBookings>(_onLoadMyBookings);
    on<CreateBooking>(_onCreateBooking);
    on<CancelBooking>(_onCancelBooking);
    on<LoadBookingById>(_onLoadBookingById);
  }

  Future<void> _onLoadMyBookings(
    LoadMyBookings event, Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final result = await _bookingRepository.getMyBookings();
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (bookings) => emit(MyBookingsLoaded(bookings)),
    );
  }

  Future<void> _onCreateBooking(
    CreateBooking event, Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final result = await _bookingRepository.createBooking(
      movieId: event.movieId,
      showtimeId: event.showtimeId,
      seatIds: event.seatIds,
      paymentMethod: event.paymentMethod,
    );
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  Future<void> _onCancelBooking(
    CancelBooking event, Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final result = await _bookingRepository.cancelBooking(event.bookingId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) => emit(const BookingCancelled()),
    );
  }

  Future<void> _onLoadBookingById(
    LoadBookingById event, Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final result = await _bookingRepository.getBookingById(event.bookingId);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (booking) => emit(BookingDetailLoaded(booking)),
    );
  }
}
