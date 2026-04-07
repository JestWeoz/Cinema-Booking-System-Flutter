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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.cardDark,
            AppColors.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_view_rounded,
                  color: AppColors.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Sơ đồ ghế phòng chiếu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(cinemaName,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            roomName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chạm vào từng ghế để chỉnh sửa nhanh, bật/tắt hoặc xoá.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SeatPill(
                  icon: Icons.event_seat_outlined,
                  text: '$seatCount ghế',
                  color: AppColors.primary),
              ...seatTypes.map(
                (type) => _SeatPill(
                  icon: Icons.sell_outlined,
                  text:
                      '${type.name} (${type.priceModifier >= 0 ? '+' : ''}${type.priceModifier.toStringAsFixed(0)})',
                  color: _seatTypeAccent(type.name),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SeatMapBoard extends StatelessWidget {
  final Map<String, List<SeatResponse>> groupedSeats;
  final List<SeatTypeResponse> seatTypes;
  final ValueChanged<SeatResponse> onTapSeat;

  const SeatMapBoard({
    super.key,
    required this.groupedSeats,
    required this.seatTypes,
    required this.onTapSeat,
  });

  List<String> get _rows => groupedSeats.keys.toList()..sort();

  List<int> get _seatNumbers {
    final numbers = groupedSeats.values
        .expand((seats) => seats.map((seat) => seat.seatNumber))
        .toSet()
        .toList()
      ..sort();
    return numbers;
  }

  int get _seatCount =>
      groupedSeats.values.fold(0, (sum, seats) => sum + seats.length);

  int get _inactiveCount => groupedSeats.values
      .expand((seats) => seats)
      .where((seat) => !seat.active)
      .length;

  Map<String, Map<int, SeatResponse>> get _seatLookup => {
        for (final entry in groupedSeats.entries)
          entry.key: {
            for (final seat in entry.value) seat.seatNumber: seat,
          },
      };

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final seatNumbers = _seatNumbers;
    final seatLookup = _seatLookup;
    final mapWidth = (seatNumbers.length * 60) + 88;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF191919), Color(0xFF101010)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seat Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rows.length} hàng • $_seatCount ghế • $_inactiveCount ghế đang tắt',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.28)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Nhấn ghế để sửa',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SeatScreen(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: mapWidth.toDouble()),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _SeatNumberHeader(numbers: seatNumbers),
                        const SizedBox(height: 10),
                        ...rows.map(
                          (rowLabel) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SeatGridRow(
                              rowLabel: rowLabel,
                              seatNumbers: seatNumbers,
                              rowSeats: seatLookup[rowLabel] ?? const {},
                              onTapSeat: onTapSeat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _SeatLegendItem(
                label: 'Ghế thường',
                fillColor: Color(0xFF2A2236),
                borderColor: Color(0xFF8A63D2),
                textColor: Colors.white70,
              ),
              const _SeatLegendItem(
                label: 'Ghế VIP',
                fillColor: Color(0xFF332A17),
                borderColor: Color(0xFFD9A400),
                textColor: Colors.white70,
              ),
              const _SeatLegendItem(
                label: 'Ghế đôi',
                fillColor: Color(0xFF311D27),
                borderColor: Color(0xFFE27AA8),
                textColor: Colors.white70,
              ),
              const _SeatLegendItem(
                label: 'Ngừng hoạt động',
                fillColor: Color(0xFF23262B),
                borderColor: Color(0xFF9CA3AF),
                textColor: Colors.white70,
              ),
              ...seatTypes.map(
                (type) => _SeatLegendItem(
                  label: type.name,
                  fillColor: _seatFillColor(type.name),
                  borderColor: _seatBorderColor(type.name),
                  textColor: _seatTextColor(type.name),
                ),
              ),
            ],
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
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
          Icon(Icons.event_seat_outlined,
              size: 56, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 14),
          const Text(
            'Chưa có ghế trong phòng',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999)),
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

class _SeatScreen extends StatelessWidget {
  const _SeatScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5BAA), Color(0xFFE50914)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5BAA).withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'MÀN HÌNH',
            style: TextStyle(
              color: Colors.white60,
              letterSpacing: 7,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatNumberHeader extends StatelessWidget {
  final List<int> numbers;

  const _SeatNumberHeader({required this.numbers});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44),
        ...numbers.map(
          (number) => SizedBox(
            width: 56,
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SeatGridRow extends StatelessWidget {
  final String rowLabel;
  final List<int> seatNumbers;
  final Map<int, SeatResponse> rowSeats;
  final ValueChanged<SeatResponse> onTapSeat;

  const _SeatGridRow({
    required this.rowLabel,
    required this.seatNumbers,
    required this.rowSeats,
    required this.onTapSeat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RowBadge(label: rowLabel),
        ...seatNumbers.map(
          (seatNumber) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: rowSeats[seatNumber] == null
                ? const SizedBox(width: 50, height: 50)
                : _SeatMapCell(
                    seat: rowSeats[seatNumber]!,
                    onTap: () => onTapSeat(rowSeats[seatNumber]!),
                  ),
          ),
        ),
        _RowBadge(label: rowLabel),
      ],
    );
  }
}

class _RowBadge extends StatelessWidget {
  final String label;

  const _RowBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF221A31),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB996FF),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatMapCell extends StatelessWidget {
  final SeatResponse seat;
  final VoidCallback onTap;

  const _SeatMapCell({
    required this.seat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = seat.active
        ? _seatFillColor(seat.seatTypeName)
        : const Color(0xFF23262B);
    final borderColor = seat.active
        ? _seatBorderColor(seat.seatTypeName)
        : const Color(0xFF9CA3AF);
    final textColor = seat.active
        ? _seatTextColor(seat.seatTypeName)
        : const Color(0xFFB8BEC9);

    return Tooltip(
      message:
          '${seat.seatRow}${seat.seatNumber} • ${seat.seatTypeName ?? 'Không rõ'} • ${seat.active ? 'Đang hoạt động' : 'Ngừng hoạt động'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${seat.seatRow}${seat.seatNumber}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatLegendItem extends StatelessWidget {
  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  const _SeatLegendItem({
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _seatTypeAccent(String? seatTypeName) {
  final normalized = seatTypeName?.toLowerCase() ?? '';
  if (normalized.contains('vip')) return const Color(0xFFD9A400);
  if (normalized.contains('couple') ||
      normalized.contains('doi') ||
      normalized.contains('đôi')) {
    return const Color(0xFFD33C8A);
  }
  return const Color(0xFF7C4DCC);
}

Color _seatFillColor(String? seatTypeName) {
  final normalized = seatTypeName?.toLowerCase() ?? '';
  if (normalized.contains('vip')) return const Color(0xFF332A17);
  if (normalized.contains('couple') ||
      normalized.contains('doi') ||
      normalized.contains('đôi')) {
    return const Color(0xFF311D27);
  }
  return const Color(0xFF2A2236);
}

Color _seatBorderColor(String? seatTypeName) {
  final normalized = seatTypeName?.toLowerCase() ?? '';
  if (normalized.contains('vip')) return const Color(0xFFD9A400);
  if (normalized.contains('couple') ||
      normalized.contains('doi') ||
      normalized.contains('đôi')) {
    return const Color(0xFFE27AA8);
  }
  return const Color(0xFF8A63D2);
}

Color _seatTextColor(String? seatTypeName) {
  final normalized = seatTypeName?.toLowerCase() ?? '';
  if (normalized.contains('vip')) return const Color(0xFFFFD76A);
  if (normalized.contains('couple') ||
      normalized.contains('doi') ||
      normalized.contains('đôi')) {
    return const Color(0xFFFF9BC7);
  }
  return const Color(0xFFD6C2FF);
}
