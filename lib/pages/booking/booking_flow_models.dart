import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/create_booking_request.dart';
import 'package:cinema_booking_system_app/models/responses/booking_response.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';

class BookingMovieSnapshot {
  final String movieId;
  final String title;
  final String? posterUrl;
  final AgeRating? ageRating;
  final int durationMinutes;

  const BookingMovieSnapshot({
    required this.movieId,
    required this.title,
    this.posterUrl,
    this.ageRating,
    this.durationMinutes = 0,
  });
}

class BookingItemSelection {
  final String itemId;
  final String name;
  final ItemType itemType;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final List<BookingProductItem> requestItems;

  const BookingItemSelection({
    required this.itemId,
    required this.name,
    required this.itemType,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    required this.requestItems,
  });

  double get subtotal => unitPrice * quantity;

  BookingItemSelection copyWith({
    String? itemId,
    String? name,
    ItemType? itemType,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
  }) {
    return BookingItemSelection(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      requestItems: requestItems,
    );
  }

  List<BookingProductItem> toRequestItems() {
    return requestItems
        .map(
          (item) => BookingProductItem(
            itemId: item.itemId,
            itemType: item.itemType,
            quantity: item.quantity * quantity,
          ),
        )
        .toList();
  }
}

class BookingFlowDraft {
  final BookingMovieSnapshot movie;
  final ShowtimeSummaryResponse showtime;
  final List<ShowtimeSeatResponse> seats;
  final List<BookingItemSelection> concessions;
  final String? promotionCode;

  const BookingFlowDraft({
    required this.movie,
    required this.showtime,
    this.seats = const [],
    this.concessions = const [],
    this.promotionCode,
  });

  double get seatSubtotal =>
      seats.fold(0, (sum, seat) => sum + seat.finalPrice);

  double get concessionsSubtotal =>
      concessions.fold(0, (sum, item) => sum + item.subtotal);

  double get estimatedTotal => seatSubtotal + concessionsSubtotal;

  List<String> get seatIds => seats.map((seat) => seat.seatId).toList();

  List<BookingProductItem> get bookingProducts {
    final merged = <String, BookingProductItem>{};
    for (final selection in concessions) {
      for (final item in selection.toRequestItems()) {
        final key = '${item.itemType.name}_${item.itemId}';
        final current = merged[key];
        merged[key] = BookingProductItem(
          itemId: item.itemId,
          itemType: item.itemType,
          quantity: (current?.quantity ?? 0) + item.quantity,
        );
      }
    }
    return merged.values.toList();
  }

  String get seatLabel {
    final labels = seats
        .map((seat) => '${seat.seatRow}${seat.seatNumber}')
        .toList()
      ..sort();
    return labels.join(', ');
  }

  CreateBookingRequest toCreateBookingRequest() {
    return CreateBookingRequest(
      seatIds: seatIds,
      showtimeId: showtime.id,
      promotionCode:
          promotionCode?.trim().isEmpty ?? true ? null : promotionCode!.trim(),
      products: bookingProducts.isEmpty ? null : bookingProducts,
    );
  }

  BookingFlowDraft copyWith({
    BookingMovieSnapshot? movie,
    ShowtimeSummaryResponse? showtime,
    List<ShowtimeSeatResponse>? seats,
    List<BookingItemSelection>? concessions,
    String? promotionCode,
    bool clearPromotionCode = false,
  }) {
    return BookingFlowDraft(
      movie: movie ?? this.movie,
      showtime: showtime ?? this.showtime,
      seats: seats ?? this.seats,
      concessions: concessions ?? this.concessions,
      promotionCode:
          clearPromotionCode ? null : (promotionCode ?? this.promotionCode),
    );
  }
}

class BookingPaymentContext {
  final BookingFlowDraft draft;
  final BookingResponse booking;

  const BookingPaymentContext({
    required this.draft,
    required this.booking,
  });
}
