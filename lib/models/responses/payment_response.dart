// Payment Response — khớp với backend DTO/Response/Payment/PaymentResponse.java
import '../enums.dart';

class PaymentResponse {
  final String paymentId;
  final String bookingId;
  final String bookingCode;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? status;
  final double amount;
  final String? transactionId;
  final String? paymentUrl;
  final String? createdAt;

  const PaymentResponse({
    required this.paymentId,
    required this.bookingId,
    required this.bookingCode,
    this.paymentMethod,
    this.status,
    required this.amount,
    this.transactionId,
    this.paymentUrl,
    this.createdAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      PaymentResponse(
        paymentId: json['paymentId'] ?? '',
        bookingId: json['bookingId'] ?? '',
        bookingCode: json['bookingCode'] ?? '',
        paymentMethod: json['paymentMethod'] != null
            ? PaymentMethod.values.byName(json['paymentMethod'])
            : null,
        status: json['status'] != null
            ? PaymentStatus.values.byName(json['status'])
            : null,
        amount: (json['amount'] ?? 0).toDouble(),
        transactionId: json['transactionId'],
        paymentUrl: json['paymentUrl'],
        createdAt: json['createdAt'],
      );
}
