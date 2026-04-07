import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/models/responses/booking_response.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_payment_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/booking_service.dart';
import 'package:cinema_booking_system_app/services/promotion_service.dart';

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
  final PromotionService _promotionService = PromotionService.instance;
  final AuthService _authService = AuthService.instance;
  final TextEditingController _promotionCodeController =
      TextEditingController();

  bool _submitting = false;
  bool _loadingPromotions = true;
  bool _applyingPromotion = false;
  String? _promotionLoadError;
  String? _promotionApplyError;
  String? _currentUserId;
  List<PromotionResponse> _promotions = const [];
  PromotionResponse? _selectedPromotion;
  _PromotionPreview? _promotionPreview;

  @override
  void initState() {
    super.initState();
    _promotionCodeController.text = widget.draft.promotionCode ?? '';
    _promotionCodeController.addListener(_handlePromotionCodeChanged);
    _loadPromotions();
  }

  @override
  void dispose() {
    _promotionCodeController.removeListener(_handlePromotionCodeChanged);
    _promotionCodeController.dispose();
    super.dispose();
  }

  void _handlePromotionCodeChanged() {
    if (!mounted) return;
    final currentCode = _promotionCodeController.text.trim().toUpperCase();
    final appliedCode = _promotionPreview?.promotionCode.toUpperCase() ?? '';
    if (_promotionPreview != null && currentCode != appliedCode) {
      setState(() {
        _promotionPreview = null;
        _selectedPromotion = null;
        _promotionApplyError = null;
      });
      return;
    }
    setState(() {});
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _loadingPromotions = true;
      _promotionLoadError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _promotionService.getActive(),
        _authService.getCurrentUserResponse(),
      ]);
      if (!mounted) return;

      final promotions = results[0] as List<PromotionResponse>;
      final user = results[1] as UserResponse?;
      setState(() {
        _promotions = promotions;
        _currentUserId = user?.id;
        _loadingPromotions = false;
      });

      final initialCode = _promotionCodeController.text.trim();
      if (initialCode.isNotEmpty) {
        await _applyPromotionCode(initialCode, showSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPromotions = false;
        _promotionLoadError = 'Khong tai duoc danh sach voucher: $e';
      });
    }
  }

  PromotionResponse? _findPromotionByCode(String code) {
    final normalizedCode = code.trim().toUpperCase();
    for (final promotion in _promotions) {
      if (promotion.code.toUpperCase() == normalizedCode) {
        return promotion;
      }
    }
    return null;
  }

  Future<bool> _applyPromotionCode(
    String code, {
    PromotionResponse? promotion,
    bool showSuccess = true,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      _clearPromotion();
      return true;
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      setState(() {
        _promotionApplyError = 'Can dang nhap de ap dung voucher.';
      });
      return false;
    }

    setState(() {
      _applyingPromotion = true;
      _promotionApplyError = null;
    });

    try {
      final preview = await _promotionService.previewForUser(
        code: normalizedCode,
        userId: _currentUserId!,
        orderTotal: widget.draft.estimatedTotal,
      );
      if (!mounted) return false;
      final previewResult = _PromotionPreview.fromJson(preview);
      if (!previewResult.valid) {
        setState(() {
          _selectedPromotion = null;
          _promotionPreview = null;
          _applyingPromotion = false;
          _promotionApplyError = 'Voucher khong hop le voi don hang hien tai.';
        });
        return false;
      }

      _promotionCodeController.value = TextEditingValue(
        text: normalizedCode,
        selection: TextSelection.collapsed(offset: normalizedCode.length),
      );
      setState(() {
        _selectedPromotion = promotion ?? _findPromotionByCode(normalizedCode);
        _promotionPreview = previewResult;
        _applyingPromotion = false;
      });

      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Da ap dung voucher $normalizedCode'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return true;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              e.message)
          : e.message;
      if (!mounted) return false;
      setState(() {
        _selectedPromotion = null;
        _promotionPreview = null;
        _applyingPromotion = false;
        _promotionApplyError = message ?? 'Voucher khong hop le.';
      });
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _selectedPromotion = null;
        _promotionPreview = null;
        _applyingPromotion = false;
        _promotionApplyError = 'Khong ap dung duoc voucher: $e';
      });
      return false;
    }
  }

  Future<void> _applyTypedPromotion() async {
    await _applyPromotionCode(_promotionCodeController.text.trim());
  }

  void _clearPromotion() {
    _promotionCodeController.clear();
    setState(() {
      _selectedPromotion = null;
      _promotionPreview = null;
      _promotionApplyError = null;
    });
  }

  Future<void> _submitBooking() async {
    setState(() => _submitting = true);
    try {
      final typedCode = _promotionCodeController.text.trim();
      final appliedCode = _promotionPreview?.promotionCode.toUpperCase() ?? '';
      if (typedCode.isNotEmpty && appliedCode != typedCode.toUpperCase()) {
        final applied = await _applyPromotionCode(
          typedCode,
          promotion: _findPromotionByCode(typedCode),
          showSuccess: false,
        );
        if (!applied) return;
      }

      final draft = widget.draft.copyWith(
        promotionCode: typedCode,
        clearPromotionCode: typedCode.isEmpty,
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
          content: Text('Khong tao duoc booking: ${message ?? e}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong tao duoc booking: $e'),
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
    final subtotal = draft.estimatedTotal;
    final discountAmount = _promotionPreview?.discountAmount ?? 0;
    final total = _promotionPreview?.finalAmount ?? subtotal;
    final appliedPromotionCode = _promotionPreview?.promotionCode.toUpperCase();

    return BookingPageScaffold(
      title: 'Thong tin dat ve',
      bottomNavigationBar: BookingBottomBar(
        label: discountAmount > 0 ? 'Tong sau voucher' : 'Tong tam tinh',
        value: bookingFormatCurrency(total),
        note: discountAmount > 0
            ? 'Da giam ${bookingFormatCurrency(discountAmount)} voi voucher ${_promotionPreview!.promotionCode}.'
            : 'Kiem tra ky thong tin truoc khi sang buoc thanh toan.',
        buttonText: 'Den thanh toan',
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
                  'Thong tin ve',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Rap',
                  value: draft.showtime.cinemaName,
                ),
                _InfoRow(
                  label: 'Phong chieu',
                  value: draft.showtime.roomName,
                ),
                _InfoRow(
                  label: 'Suat chieu',
                  value: bookingFormatTimeRange(
                    draft.showtime.startTime,
                    draft.showtime.endTime,
                  ),
                ),
                _InfoRow(
                  label: 'Ngay xem',
                  value: bookingFormatDateLong(
                    DateTime.parse(draft.showtime.startTime).toLocal(),
                  ),
                ),
                _InfoRow(
                  label: 'Ghe da chon',
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
                  'Uu dai',
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
                  enabled: !_applyingPromotion,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhap ma khuyen mai neu co',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _applyTypedPromotion(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed:
                              _applyingPromotion ? null : _applyTypedPromotion,
                          icon: _applyingPromotion
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_offer_outlined,
                                  size: 18,
                                ),
                          label: const Text('Ap dung'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: TextButton(
                        onPressed: _promotionCodeController.text.trim().isEmpty &&
                                _promotionPreview == null
                            ? null
                            : _clearPromotion,
                        child: const Text('Bo chon'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_promotionPreview != null)
                  _AppliedPromotionCard(
                    preview: _promotionPreview!,
                    promotion: _selectedPromotion,
                  )
                else if (_promotionApplyError != null)
                  Text(
                    _promotionApplyError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Chon voucher trong danh sach hoac nhap ma de ap dung ngay.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Danh sach voucher',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loadingPromotions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_promotionLoadError != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _promotionLoadError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loadPromotions,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Tai lai voucher'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white12),
                        ),
                      ),
                    ],
                  )
                else if (_promotions.isEmpty)
                  const Text(
                    'Hien chua co voucher dang hoat dong.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  ..._promotions.map(
                    (promotion) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PromotionListTile(
                        promotion: promotion,
                        selected:
                            appliedPromotionCode == promotion.code.toUpperCase(),
                        onTap: () => _applyPromotionCode(
                          promotion.code,
                          promotion: promotion,
                        ),
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
                  'Combo & do an',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (draft.concessions.isEmpty)
                  const Text(
                    'Ban chua chon them combo hoac do an.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  ...draft.concessions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.itemType == ItemType.COMBO
                                        ? AppColors.primary.withValues(
                                            alpha: 0.16,
                                          )
                                        : AppColors.secondary.withValues(
                                            alpha: 0.14,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.itemType == ItemType.COMBO
                                        ? 'Combo'
                                        : 'Mon le',
                                    style: TextStyle(
                                      color: item.itemType == ItemType.COMBO
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${item.name} x${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
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
                  'Tong ket don hang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Tien ghe',
                  value: bookingFormatCurrency(seatTotal),
                ),
                _InfoRow(
                  label: 'Combo & do an',
                  value: bookingFormatCurrency(concessionTotal),
                ),
                if (discountAmount > 0)
                  _InfoRow(
                    label: 'Voucher',
                    value: '-${bookingFormatCurrency(discountAmount)}',
                    valueColor: AppColors.success,
                  ),
                const Divider(color: Colors.white12, height: 24),
                _InfoRow(
                  label: discountAmount > 0 ? 'Tong sau voucher' : 'Tong tam tinh',
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
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor =
        valueColor ?? (highlight ? AppColors.secondary : Colors.white);
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
                color: resolvedValueColor,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppliedPromotionCard extends StatelessWidget {
  final _PromotionPreview preview;
  final PromotionResponse? promotion;

  const _AppliedPromotionCard({
    required this.preview,
    required this.promotion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  promotion?.name ?? preview.promotionName ?? preview.promotionCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ma ${preview.promotionCode}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Giam ${bookingFormatCurrency(preview.discountAmount)}. Tong con ${bookingFormatCurrency(preview.finalAmount)}.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionListTile extends StatelessWidget {
  final PromotionResponse promotion;
  final bool selected;
  final VoidCallback onTap;

  const _PromotionListTile({
    required this.promotion,
    required this.selected,
    required this.onTap,
  });

  String get _discountLabel {
    if (promotion.discountType == DiscountType.PERCENTAGE) {
      return 'Giam ${promotion.discountValue.toInt()}%';
    }
    if (promotion.discountType == DiscountType.FIXED) {
      return 'Giam ${bookingFormatCurrency(promotion.discountValue)}';
    }
    return 'Voucher';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                promotion.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.minOrderValue != null
                        ? 'Toi thieu ${bookingFormatCurrency(promotion.minOrderValue!)}'
                        : 'Ap dung cho don hop le',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _discountLabel,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionPreview {
  final bool valid;
  final double discountAmount;
  final double finalAmount;
  final String promotionCode;
  final String? promotionName;

  const _PromotionPreview({
    required this.valid,
    required this.discountAmount,
    required this.finalAmount,
    required this.promotionCode,
    this.promotionName,
  });

  factory _PromotionPreview.fromJson(Map<String, dynamic> json) {
    return _PromotionPreview(
      valid: json['valid'] == true,
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      promotionCode: json['promotionCode']?.toString() ?? '',
      promotionName: json['promotionName']?.toString(),
    );
  }
}
