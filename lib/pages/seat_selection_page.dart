import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class SeatSelectionPage extends StatefulWidget {
  const SeatSelectionPage({super.key});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final Set<String> _selectedSeats = {};

  static const int _rows = 8;
  static const int _cols = 10;
  static const Set<String> _bookedSeats = {'A1', 'A2', 'C5', 'D3', 'E7'};
  static const Set<String> _vipSeats = {'D1', 'D2', 'D3', 'D8', 'D9', 'D10'};

  Color _seatColor(String seat) {
    if (_bookedSeats.contains(seat)) return AppColors.seatBooked;
    if (_selectedSeats.contains(seat)) return AppColors.seatSelected;
    if (_vipSeats.contains(seat)) return AppColors.seatVip;
    return AppColors.seatAvailable;
  }

  void _toggleSeat(String seat) {
    if (_bookedSeats.contains(seat)) return;
    setState(() {
      _selectedSeats.contains(seat) ? _selectedSeats.remove(seat) : _selectedSeats.add(seat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Seats')),
      body: Column(
        children: [
          // Screen indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.transparent, AppColors.primary, Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('SCREEN', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 4)),
          const SizedBox(height: 24),

          // Seat Grid
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(_rows, (row) {
                      final rowLabel = String.fromCharCode(65 + row);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(rowLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                            ...List.generate(_cols, (col) {
                              final seat = '$rowLabel${col + 1}';
                              return GestureDetector(
                                onTap: () => _toggleSeat(seat),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _seatColor(seat),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // Legend & Summary
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _LegendItem(color: AppColors.seatAvailable, label: 'Available'),
                    _LegendItem(color: AppColors.seatSelected, label: 'Selected'),
                    _LegendItem(color: AppColors.seatVip, label: 'VIP'),
                    _LegendItem(color: AppColors.seatBooked, label: 'Booked'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedSeats.isNotEmpty)
                  Text(
                    'Selected: ${_selectedSeats.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _selectedSeats.isEmpty ? null : () {},
                  child: Text('Confirm ${_selectedSeats.length} Seat(s)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
