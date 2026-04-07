import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_concessions_page.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_flow_models.dart';
import 'package:cinema_booking_system_app/pages/booking/booking_ui.dart';
import 'package:cinema_booking_system_app/services/showtime_service.dart';

class BookingSeatPage extends StatefulWidget {
  final BookingFlowDraft draft;

  const BookingSeatPage({
    super.key,
    required this.draft,
  });

  @override
  State<BookingSeatPage> createState() => _BookingSeatPageState();
}

class _BookingSeatPageState extends State<BookingSeatPage> {
  final ShowtimeService _showtimeService = ShowtimeService.instance;
  SeatMapResponse? _seatMap;
  final Map<String, ShowtimeSeatResponse> _selectedSeats = {};
  bool _loading = true;
  bool _processingSeat = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final seat in widget.draft.seats) {
      _selectedSeats[seat.seatId] = seat;
    }
    _loadSeatMap();
  }

  Future<void> _loadSeatMap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _showtimeService.getSeatMap(widget.draft.showtime.id),
        _showtimeService.getMyLockedSeats(widget.draft.showtime.id),
      ]);
      final seatMap = results[0] as SeatMapResponse;
      final myLockedSeats = results[1] as List<ShowtimeSeatResponse>;
      for (final seat in myLockedSeats) {
        _selectedSeats[seat.seatId] = seat;
      }
      if (!mounted) return;
      setState(() {
        _seatMap = seatMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được sơ đồ ghế: $e';
      });
    }
  }

  List<String> get _rows {
    final map = _seatMap?.seatMap ?? const {};
    final rows = map.keys.toList()..sort();
    return rows;
  }

  List<int> get _seatNumbers {
    final map = _seatMap?.seatMap ?? const {};
    final numbers = map.values
        .expand((items) => items.map((seat) => seat.seatNumber))
        .toSet()
        .toList()
      ..sort();
    return numbers;
  }

  Map<String, Map<int, ShowtimeSeatResponse>> get _seatLookup {
    final map = _seatMap?.seatMap ?? const {};
    return {
      for (final entry in map.entries)
        entry.key: {for (final seat in entry.value) seat.seatNumber: seat},
    };
  }

  ShowtimeSeatResponse _copySeat(
    ShowtimeSeatResponse seat, {
    SeatStatus? status,
    String? lockedUntil,
    String? lockedByUser,
  }) {
    return ShowtimeSeatResponse(
      showtimeSeatId: seat.showtimeSeatId,
      seatId: seat.seatId,
      seatRow: seat.seatRow,
      seatNumber: seat.seatNumber,
      seatType: seat.seatType,
      finalPrice: seat.finalPrice,
      status: status ?? seat.status,
      lockedUntil: lockedUntil ?? seat.lockedUntil,
      lockedByUser: lockedByUser ?? seat.lockedByUser,
    );
  }

  void _updateSeatMapSeat(ShowtimeSeatResponse updated) {
    final current = _seatMap;
    if (current == null) return;
    final rowSeats = current.seatMap[updated.seatRow];
    if (rowSeats == null) return;
    final replaced = rowSeats
        .map((seat) => seat.seatId == updated.seatId ? updated : seat)
        .toList();
    setState(() {
      _seatMap = SeatMapResponse(
        showtimeId: current.showtimeId,
        totalSeats: current.totalSeats,
        availableSeats: current.availableSeats,
        seatMap: {
          ...current.seatMap,
          updated.seatRow: replaced,
        },
      );
    });
  }

  Future<void> _toggleSeat(ShowtimeSeatResponse seat) async {
    if (_processingSeat) return;
    final isSelected = _selectedSeats.containsKey(seat.seatId);
    if (!isSelected &&
        (seat.status == SeatStatus.BOOKED ||
            seat.status == SeatStatus.LOCKED)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghế này hiện không thể chọn.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _processingSeat = true);
    try {
      if (isSelected) {
        await _showtimeService
            .unlockSeats(widget.draft.showtime.id, [seat.seatId]);
        _selectedSeats.remove(seat.seatId);
        _updateSeatMapSeat(
          _copySeat(
            seat,
            status: SeatStatus.AVAILABLE,
            lockedUntil: '',
            lockedByUser: '',
          ),
        );
      } else {
        final locked = await _showtimeService.lockSeats(
          widget.draft.showtime.id,
          [seat.seatId],
        );
        final lockedSeat = locked.isNotEmpty ? locked.first : seat;
        _selectedSeats[seat.seatId] = lockedSeat;
        _updateSeatMapSeat(
          _copySeat(
            lockedSeat,
            status: SeatStatus.LOCKED,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _processingSeat = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingSeat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không cập nhật được ghế: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _goNext() {
    final selected = _selectedSeats.values.toList()
      ..sort((a, b) {
        final byRow = a.seatRow.compareTo(b.seatRow);
        return byRow != 0 ? byRow : a.seatNumber.compareTo(b.seatNumber);
      });
    final nextDraft = widget.draft.copyWith(seats: selected);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConcessionsPage(draft: nextDraft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seatMap = _seatMap;
    final seatLookup = _seatLookup;
    final seatNumbers = _seatNumbers;
    final rows = _rows;
    final selectedTotal = _selectedSeats.values.fold<double>(
      0,
      (sum, seat) => sum + seat.finalPrice,
    );
    final mapWidth = (seatNumbers.length * 62) + 96;

    return BookingPageScaffold(
      title: 'Chọn ghế',
      bottomNavigationBar: BookingBottomBar(
        label: 'Tạm tính ghế',
        value: bookingFormatCurrency(selectedTotal),
        note: _selectedSeats.isEmpty
            ? 'Chọn ghế để tiếp tục sang bước combo.'
            : 'Đã chọn ${_selectedSeats.length} ghế: ${_selectedSeats.values.map((seat) => '${seat.seatRow}${seat.seatNumber}').join(', ')}',
        buttonText: 'Tiếp tục',
        onPressed: _selectedSeats.isEmpty ? null : _goNext,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          BookingMovieStrip(
            title: widget.draft.movie.title,
            posterUrl: widget.draft.movie.posterUrl,
            ageRating: widget.draft.movie.ageRating,
            subtitle:
                '${widget.draft.showtime.cinemaName} • ${bookingFormatDateTime(widget.draft.showtime.startTime)}',
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
                  const Icon(Icons.event_seat_outlined,
                      color: Colors.white38, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _loadSeatMap,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            )
          else if (seatMap != null) ...[
            BookingSectionCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sơ đồ phòng chiếu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${seatMap.availableSeats}/${seatMap.totalSeats} ghế đang còn trống',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  const _SeatScreenBanner(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minWidth: mapWidth.toDouble()),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _SeatNumberHeader(numbers: seatNumbers),
                                const SizedBox(height: 10),
                                ...rows.map(
                                  (rowLabel) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        _RowBadge(label: rowLabel),
                                        ...seatNumbers.map(
                                          (seatNumber) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 3),
                                            child: Builder(
                                              builder: (_) {
                                                final seat =
                                                    seatLookup[rowLabel]
                                                        ?[seatNumber];
                                                if (seat == null) {
                                                  return const SizedBox(
                                                      width: 50, height: 50);
                                                }
                                                final selected = _selectedSeats
                                                    .containsKey(seat.seatId);
                                                return _SeatCell(
                                                  seat: seat,
                                                  selected: selected,
                                                  onTap: () =>
                                                      _toggleSeat(seat),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        _RowBadge(label: rowLabel),
                                      ],
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
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _LegendPill(
                        label: 'Ghế thường',
                        fill: Color(0xFF221A31),
                        border: Color(0xFFA575FF),
                        text: Color(0xFFE0CCFF),
                      ),
                      _LegendPill(
                        label: 'Ghế VIP',
                        fill: Color(0xFF2E2411),
                        border: Color(0xFFD9A400),
                        text: Color(0xFFFFD76A),
                      ),
                      _LegendPill(
                        label: 'Ghế đôi',
                        fill: Color(0xFF311D27),
                        border: Color(0xFFE27AA8),
                        text: Color(0xFFFF9BC7),
                      ),
                      _LegendPill(
                        label: 'Bạn chọn',
                        fill: AppColors.primary,
                        border: AppColors.primaryLight,
                        text: Colors.white,
                      ),
                      _LegendPill(
                        label: 'Đã đặt',
                        fill: Color(0xFF2A2D33),
                        border: Color(0xFF6B7280),
                        text: Color(0xFFB8BEC9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeatScreenBanner extends StatelessWidget {
  const _SeatScreenBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6AA2), AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'MÀN HÌNH',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
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
        const SizedBox(width: 40),
        ...numbers.map(
          (number) => SizedBox(
            width: 56,
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
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
      width: 40,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatCell extends StatelessWidget {
  final ShowtimeSeatResponse seat;
  final bool selected;
  final VoidCallback onTap;

  const _SeatCell({
    required this.seat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = seat.status == SeatStatus.BOOKED;
    final isLocked = seat.status == SeatStatus.LOCKED && !selected;
    final disabled = isBooked || isLocked;
    final fill = disabled
        ? const Color(0xFF2A2D33)
        : bookingSeatFillColor(seat.seatType, selected: selected);
    final border = disabled
        ? const Color(0xFF6B7280)
        : bookingSeatBorderColor(seat.seatType, selected: selected);
    final text = disabled
        ? const Color(0xFFB8BEC9)
        : bookingSeatTextColor(seat.seatType, selected: selected);

    return Tooltip(
      message:
          '${seat.seatRow}${seat.seatNumber} • ${bookingFormatCurrency(seat.finalPrice)}',
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Center(
            child: Text(
              '${seat.seatRow}${seat.seatNumber}',
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final String label;
  final Color fill;
  final Color border;
  final Color text;

  const _LegendPill({
    required this.label,
    required this.fill,
    required this.border,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border, width: 1.2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
