import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/payment_requests.dart';
import 'package:cinema_booking_system_app/models/responses/payment_response.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_payment_webview_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/services/payment_service.dart';

class BookingPaymentResultPage extends StatefulWidget {
  final String bookingId;
  final String? bookingCode;
  final String? rawStatus;
  final String? responseCode;
  final String? transactionId;

  const BookingPaymentResultPage({
    super.key,
    required this.bookingId,
    this.bookingCode,
    this.rawStatus,
    this.responseCode,
    this.transactionId,
  });

  @override
  State<BookingPaymentResultPage> createState() =>
      _BookingPaymentResultPageState();
}

class _BookingPaymentResultPageState extends State<BookingPaymentResultPage> {
  final PaymentService _paymentService = PaymentService.instance;
  PaymentResponse? _payment;
  String? _error;
  bool _loading = true;
  bool _reopeningPayment = false;

  @override
  void initState() {
    super.initState();
    _refreshPayment();
  }

  PaymentStatus? get _fallbackStatus {
    final raw = widget.rawStatus?.trim().toUpperCase();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return PaymentStatus.values.byName(raw);
    } catch (_) {
      return null;
    }
  }

  PaymentStatus get _effectiveStatus =>
      _payment?.status ?? _fallbackStatus ?? PaymentStatus.PENDING;

  Future<void> _refreshPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payment = await _paymentService.getByBooking(widget.bookingId);
      if (!mounted) return;
      setState(() => _payment = payment);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _retryPayment() async {
    setState(() => _reopeningPayment = true);
    try {
      final payment = await _paymentService.createPayment(
        CreatePaymentRequest(bookingId: widget.bookingId),
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
            bookingId: widget.bookingId,
          ),
        ),
      );

      if (!mounted || paymentResult == null) return;
      context.go(paymentResult.toRouteLocation());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong the mo lai VNPay: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reopeningPayment = false);
      }
    }
  }

  IconData get _statusIcon {
    switch (_effectiveStatus) {
      case PaymentStatus.SUCCESS:
        return Icons.verified_rounded;
      case PaymentStatus.FAILED:
      case PaymentStatus.REFUNDED:
        return Icons.error_outline_rounded;
      case PaymentStatus.PENDING:
        return Icons.hourglass_top_rounded;
    }
  }

  Color get _statusColor {
    switch (_effectiveStatus) {
      case PaymentStatus.SUCCESS:
        return AppColors.success;
      case PaymentStatus.FAILED:
      case PaymentStatus.REFUNDED:
        return AppColors.error;
      case PaymentStatus.PENDING:
        return AppColors.secondary;
    }
  }

  String get _statusTitle {
    switch (_effectiveStatus) {
      case PaymentStatus.SUCCESS:
        return 'Thanh toán thành công';
      case PaymentStatus.FAILED:
        return 'Thanh toán thất bại';
      case PaymentStatus.REFUNDED:
        return 'Thanh toán đã hoàn tiền';
      case PaymentStatus.PENDING:
        return 'Đang chờ xác nhận thanh toán';
    }
  }

  String get _statusDescription {
    switch (_effectiveStatus) {
      case PaymentStatus.SUCCESS:
        return 'Giao dịch đã quay về app và booking của bạn đã được xác nhận.';
      case PaymentStatus.FAILED:
        return 'VNPay đã trả về kết quả chưa thành công. Bạn có thể thử lại ngay trong app.';
      case PaymentStatus.REFUNDED:
        return 'Khoản thanh toán này đã được hoàn lại.';
      case PaymentStatus.PENDING:
        return 'Giao dịch đã quay về app, nhưng backend có thể vẫn đang đợi IPN đồng bộ. Bạn có thể kiểm tra lại sau ít giây.';
    }
  }

  String get _primaryButtonText {
    switch (_effectiveStatus) {
      case PaymentStatus.SUCCESS:
        return 'Về trang chủ';
      case PaymentStatus.FAILED:
        return 'Thanh toán lại';
      case PaymentStatus.REFUNDED:
        return 'Về trang chủ';
      case PaymentStatus.PENDING:
        return 'Kiểm tra lại';
    }
  }

  Future<void> _onPrimaryPressed() async {
    switch (_effectiveStatus) {
      case PaymentStatus.SUCCESS:
        if (!mounted) return;
        context.go(AppRoutes.home);
        break;
      case PaymentStatus.FAILED:
        await _retryPayment();
        break;
      case PaymentStatus.REFUNDED:
        if (!mounted) return;
        context.go(AppRoutes.home);
        break;
      case PaymentStatus.PENDING:
        await _refreshPayment();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BookingPageScaffold(
      title: 'Kết quả thanh toán',
      bottomNavigationBar: BookingBottomBar(
        label: 'Trạng thái',
        value: _effectiveStatus.name,
        note:
            'App đã nhận callback từ VNPay và đang đồng bộ trạng thái mới nhất.',
        buttonText: _primaryButtonText,
        onPressed: (_loading || _reopeningPayment) ? null : _onPrimaryPressed,
        loading: _reopeningPayment,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          BookingSectionCard(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon, color: _statusColor, size: 38),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.6,
                  ),
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
                  'Chi tiết giao dịch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryLine(label: 'Booking ID', value: widget.bookingId),
                if ((widget.bookingCode ?? '').isNotEmpty)
                  _SummaryLine(
                    label: 'Mã booking',
                    value: widget.bookingCode!,
                  ),
                if ((_payment?.amount ?? 0) > 0)
                  _SummaryLine(
                    label: 'Số tiền',
                    value: bookingFormatCurrency(_payment!.amount),
                  ),
                if ((widget.transactionId ?? _payment?.transactionId ?? '')
                    .isNotEmpty)
                  _SummaryLine(
                    label: 'Mã giao dịch',
                    value: widget.transactionId ?? _payment!.transactionId!,
                  ),
                if ((widget.responseCode ?? '').isNotEmpty)
                  _SummaryLine(
                    label: 'VNPay code',
                    value: widget.responseCode!,
                  ),
                _SummaryLine(
                  label: 'Trạng thái backend',
                  value: _effectiveStatus.name,
                  highlight: true,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            BookingSectionCard(
              child: Text(
                'Không tải được thông tin thanh toán mới nhất: $_error',
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          BookingSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tùy chọn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _refreshPayment,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('Cập nhật trạng thái'),
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Về trang chủ'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight ? AppColors.secondary : Colors.white,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                fontSize: highlight ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
