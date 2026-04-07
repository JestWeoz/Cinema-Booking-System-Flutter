import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/services/room_seat_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/seat_form_dialogs.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/seat_views.dart';

class AdminSeatListPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String cinemaName;

  const AdminSeatListPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.cinemaName,
  });

  @override
  State<AdminSeatListPage> createState() => _AdminSeatListPageState();
}

class _AdminSeatListPageState extends State<AdminSeatListPage> {
  final SeatService _seatService = SeatService.instance;
  final SeatTypeService _seatTypeService = SeatTypeService.instance;
  List<SeatResponse> _seats = const [];
  List<SeatTypeResponse> _seatTypes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _seatService.getByRoom(widget.roomId),
        _seatTypeService.getAll(),
      ]);
      if (!mounted) return;
      final seats = results[0] as List<SeatResponse>;
      seats.sort(_sortSeat);
      setState(() {
        _seats = seats;
        _seatTypes = results[1] as List<SeatTypeResponse>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách ghế: $error';
        _loading = false;
      });
    }
  }

  int _sortSeat(SeatResponse a, SeatResponse b) {
    final byRow = a.seatRow.compareTo(b.seatRow);
    return byRow != 0 ? byRow : a.seatNumber.compareTo(b.seatNumber);
  }

  Map<String, List<SeatResponse>> get _groupedSeats {
    final grouped = <String, List<SeatResponse>>{};
    for (final seat in _seats) {
      grouped.putIfAbsent(seat.seatRow, () => <SeatResponse>[]).add(seat);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      for (final entry in entries) entry.key: entry.value..sort(_sortSeat)
    };
  }

  Future<void> _createSeat() async {
    if (_seatTypes.isEmpty) {
      _showSnackBar('Không có loại ghế để sử dụng', isError: true);
      return;
    }
    final payload = await showSeatFormDialog(context, seatTypes: _seatTypes);
    if (payload == null) return;
    await _submitSeat(payload);
  }

  Future<void> _editSeat(SeatResponse seat) async {
    final payload = await showSeatFormDialog(
      context,
      seatTypes: _seatTypes,
      initial: seat,
    );
    if (payload == null) return;
    await _submitSeat(payload, seatId: seat.id);
  }

  Future<void> _submitSeat(SeatFormPayload payload, {String? seatId}) async {
    try {
      final body = {
        'seatRow': payload.seatRow,
        'seatNumber': payload.seatNumber,
        'seatTypeId': payload.seatTypeId,
        'active': payload.active,
        'isActive': payload.active,
      };
      if (seatId == null) {
        await _seatService.create({...body, 'roomId': widget.roomId});
      } else {
        await _seatService.update(seatId, body);
      }
      if (!mounted) return;
      _showSnackBar(seatId == null ? 'Đã tạo ghế mới' : 'Đã cập nhật ghế');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể lưu ghế: $error', isError: true);
    }
  }

  Future<void> _createBulkSeats() async {
    if (_seatTypes.isEmpty) {
      _showSnackBar('Không có loại ghế để sử dụng', isError: true);
      return;
    }
    final payload = await showSeatBulkDialog(context, seatTypes: _seatTypes);
    if (payload == null) return;
    try {
      await _seatService.bulkCreate(widget.roomId, {
        'seatGroups': [
          {
            'rows': payload.rows,
            'numbers': payload.numbers,
            'seatTypeId': payload.seatTypeId,
          },
        ],
      });
      if (!mounted) return;
      _showSnackBar('Đã tạo ghế hàng loạt');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể tạo ghế hàng loạt: $error', isError: true);
    }
  }

  Future<void> _deleteSeat(SeatResponse seat) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xoá ghế',
      message: 'Xoá ghế ${seat.seatRow}${seat.seatNumber} khỏi phòng này?',
      confirmLabel: 'Xoá ghế',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _seatService.delete(seat.id);
      if (!mounted) return;
      _showSnackBar('Đã xoá ghế');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể xoá ghế: $error', isError: true);
    }
  }

  Future<void> _toggleSeat(SeatResponse seat) async {
    await _submitSeat(
      SeatFormPayload(
        seatRow: seat.seatRow,
        seatNumber: seat.seatNumber,
        seatTypeId: seat.seatTypeId,
        active: !seat.active,
      ),
      seatId: seat.id,
    );
  }

  void _showSeatActions(SeatResponse seat) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white70),
              title: Text('Chỉnh sửa ghế ${seat.seatRow}${seat.seatNumber}',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                _editSeat(seat);
              },
            ),
            ListTile(
              leading: Icon(
                seat.active
                    ? Icons.toggle_off_outlined
                    : Icons.toggle_on_outlined,
                color: seat.active ? Colors.orangeAccent : AppColors.success,
              ),
              title: Text(seat.active ? 'Tắt ghế' : 'Bật ghế',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                _toggleSeat(seat);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title:
                  const Text('Xoá ghế', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                _deleteSeat(seat);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Ghế • ${widget.roomName}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<_SeatAction>(
            icon: const Icon(Icons.add, color: AppColors.primary),
            color: AppColors.cardDark,
            onSelected: (value) {
              if (value == _SeatAction.single) {
                _createSeat();
              } else {
                _createBulkSeats();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: _SeatAction.single, child: Text('Tạo ghế lẻ')),
              PopupMenuItem(
                  value: _SeatAction.bulk, child: Text('Tạo nhiều ghế')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSeat,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.event_seat_outlined, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? SeatErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      SeatHeader(
                        cinemaName: widget.cinemaName,
                        roomName: widget.roomName,
                        seatCount: _seats.length,
                        seatTypes: _seatTypes,
                      ),
                      const SizedBox(height: 12),
                      if (_seats.isEmpty)
                        const SeatEmptyView()
                      else
                        SeatMapBoard(
                          groupedSeats: _groupedSeats,
                          seatTypes: _seatTypes,
                          onTapSeat: _showSeatActions,
                        ),
                    ],
                  ),
                ),
    );
  }
}

enum _SeatAction { single, bulk }
