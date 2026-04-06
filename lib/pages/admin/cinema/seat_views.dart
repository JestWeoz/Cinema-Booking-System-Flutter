import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/services/room_seat_service.dart';

class SeatHeader extends StatelessWidget {
  final String cinemaName;
  final String roomName;
  final int seatCount;
  final List<SeatTypeResponse> seatTypes;

  const SeatHeader({
    super.key,
    required this.cinemaName,
    required this.roomName,
    required this.seatCount,
    required this.seatTypes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cinemaName, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SeatPill(icon: Icons.event_seat_outlined, text: '$seatCount ghế', color: AppColors.primary),
              ...seatTypes.map(
                (type) => _SeatPill(
                  icon: Icons.sell_outlined,
                  text: '${type.name} (${type.priceModifier >= 0 ? '+' : ''}${type.priceModifier.toStringAsFixed(0)})',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SeatRowCard extends StatelessWidget {
  final String rowLabel;
  final List<SeatResponse> seats;
  final ValueChanged<SeatResponse> onTapSeat;

  const SeatRowCard({
    super.key,
    required this.rowLabel,
    required this.seats,
    required this.onTapSeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hàng $rowLabel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: seats.map((seat) => _SeatChip(seat: seat, onTap: () => onTapSeat(seat))).toList(),
          ),
        ],
      ),
    );
  }
}

class SeatErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SeatErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class SeatEmptyView extends StatelessWidget {
  const SeatEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_seat_outlined, size: 56, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          const Text(
            'Chưa có ghế trong phòng',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo ghế lẻ hoặc tạo hàng loạt để hoàn thiện sơ đồ phòng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _SeatPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SeatPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SeatChip extends StatelessWidget {
  final SeatResponse seat;
  final VoidCallback onTap;

  const _SeatChip({
    required this.seat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = seat.active ? AppColors.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text('${seat.seatRow}${seat.seatNumber}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              seat.seatTypeName ?? 'N/A',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(seat.active ? 'Active' : 'Inactive', style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
