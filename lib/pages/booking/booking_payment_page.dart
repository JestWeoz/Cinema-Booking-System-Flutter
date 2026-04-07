import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
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
  bool _checkingPayment = false;

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
      final paymentResult = await Navigator.of(context).push<
          BookingPaymentWebViewResult>(
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

  Future<void> _checkPaymentStatus() async {
    setState(() => _checkingPayment = true);
    try {
      final payment = await _paymentService.getByBooking(
        widget.contextData.booking.bookingId,
      );
      if (!mounted) return;
      setState(() => _payment = payment);
      if (payment.status == PaymentStatus.SUCCESS) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Text(
              'Thanh toan thanh cong',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Dat ve cua ban da duoc thanh toan thanh cong. Ve se xuat hien trong muc ve cua toi.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dong'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        context.go(AppRoutes.tickets);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              payment.status == PaymentStatus.PENDING
                  ? 'Thanh toan van dang cho xu ly.'
                  : 'Trang thai hien tai: ${payment.status?.name ?? 'UNKNOWN'}',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong kiem tra duoc thanh toan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.contextData.draft;
    final booking = widget.contextData.booking;
    final payment = _payment;

    return BookingPageScaffold(
      title: 'Thanh toan an toan',
      bottomNavigationBar: BookingBottomBar(
        label: 'Tong tien',
        value: bookingFormatCurrency(booking.finalPrice),
        note: 'Buoc cuoi cung de giu cho va xuat ve.',
        buttonText: 'Thanh toan voi VNPay',
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
                  'Tom tat thanh toan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryLine(label: 'Ma booking', value: booking.bookingCode),
                _SummaryLine(label: 'Ghe', value: draft.seatLabel),
                _SummaryLine(
                  label: 'Tien ve',
                  value: bookingFormatCurrency(booking.totalPrice),
                ),
                _SummaryLine(
                  label: 'Giam gia',
                  value: booking.discountAmount > 0
                      ? '-${bookingFormatCurrency(booking.discountAmount)}'
                      : '0 VND',
                ),
                _SummaryLine(
                  label: 'Phai thanh toan',
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
                  'Phuong thuc thanh toan',
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
                              'Mo truc tiep cong thanh toan ngay trong app, giong man embedded web.',
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
          const SizedBox(height: 16),
          BookingSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sau khi thanh toan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Nhan nut thanh toan de mo man hinh VNPay nhung ngay trong app.\n2. Hoan tat giao dich ngay trong WebView hoac sang app ngan hang neu VNPay yeu cau.\n3. Khi giao dich tra ket qua, app se tu ve man hinh ket qua thanh toan.',
                  style: TextStyle(color: Colors.white70, height: 1.6),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkingPayment ? null : _checkPaymentStatus,
                    icon: _checkingPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Kiem tra trang thai thanh toan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
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
