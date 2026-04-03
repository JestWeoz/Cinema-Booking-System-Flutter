import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/services/promotion_service.dart';

/// Trang Ưu Đãi — khuyến mãi đang hoạt động cho người dùng
class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final _promotionService = PromotionService.instance;
  final _codeController = TextEditingController();

  List<PromotionResponse> _promotions = [];
  bool _loading = true;
  String? _error;

  // Tra cứu mã
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final promotions = await _promotionService.getActive();
      setState(() {
        _promotions = promotions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Không thể tải khuyến mãi: $e';
      });
    }
  }

  Future<void> _searchByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _searching = true;
    });

    try {
      final promo = await _promotionService.getByCode(code);
      setState(() {
        _searching = false;
      });
      if (mounted) {
        _showPromoDetail(context, promo);
      }
    } catch (e) {
      setState(() {
        _searching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy mã "$code"'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ưu Đãi'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPromotions,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _loadPromotions)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Banner ──
                      _buildBanner(),
                      const SizedBox(height: 20),

                      // ── Tra cứu mã ──
                      _buildCodeSearch(),
                      const SizedBox(height: 20),

                      // ── Danh sách khuyến mãi ──
                      Row(
                        children: [
                          const Text('Ưu đãi đang hoạt động',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            '${_promotions.length} ưu đãi',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_promotions.isEmpty)
                        const _EmptyView(
                            message: 'Chưa có ưu đãi nào đang hoạt động')
                      else
                        ..._promotions.map((p) => _OfferCard(
                              promotion: p,
                              onTap: () => _showPromoDetail(context, p),
                              onCopy: () => _copyCode(p.code),
                            )),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.local_movies,
                size: 140, color: Colors.white10),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎬 Ưu đãi đặc biệt',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 4),
                Text('Tiết kiệm hơn mỗi ngày!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Nhập mã hoặc chọn ưu đãi bên dưới',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSearch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.confirmation_number_outlined,
                  size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('Tra cứu mã khuyến mãi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã ưu đãi...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.code, size: 18),
                  ),
                  onSubmitted: (_) => _searchByCode(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                width: 52,
                child: ElevatedButton(
                  onPressed: _searching ? null : _searchByCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPromoDetail(BuildContext context, PromotionResponse promo) {
    final color = _promoColor(promo.discountType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PromoDetailSheet(
        promotion: promo,
        color: color,
        onCopy: () => _copyCode(promo.code),
        promotionService: _promotionService,
      ),
    );
  }

  static Color _promoColor(DiscountType? type) {
    switch (type) {
      case DiscountType.PERCENT:
        return AppColors.primary;
      case DiscountType.FIXED:
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }
}

// ── Offer Card ──────────────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final PromotionResponse promotion;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _OfferCard({
    required this.promotion,
    required this.onTap,
    required this.onCopy,
  });

  Color get _color {
    switch (promotion.discountType) {
      case DiscountType.PERCENT:
        return AppColors.primary;
      case DiscountType.FIXED:
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }

  IconData get _icon {
    switch (promotion.discountType) {
      case DiscountType.PERCENT:
        return Icons.percent;
      case DiscountType.FIXED:
        return Icons.attach_money;
      default:
        return Icons.local_offer;
    }
  }

  String get _discountText {
    if (promotion.discountType == DiscountType.PERCENT) {
      return 'Giảm ${promotion.discountValue.toInt()}%';
    } else if (promotion.discountType == DiscountType.FIXED) {
      final fmt = NumberFormat('#,###', 'vi');
      return 'Giảm ${fmt.format(promotion.discountValue)}đ';
    }
    return 'Ưu đãi';
  }

  String? get _validityText {
    if (promotion.startDate == null && promotion.endDate == null) return null;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final parts = <String>[];
    if (promotion.startDate != null) {
      try {
        parts.add('Từ ${dateFmt.format(DateTime.parse(promotion.startDate!))}');
      } catch (_) {}
    }
    if (promotion.endDate != null) {
      try {
        parts.add('đến ${dateFmt.format(DateTime.parse(promotion.endDate!))}');
      } catch (_) {}
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (promotion.quantity != null && promotion.usedQuantity != null)
        ? promotion.quantity! - promotion.usedQuantity!
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 26),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(promotion.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_discountText,
                              style: TextStyle(fontSize: 10, color: _color)),
                        ),
                      ],
                    ),
                    if (promotion.description != null) ...[
                      const SizedBox(height: 4),
                      Text(promotion.description!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Promo code chip
                        GestureDetector(
                          onTap: onCopy,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.dividerDark),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(promotion.code,
                                    style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Remaining quantity
                        if (remaining != null)
                          Text(
                            'Còn $remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: remaining > 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    if (_validityText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _validityText!,
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Promo Detail Bottom Sheet ───────────────────────────────────────────────
class _PromoDetailSheet extends StatefulWidget {
  final PromotionResponse promotion;
  final Color color;
  final VoidCallback onCopy;
  final PromotionService promotionService;

  const _PromoDetailSheet({
    required this.promotion,
    required this.color,
    required this.onCopy,
    required this.promotionService,
  });

  @override
  State<_PromoDetailSheet> createState() => _PromoDetailSheetState();
}

class _PromoDetailSheetState extends State<_PromoDetailSheet> {
  final _previewAmountController = TextEditingController();
  bool _previewing = false;
  Map<String, dynamic>? _previewResult;
  String? _previewError;

  @override
  void dispose() {
    _previewAmountController.dispose();
    super.dispose();
  }

  Future<void> _previewPromo() async {
    final amountStr = _previewAmountController.text.trim();
    if (amountStr.isEmpty) return;

    final amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null || amount <= 0) {
      setState(() => _previewError = 'Vui lòng nhập số tiền hợp lệ');
      return;
    }

    setState(() {
      _previewing = true;
      _previewResult = null;
      _previewError = null;
    });

    try {
      final result = await widget.promotionService.preview(
        code: widget.promotion.code,
        orderTotal: amount,
      );
      setState(() {
        _previewing = false;
        _previewResult = result;
      });
    } catch (e) {
      setState(() {
        _previewing = false;
        _previewError = 'Không thể xem trước: $e';
      });
    }
  }

  String _formatCurrency(dynamic value) {
    final fmt = NumberFormat('#,###', 'vi');
    if (value is num) {
      return '${fmt.format(value)}đ';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promotion;
    final color = widget.color;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                promo.discountType == DiscountType.PERCENT
                    ? Icons.percent
                    : Icons.attach_money,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(promo.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Description
            if (promo.description != null)
              Text(promo.description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // Details table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerDark),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Loại giảm giá',
                    value: promo.discountType == DiscountType.PERCENT
                        ? 'Giảm ${promo.discountValue.toInt()}%'
                        : 'Giảm ${_formatCurrency(promo.discountValue)}',
                  ),
                  if (promo.minOrderValue != null)
                    _DetailRow(
                      label: 'Đơn tối thiểu',
                      value: _formatCurrency(promo.minOrderValue),
                    ),
                  if (promo.maxDiscount != null)
                    _DetailRow(
                      label: 'Giảm tối đa',
                      value: _formatCurrency(promo.maxDiscount),
                    ),
                  if (promo.quantity != null)
                    _DetailRow(
                      label: 'Số lượng',
                      value:
                          '${promo.usedQuantity ?? 0}/${promo.quantity} đã dùng',
                    ),
                  if (promo.maxUsagePerUser != null)
                    _DetailRow(
                      label: 'Giới hạn/người',
                      value: '${promo.maxUsagePerUser} lần',
                    ),
                  if (promo.startDate != null)
                    _DetailRow(
                      label: 'Bắt đầu',
                      value: (() {
                        try {
                          return dateFmt
                              .format(DateTime.parse(promo.startDate!));
                        } catch (_) {
                          return promo.startDate!;
                        }
                      })(),
                    ),
                  if (promo.endDate != null)
                    _DetailRow(
                      label: 'Kết thúc',
                      value: (() {
                        try {
                          return dateFmt.format(DateTime.parse(promo.endDate!));
                        } catch (_) {
                          return promo.endDate!;
                        }
                      })(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Code box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(promo.code,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 2)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      widget.onCopy();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Preview section ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.preview_outlined,
                          size: 16, color: AppColors.secondary),
                      SizedBox(width: 6),
                      Text('Xem trước giảm giá',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _previewAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Nhập số tiền đơn hàng...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixText: 'đ',
                          ),
                          onSubmitted: (_) => _previewPromo(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _previewing ? null : _previewPromo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _previewing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Xem',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  if (_previewError != null) ...[
                    const SizedBox(height: 8),
                    Text(_previewError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ],
                  if (_previewResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          if (_previewResult!['discount'] != null)
                            _DetailRow(
                              label: 'Giảm giá',
                              value: _formatCurrency(
                                  _previewResult!['discount']),
                              valueColor: AppColors.success,
                            ),
                          if (_previewResult!['finalTotal'] != null)
                            _DetailRow(
                              label: 'Tổng sau giảm',
                              value: _formatCurrency(
                                  _previewResult!['finalTotal']),
                              valueColor: AppColors.secondary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Use button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onCopy();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Sao chép mã & đóng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Row ──────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
