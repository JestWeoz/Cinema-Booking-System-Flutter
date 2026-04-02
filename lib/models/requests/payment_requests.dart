// Payment Request — khớp với backend DTO/Request/Payment/CreatePaymentRequest.java

class CreatePaymentRequest {
  final String bookingId;
  final String? clientIp;

  const CreatePaymentRequest({required this.bookingId, this.clientIp});

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        if (clientIp != null) 'clientIp': clientIp,
      };
}
