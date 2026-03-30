class CreateBookingRequest {
  final String showtimeId;
  final List<String> seatIds;
  final String paymentMethod;
  final String? promotionCode;

  const CreateBookingRequest({
    required this.showtimeId,
    required this.seatIds,
    required this.paymentMethod,
    this.promotionCode,
  });

  Map<String, dynamic> toJson() => {
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        'paymentMethod': paymentMethod,
        if (promotionCode != null) 'promotionCode': promotionCode,
      };
}
