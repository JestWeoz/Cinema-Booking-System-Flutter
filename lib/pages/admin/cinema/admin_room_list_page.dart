import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/services/room_seat_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/room_form_dialog.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/room_views.dart';

class AdminRoomListPage extends StatefulWidget {
  final String cinemaId;
  final String cinemaName;

  const AdminRoomListPage({
    super.key,
    required this.cinemaId,
    required this.cinemaName,
  });

  @override
  State<AdminRoomListPage> createState() => _AdminRoomListPageState();
}

class _AdminRoomListPageState extends State<AdminRoomListPage> {
  final RoomService _roomService = RoomService.instance;
  List<RoomResponse> _rooms = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _size = 10;
  int _totalPages = 0;
  int _totalElements = 0;

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
      final response = await _roomService.getByCinemaPaginated(
        widget.cinemaId,
        page: _page,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _rooms = response.content;
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách phòng: $error';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({RoomResponse? room}) async {
    final payload = await showRoomFormDialog(
      context,
      initial: room == null
          ? null
          : RoomFormPayload(
              name: room.name,
              totalSeats: room.totalSeats,
              roomType: room.roomType ?? RoomType.TWO_D,
            ),
    );
    if (payload == null) return;
    try {
      if (room == null) {
        await _roomService.create({
          'name': payload.name,
          'cinemaId': widget.cinemaId,
          'roomType': roomTypeToApi(payload.roomType),
          'totalSeats': payload.totalSeats,
        });
      } else {
        await _roomService.update(room.id, {
          'name': payload.name,
          'roomType': roomTypeToApi(payload.roomType),
          'totalSeats': payload.totalSeats,
        });
      }
      if (!mounted) return;
      _showSnackBar(room == null ? 'Đã tạo phòng chiếu' : 'Đã cập nhật phòng chiếu');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể lưu phòng: $error', isError: true);
    }
  }

  Future<void> _deleteRoom(RoomResponse room) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xoá phòng chiếu',
      message: 'Xoá "${room.name}" sẽ làm mất liên kết ghế và suất chiếu liên quan.',
      confirmLabel: 'Xoá phòng',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _roomService.delete(room.id);
      if (!mounted) return;
      _showSnackBar('Đã xoá phòng chiếu');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể xoá phòng: $error', isError: true);
    }
  }

  Future<void> _toggleRoom(RoomResponse room) async {
    try {
      await _roomService.toggleStatus(room.id);
      if (!mounted) return;
      _showSnackBar('Đã cập nhật trạng thái "${room.name}"');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể cập nhật trạng thái: $error', isError: true);
    }
  }

  void _openSeats(RoomResponse room) {
    context.push(
      '${AppRoutes.adminSeats}?roomId=${room.id}&roomName=${Uri.encodeComponent(room.name)}&cinemaName=${Uri.encodeComponent(widget.cinemaName)}',
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
          'Phòng • ${widget.cinemaName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _openForm,
            icon: const Icon(Icons.add, color: AppColors.primary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$_totalElements phòng', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? RoomErrorView(message: _error!, onRetry: _load)
                    : _rooms.isEmpty
                        ? const RoomEmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _rooms.length,
                            itemBuilder: (_, index) {
                              final room = _rooms[index];
                              return RoomCard(
                                room: room,
                                onEdit: () => _openForm(room: room),
                                onDelete: () => _deleteRoom(room),
                                onToggle: () => _toggleRoom(room),
                                onOpenSeats: () => _openSeats(room),
                              );
                            },
                          ),
          ),
          AppPagination(
            page: _page,
            totalPages: _totalPages,
            onPageChanged: (page) {
              setState(() => _page = page);
              _load();
            },
          ),
        ],
      ),
    );
  }
}
