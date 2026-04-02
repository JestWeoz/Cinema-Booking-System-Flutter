import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class AdminStatPage extends StatelessWidget {
  const AdminStatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Thống Kê', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(title: 'Tổng Doanh Thu', value: '125,000,000 ₫',
              icon: Icons.attach_money_rounded, color: AppColors.secondary),
          const SizedBox(height: 12),
          _StatCard(title: 'Tổng Số Vé', value: '2,245', icon: Icons.confirmation_number, color: AppColors.primary),
          const SizedBox(height: 12),
          _StatCard(title: 'Phòng Chiếu', value: '12', icon: Icons.meeting_room_outlined, color: const Color(0xFF9C27B0)),
          const SizedBox(height: 12),
          _StatCard(title: 'Khách Hàng', value: '125', icon: Icons.people_outline, color: AppColors.info),
          const SizedBox(height: 24),
          const Text('Doanh Thu 7 Ngày Qua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
            child: CustomPaint(painter: _BarChartPainter()),
          ),
          const SizedBox(height: 24),
          const Text('Top Phim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._topMovies.map((m) => _TopMovieItem(title: m['title']!, revenue: m['revenue']!)),
        ],
      ),
    );
  }

  static const _topMovies = [
    {'title': 'Avengers: Endgame', 'revenue': '45,000,000 ₫'},
    {'title': 'Mission Impossible', 'revenue': '32,000,000 ₫'},
    {'title': 'The Dark Knight', 'revenue': '28,000,000 ₫'},
  ];
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          colors: [AppColors.cardDark, color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
        ]),
      ]),
    );
  }
}

class _TopMovieItem extends StatelessWidget {
  final String title;
  final String revenue;
  const _TopMovieItem({required this.title, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
      child: Row(children: [
        const Icon(Icons.movie_outlined, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        Text(revenue, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values = const [0.4, 0.7, 0.55, 0.9, 0.65, 0.8, 0.6];
  final List<String> labels = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width / values.length) * 0.5;
    final gap = size.width / values.length;
    final paint = Paint()..shader = const LinearGradient(
      colors: [AppColors.primary, Color(0xFFFF6B6B)],
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < values.length; i++) {
      final x = gap * i + gap / 2 - barWidth / 2;
      final barH = size.height * 0.8 * values[i];
      final top = size.height * 0.8 - barH;
      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barWidth, barH),
        topLeft: const Radius.circular(6), topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rrect, paint);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: Colors.white54, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, size.height * 0.85));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
