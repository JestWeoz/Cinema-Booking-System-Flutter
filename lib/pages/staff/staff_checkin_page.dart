import 'dart:convert';

import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/responses/checkin_response.dart';
import 'package:cinema_booking_system_app/services/auth_service.dart';
import 'package:cinema_booking_system_app/services/ticket_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StaffCheckInPage extends StatefulWidget {
  const StaffCheckInPage({super.key});

  @override
  State<StaffCheckInPage> createState() => _StaffCheckInPageState();
}

class _StaffCheckInPageState extends State<StaffCheckInPage> {
  final TextEditingController _bookingCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isLoading = false;
  bool _canScan = true;
  String? _error;
  CheckInResponse? _result;

  @override
  void dispose() {
    _bookingCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  String _extractBookingCode(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    if (value.startsWith('{') && value.endsWith('}')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          final bookingCode = (decoded['bookingCode'] ?? '').toString().trim();
          if (bookingCode.isNotEmpty) return bookingCode;
        }
      } catch (_) {}
    }

    final uri = Uri.tryParse(value);
    if (uri != null) {
      final byQuery = (uri.queryParameters['bookingCode'] ?? '').trim();
      if (byQuery.isNotEmpty) return byQuery;
    }

    return value;
  }

  Future<void> _handleBookingCode(String value) async {
    final bookingCode = _extractBookingCode(value);
    if (bookingCode.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await TicketService.instance.checkInByBookingCode(bookingCode);
      if (!mounted) return;

      if (result.tickets.isEmpty) {
        setState(() {
          _result = result;
          _error = 'Không có vé hợp lệ để check-in hoặc mã không hợp lệ.';
        });
        return;
      }

      setState(() {
        _result = result;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in thành công ${result.tickets.length} vé.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Check-in thất bại: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_canScan || _isLoading) return;

    String? first;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        first = value;
        break;
      }
    }

    if (first == null) return;

    _canScan = false;
    _bookingCodeController.text = _extractBookingCode(first);
    _handleBookingCode(first).whenComplete(() {
      Future<void>.delayed(const Duration(seconds: 2), () {
        _canScan = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final data = _result;
    final tickets = data?.tickets ?? const <CheckInTicketInfo>[];
    final products = data?.products ?? const <CheckInProductInfo>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Check-in'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Quét QR hoặc nhập booking code để check-in vé',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 240,
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bookingCodeController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Booking code',
                      hintText: 'Ví dụ: BK20260408ABC',
                    ),
                    onSubmitted: _handleBookingCode,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _handleBookingCode(_bookingCodeController.text),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner),
                  label: const Text('Check-in'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            if (data != null)
              Text(
                'Booking: ${data.bookingCode}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            if (data != null) ...[
              const SizedBox(height: 4),
              Text('Phim: ${data.movieTitle}'),
              Text('Phòng: ${data.roomName}'),
              Text(
                'Suất chiếu: ${data.showtimeAt == null ? '-' : formatter.format(DateTime.tryParse(data.showtimeAt!)?.toLocal() ?? DateTime.now())}',
              ),
            ],
            const SizedBox(height: 8),
            if (tickets.isEmpty)
              const Text('Chưa có dữ liệu check-in.'),
            if (tickets.isNotEmpty) ...[
              Text(
                'Danh sách vé (${tickets.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...tickets.map(
                (ticket) {
                  final parsedAt = ticket.checkedInAt == null
                      ? null
                      : DateTime.tryParse(ticket.checkedInAt!);
                  final checkInAt = parsedAt == null
                      ? '-'
                      : formatter.format(parsedAt.toLocal());
                  return Card(
                    child: ListTile(
                      title: Text('Vé ${ticket.ticketCode}'),
                      subtitle: Text(
                        'Ghế ${ticket.seatRow}${ticket.seatNumber} (${ticket.seatType?.name ?? '-'})\n'
                        'Trạng thái: ${ticket.status?.name ?? '-'}\n'
                        'Check-in lúc: $checkInAt',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Phiếu sản phẩm (${products.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (products.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Không có phiếu sản phẩm trong dữ liệu check-in'),
                    subtitle: Text('Nếu backend chưa trả products trong endpoint /tickets/check-in thì danh sách này sẽ trống.'),
                  ),
                )
              else
                ...products.map(
                  (product) => Card(
                    child: ListTile(
                      title: Text(product.itemName),
                      subtitle: Text(
                        'Loại: ${product.itemType} | Số lượng: ${product.quantity}',
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
