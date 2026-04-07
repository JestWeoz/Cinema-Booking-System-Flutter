import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/booking_response.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_payment_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/services/booking_service.dart';

class BookingReviewPage extends StatefulWidget {
  final BookingFlowDraft draft;

  const BookingReviewPage({
    super.key,
    required this.draft,
  });

  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage> {
  final BookingService _bookingService = BookingService.instance;
  final TextEditingController _promotionCodeController =
      TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _promotionCodeController.text = widget.draft.promotionCode ?? '';
  }

  @override
  void dispose() {
    _promotionCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    setState(() => _submitting = true);
    try {
      final draft = widget.draft.copyWith(
        promotionCode: _promotionCodeController.text.trim(),
        clearPromotionCode: _promotionCodeController.text.trim().isEmpty,
      );
      final BookingResponse booking = await _bookingService.createBookingFull(
        draft.toCreateBookingRequest(),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingPaymentPage(
            contextData: BookingPaymentContext(
              draft: draft,
              booking: booking,
            ),
          ),
        ),
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              e.message)
          : e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tạo được booking: ${message ?? e}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tạo được booking: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final seatTotal = draft.seatSubtotal;
    final concessionTotal = draft.concessionsSubtotal;
    final total = draft.estimatedTotal;

    return BookingPageScaffold(
      title: 'Thông tin đặt vé',
      bottomNavigationBar: BookingBottomBar(
        label: 'Tổng tạm tính',
        value: bookingFormatCurrency(total),
        note: 'Kiểm tra kỹ thông tin trước khi sang bước thanh toán.',
        buttonText: 'Đến thanh toán',
        onPressed: _submitBooking,
        loading: _submitting,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          BookingMovieStrip(
            title: draft.movie.title,
            posterUrl: draft.movie.posterUrl,
            ageRating: draft.movie.ageRating,
            subtitle:
                '${draft.showtime.cinemaName} • ${bookingFormatDateTime(draft.showtime.startTime)}',
          ),
          const SizedBox(height: 16),
          BookingSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin vé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Rạp',
                  value: draft.showtime.cinemaName,
                ),
                _InfoRow(
                  label: 'Phòng chiếu',
                  value: draft.showtime.roomName,
                ),
                _InfoRow(
                  label: 'Suất chiếu',
                  value: bookingFormatTimeRange(
                    draft.showtime.startTime,
                    draft.showtime.endTime,
                  ),
                ),
                _InfoRow(
                  label: 'Ngày xem',
                  value: bookingFormatDateLong(
                    DateTime.parse(draft.showtime.startTime).toLocal(),
                  ),
                ),
                _InfoRow(
                  label: 'Ghế đã chọn',
                  value: draft.seatLabel,
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
                  'Ưu đãi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promotionCodeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã khuyến mãi nếu có',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mã sẽ được áp dụng khi tạo booking ở bước tiếp theo.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
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
                  'Combo & đồ ăn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (draft.concessions.isEmpty)
                  const Text(
                    'Bạn chưa chọn thêm combo hoặc đồ ăn.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  ...draft.concessions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} x${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            bookingFormatCurrency(item.subtotal),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
                  'Tổng kết đơn hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Tiền ghế',
                  value: bookingFormatCurrency(seatTotal),
                ),
                _InfoRow(
                  label: 'Combo & đồ ăn',
                  value: bookingFormatCurrency(concessionTotal),
                ),
                const Divider(color: Colors.white12, height: 24),
                _InfoRow(
                  label: 'Tổng tạm tính',
                  value: bookingFormatCurrency(total),
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = highlight ? AppColors.secondary : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
