import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/booking_model.dart';
import 'package:cinema_booking_system_app/services/booking_service.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await BookingService.instance.getMyBookings();
      if (mounted) setState(() { _bookings = bookings; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<BookingModel> get _upcoming => _bookings
      .where((b) => b.status != 'cancelled' && b.showtime.isAfter(DateTime.now()))
      .toList();

  List<BookingModel> get _past => _bookings
      .where((b) => b.status == 'cancelled' || b.showtime.isBefore(DateTime.now()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vé Của Tôi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Không thể tải vé', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadBookings, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [Tab(text: 'Sắp Chiếu'), Tab(text: 'Đã Xem')],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TicketList(bookings: _upcoming),
                            _TicketList(bookings: _past),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<BookingModel> bookings;
  const _TicketList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không có vé nào', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _TicketCard(booking: bookings[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final BookingModel booking;
  const _TicketCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed': return AppColors.success;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showQrCode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('QR Vào Rạp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(booking.movieTitle,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // QR Code placeholder
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // QR grid visual
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: 100,
                    itemBuilder: (_, i) => Container(
                      decoration: BoxDecoration(
                        color: [0, 1, 9, 10, 18, 19, 80, 81, 89, 90, 99, 98, 88, 79].contains(i) ||
                                (i % 7 == 0) ||
                                (i % 13 == 3)
                            ? Colors.black
                            : Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  // Center logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.movie, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              '${booking.cinemaName} • ${booking.seats.join(', ')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.showtime.day}/${booking.showtime.month}/${booking.showtime.year} '
              '${booking.showtime.hour.toString().padLeft(2, '0')}:${booking.showtime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Xuất trình mã QR này tại quầy để vào rạp',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQrCode(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.dividerDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.movieTitle,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('${booking.cinemaName} • ${booking.seats.length} ghế',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.showtime.day}/${booking.showtime.month}/${booking.showtime.year} '
                              '${booking.showtime.hour.toString().padLeft(2, '0')}:${booking.showtime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(booking.status,
                        style: TextStyle(color: _statusColor, fontSize: 11)),
                  ),
                ],
              ),
            ),

            // Divider dashed style
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: AppColors.backgroundDark,
                        shape: CircleBorder(),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.dividerDark)),
                  SizedBox(
                    width: 16, height: 16,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: AppColors.backgroundDark,
                        shape: CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // QR tap hint
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Nhấn để xem QR vào rạp',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
