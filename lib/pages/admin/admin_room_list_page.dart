import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';

class AdminRoomListPage extends StatefulWidget {
  final String cinemaId;
  final String cinemaName;
  const AdminRoomListPage({super.key, required this.cinemaId, required this.cinemaName});
  @override
  State<AdminRoomListPage> createState() => _AdminRoomListPageState();
}

class _AdminRoomListPageState extends State<AdminRoomListPage> {
  final _service = AdminService.instance;
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.getRoomsByCinema(widget.cinemaId, size: 50);
      setState(() => _rooms = r);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Phòng — ${widget.cinemaName}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _rooms.isEmpty
              ? const Center(child: Text('Không có phòng', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rooms.length,
                  itemBuilder: (_, i) {
                    final r = _rooms[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text('P', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['name']?.toString() ?? 'Phòng', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('${r['roomType'] ?? ''} · ${r['totalSeats'] ?? '?'} ghế',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ])),
                        Icon(r['status'] == 'ACTIVE' ? Icons.check_circle : Icons.cancel,
                            color: r['status'] == 'ACTIVE' ? AppColors.success : AppColors.error, size: 20),
                      ]),
                    );
                  },
                ),
    );
  }
}
