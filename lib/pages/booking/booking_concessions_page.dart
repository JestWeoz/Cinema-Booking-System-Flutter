import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/create_booking_request.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_review_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/services/combo_service.dart';
import 'package:cinema_booking_system_app/services/product_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class BookingConcessionsPage extends StatefulWidget {
  final BookingFlowDraft draft;

  const BookingConcessionsPage({
    super.key,
    required this.draft,
  });

  @override
  State<BookingConcessionsPage> createState() => _BookingConcessionsPageState();
}

class _BookingConcessionsPageState extends State<BookingConcessionsPage> {
  final ComboService _comboService = ComboService.instance;
  final ProductService _productService = ProductService.instance;
  final Map<String, BookingItemSelection> _selectedItems = {};

  List<ComboResponse> _combos = const [];
  List<ProductResponse> _products = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.draft.concessions) {
      _selectedItems[_keyOf(item.itemType, item.itemId)] = item;
    }
    _loadConcessions();
  }

  String _keyOf(ItemType type, String itemId) => '${type.name}_$itemId';

  Future<void> _loadConcessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _comboService.getActive(),
        _productService.getActive(),
      ]);
      if (!mounted) return;
      setState(() {
        _combos = results[0] as List<ComboResponse>;
        _products = results[1] as List<ProductResponse>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được combo và sản phẩm: $e';
      });
    }
  }

  void _updateSelection({
    required ItemType type,
    required String itemId,
    required String name,
    required double price,
    String? imageUrl,
    required List<BookingProductItem> requestItems,
    required int delta,
  }) {
    final key = _keyOf(type, itemId);
    final current = _selectedItems[key];
    final nextQuantity = (current?.quantity ?? 0) + delta;
    setState(() {
      if (nextQuantity <= 0) {
        _selectedItems.remove(key);
      } else {
        _selectedItems[key] = BookingItemSelection(
          itemId: itemId,
          name: name,
          itemType: type,
          unitPrice: price,
          quantity: nextQuantity,
          imageUrl: imageUrl,
          requestItems: requestItems,
        );
      }
    });
  }

  int _quantityOf(ItemType type, String itemId) {
    return _selectedItems[_keyOf(type, itemId)]?.quantity ?? 0;
  }

  void _goNext() {
    final nextDraft = widget.draft.copyWith(
      concessions: _selectedItems.values.toList(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingReviewPage(draft: nextDraft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedItems.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final concessionTotal = _selectedItems.values.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final estimatedTotal = widget.draft.seatSubtotal + concessionTotal;

    return BookingPageScaffold(
      title: 'Combo & đồ ăn',
      bottomNavigationBar: BookingBottomBar(
        label: 'Tạm tính',
        value: bookingFormatCurrency(estimatedTotal),
        note: selectedCount == 0
            ? 'Bạn có thể bỏ qua bước này nếu không mua thêm.'
            : 'Đã chọn $selectedCount món/combo ăn kèm.',
        buttonText: 'Tiếp tục',
        onPressed: _goNext,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          BookingMovieStrip(
            title: widget.draft.movie.title,
            posterUrl: widget.draft.movie.posterUrl,
            ageRating: widget.draft.movie.ageRating,
            subtitle:
                '${widget.draft.showtime.cinemaName} • ${widget.draft.seatLabel.isEmpty ? 'Chưa chọn ghế' : widget.draft.seatLabel}',
          ),
          const SizedBox(height: 16),
          BookingSectionCard(
            child: Row(
              children: [
                _SummaryBadge(
                  icon: Icons.event_seat_outlined,
                  label: 'Tiền ghế',
                  value: bookingFormatCurrency(widget.draft.seatSubtotal),
                ),
                const SizedBox(width: 10),
                _SummaryBadge(
                  icon: Icons.local_mall_outlined,
                  label: 'Đồ ăn',
                  value: bookingFormatCurrency(concessionTotal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            BookingSectionCard(
              child: Column(
                children: [
                  const Icon(Icons.fastfood_outlined,
                      color: Colors.white38, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loadConcessions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            )
          else ...[
            if (_combos.isNotEmpty) ...[
              const Text(
                'Combo bắp nước',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ..._combos.map(
                (combo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ConcessionCard(
                    title: combo.name,
                    subtitle: combo.description ??
                        'Combo tiện lợi cho buổi xem phim.',
                    imageUrl: combo.image,
                    price: combo.price,
                    quantity: _quantityOf(ItemType.COMBO, combo.id),
                    onDecrease: () => _updateSelection(
                      type: ItemType.COMBO,
                      itemId: combo.id,
                      name: combo.name,
                      price: combo.price,
                      imageUrl: combo.image,
                      requestItems: combo.items
                          .map(
                            (item) => BookingProductItem(
                              itemId: item.productId,
                              itemType: ItemType.PRODUCT,
                              quantity: item.quantity,
                            ),
                          )
                          .toList(),
                      delta: -1,
                    ),
                    onIncrease: () => _updateSelection(
                      type: ItemType.COMBO,
                      itemId: combo.id,
                      name: combo.name,
                      price: combo.price,
                      imageUrl: combo.image,
                      requestItems: combo.items
                          .map(
                            (item) => BookingProductItem(
                              itemId: item.productId,
                              itemType: ItemType.PRODUCT,
                              quantity: item.quantity,
                            ),
                          )
                          .toList(),
                      delta: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_products.isNotEmpty) ...[
              const Text(
                'Bắp & nước lẻ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ..._products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ConcessionCard(
                    title: product.name,
                    subtitle: 'Thêm món riêng theo sở thích của bạn.',
                    imageUrl: product.image,
                    price: product.price,
                    quantity: _quantityOf(ItemType.PRODUCT, product.id),
                    onDecrease: () => _updateSelection(
                      type: ItemType.PRODUCT,
                      itemId: product.id,
                      name: product.name,
                      price: product.price,
                      imageUrl: product.image,
                      requestItems: [
                        BookingProductItem(
                          itemId: product.id,
                          itemType: ItemType.PRODUCT,
                          quantity: 1,
                        ),
                      ],
                      delta: -1,
                    ),
                    onIncrease: () => _updateSelection(
                      type: ItemType.PRODUCT,
                      itemId: product.id,
                      name: product.name,
                      price: product.price,
                      imageUrl: product.image,
                      requestItems: [
                        BookingProductItem(
                          itemId: product.id,
                          itemType: ItemType.PRODUCT,
                          quantity: 1,
                        ),
                      ],
                      delta: 1,
                    ),
                  ),
                ),
              ),
            ],
            if (_combos.isEmpty && _products.isEmpty)
              const BookingSectionCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.no_food_outlined,
                          color: Colors.white38, size: 42),
                      SizedBox(height: 8),
                      Text(
                        'Hiện chưa có combo hoặc đồ ăn đang mở bán.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final double price;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ConcessionCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return BookingSectionCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AppNetworkImage(
              url: imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              fallbackIcon: Icons.fastfood_outlined,
              backgroundColor: AppColors.cardDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  bookingFormatCurrency(price),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: Icons.remove,
                  onTap: quantity == 0 ? null : onDecrease,
                ),
                SizedBox(
                  width: 34,
                  child: Center(
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add,
                  onTap: onIncrease,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.primary.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.white24 : AppColors.primary,
        ),
      ),
    );
  }
}
