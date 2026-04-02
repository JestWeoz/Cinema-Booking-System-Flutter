// Booking Request — khớp với backend DTO/Request/Booking/CreateBookingRequest.java
import '../enums.dart';

class BookingProductItem {
  final String itemId;
  final ItemType itemType; // PRODUCT | COMBO
  final int quantity;

  const BookingProductItem({
    required this.itemId,
    required this.itemType,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemType': itemType.name,
        'quantity': quantity,
      };
}

class CreateBookingRequest {
  final List<String> seatIds;
  final String showtimeId;
  final String? promotionCode;
  final List<BookingProductItem>? products;

  const CreateBookingRequest({
    required this.seatIds,
    required this.showtimeId,
    this.promotionCode,
    this.products,
  });

  Map<String, dynamic> toJson() => {
        'seatIds': seatIds,
        'showtimeId': showtimeId,
        if (promotionCode != null) 'promotionCode': promotionCode,
        if (products != null)
          'products': products!.map((p) => p.toJson()).toList(),
      };
}
