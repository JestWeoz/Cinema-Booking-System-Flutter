import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

/// Trang Ưu Đãi — chương trình giảm giá, mã khuyến mãi
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  static const List<Map<String, dynamic>> _offers = [
    {
      'title': 'Thứ 3 Vui Vẻ',
      'desc': 'Giảm 30% tất cả vé xem phim vào thứ Ba hàng tuần',
      'code': 'TUESDAY30',
      'tag': 'Hàng tuần',
      'color': Color(0xFFE50914),
      'icon': Icons.local_offer,
    },
    {
      'title': 'Combo Đôi',
      'desc': 'Mua 2 vé tặng 2 bắp rang & 2 nước ngọt',
      'code': 'COUPLE2',
      'tag': 'Combo',
      'color': Color(0xFFFFC107),
      'icon': Icons.people,
    },
    {
      'title': 'Sinh Nhật Vàng',
      'desc': 'Miễn phí 1 vé xem phim trong tháng sinh nhật',
      'code': 'BIRTHDAY',
      'tag': 'Thành viên',
      'color': Color(0xFF4CAF50),
      'icon': Icons.cake,
    },
    {
      'title': 'Thẻ Sinh Viên',
      'desc': 'Giảm 20% khi xuất trình thẻ sinh viên hợp lệ',
      'code': 'STUDENT20',
      'tag': 'Sinh viên',
      'color': Color(0xFF2196F3),
      'icon': Icons.school,
    },
    {
      'title': 'Cuối Tuần Gia Đình',
      'desc': 'Mua 4 vé chỉ tính tiền 3 vé vào Thứ 7 & CN',
      'code': 'FAMILY4',
      'tag': 'Cuối tuần',
      'color': Color(0xFF9C27B0),
      'icon': Icons.family_restroom,
    },
    {
      'title': 'Tân Binh',
      'desc': 'Đặt vé lần đầu giảm ngay 50k',
      'code': 'NEWUSER50',
      'tag': 'Lần đầu',
      'color': Color(0xFFFF5722),
      'icon': Icons.star_border,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ưu Đãi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
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
                  child: Icon(Icons.local_movies, size: 140, color: Colors.white10),
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
                      Text('Sử dụng mã để nhận ưu đãi',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid of offers
          const Text('Tất cả ưu đãi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._offers.map((o) => _OfferCard(offer: o)),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final color = offer['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(offer['icon'] as IconData, color: color, size: 26),
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
                          child: Text(offer['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(offer['tag'] as String,
                              style: TextStyle(fontSize: 10, color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(offer['desc'] as String,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    // Promo code chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(offer['code'] as String,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = offer['color'] as Color;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(offer['icon'] as IconData, color: color, size: 48),
            const SizedBox(height: 12),
            Text(offer['title'] as String,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(offer['desc'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
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
                  Text(offer['code'] as String,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 2)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Dùng ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
