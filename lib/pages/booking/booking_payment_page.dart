import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/requests/payment_requests.dart';
import 'package:cinema_booking_system_app/models/responses/payment_response.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_payment_webview_page.dart';
import 'package:cinema_booking_system_app/services/payment_service.dart';

class BookingPaymentPage extends StatefulWidget {
  final BookingPaymentContext contextData;

  const BookingPaymentPage({
    super.key,
    required this.contextData,
  });

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  final PaymentService _paymentService = PaymentService.instance;
  PaymentResponse? _payment;
  bool _creatingPayment = false;

  Future<void> _openVnpay() async {
    setState(() => _creatingPayment = true);
    try {
      final payment = await _paymentService.createPayment(
        CreatePaymentRequest(
          bookingId: widget.contextData.booking.bookingId,
        ),
      );
      _payment = payment;

      final url = payment.paymentUrl;
      if (url == null || url.isEmpty) {
        throw Exception('Backend chua tra ve paymentUrl');
      }

      if (!mounted) return;
      final paymentResult =
          await Navigator.of(context).push<BookingPaymentWebViewResult>(
        MaterialPageRoute<BookingPaymentWebViewResult>(
          builder: (_) => BookingPaymentWebViewPage(
            paymentUrl: url,
            bookingId: widget.contextData.booking.bookingId,
          ),
        ),
      );

      if (!mounted) return;
      if (paymentResult != null) {
        context.go(paymentResult.toRouteLocation());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong the tao thanh toan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.contextData.draft;
    final booking = widget.contextData.booking;
    final payment = _payment;

    return BookingPageScaffold(
      title: 'Thanh toán',
      bottomNavigationBar: BookingBottomBar(
        label: 'Tổng tiền',
        value: bookingFormatCurrency(booking.finalPrice),
        note: 'Bước cuối cùng để giữ chỗ và xuất vé.',
        buttonText: 'Thanh toán với VNPay',
        onPressed: _openVnpay,
        loading: _creatingPayment,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          BookingMovieStrip(
            title: draft.movie.title,
            posterUrl: draft.movie.posterUrl,
            ageRating: draft.movie.ageRating,
            subtitle:
                '${draft.showtime.cinemaName} - ${bookingFormatDateTime(draft.showtime.startTime)}',
          ),
          const SizedBox(height: 16),
          BookingSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryLine(label: 'Mã booking', value: booking.bookingCode),
                _SummaryLine(label: 'Ghế', value: draft.seatLabel),
                _SummaryLine(
                  label: 'Tiền vé',
                  value: bookingFormatCurrency(booking.totalPrice),
                ),
                _SummaryLine(
                  label: 'Giam gia',
                  value: booking.discountAmount > 0
                      ? '-${bookingFormatCurrency(booking.discountAmount)}'
                      : '0 VND',
                ),
                _SummaryLine(
                  label: 'Phải thanh toán',
                  value: bookingFormatCurrency(booking.finalPrice),
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BookingSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VNPay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mở trực tiếp cổng thanh toán ngay trong app, giống màn embedded web.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
                if (payment != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Trang thai hien tai: ${payment.status?.name ?? 'PENDING'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.secondary : Colors.white,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: highlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
