import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/requests/showtime_requests.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';

class AdminShowtimeListPage extends StatefulWidget {
  const AdminShowtimeListPage({super.key});
  @override
  State<AdminShowtimeListPage> createState() => _AdminShowtimeListPageState();
}

class _AdminShowtimeListPageState extends State<AdminShowtimeListPage> {
  final _service = AdminService.instance;
  List<ShowtimeSummaryResponse> _items = [];
  List<CinemaResponse> _cinemas = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  String? _cinemaId;

  @override
  void initState() {
    super.initState();
    _loadCinemas();
    _load();
  }

  Future<void> _loadCinemas() async {
    try {
      final r = await _service.getCinemas(size: 50);
      setState(() => _cinemas = r.content);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.getShowtimes(page: _page, size: 20, cinemaId: _cinemaId);
      setState(() { _items = r.content; _total = r.totalElements; });
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  Future<void> _cancel(String id) async {
    await _service.cancelShowtime(id);
    _load();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Xoá suất chiếu?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) { await _service.deleteShowtime(id); _load(); }
  }

  void _showAddDialog() {
    final movieCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final langCtrl = TextEditingController(text: 'VIETNAMESE');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Thêm Suất Chiếu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(movieCtrl, 'Movie ID *'),
            const SizedBox(height: 8),
            _field(roomCtrl, 'Room ID *'),
            const SizedBox(height: 8),
            _field(timeCtrl, 'Thời gian (2025-08-15T14:30:00)'),
            const SizedBox(height: 8),
            _field(priceCtrl, 'Giá vé (VND)', keyboard: TextInputType.number),
            const SizedBox(height: 8),
            _field(langCtrl, 'Ngôn ngữ'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.createShowtime(CreateShowtimeRequest(
                  movieId: movieCtrl.text,
                  roomId: roomCtrl.text,
                  startTime: timeCtrl.text,
                  basePrice: double.tryParse(priceCtrl.text) ?? 0,
                  language: langCtrl.text,
                ));
                _load();
              } catch (e) { _snack('Lỗi: $e'); }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {TextInputType keyboard = TextInputType.text}) =>
      TextField(controller: c, keyboardType: keyboard, style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true, fillColor: AppColors.surfaceDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Suất Chiếu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: _showAddDialog)],
      ),
      body: Column(
        children: [
          if (_cinemas.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _chip('Tất cả', null),
                  ..._cinemas.map((c) => _chip(c.name, c.id)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _items.isEmpty
                    ? const Center(child: Text('Không có suất chiếu', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _ShowtimeCard(item: _items[i], onCancel: () => _cancel(_items[i].id), onDelete: () => _delete(_items[i].id)),
                      ),
          ),
          _pagination(),
        ],
      ),
    );
  }

  Widget _chip(String label, String? id) => GestureDetector(
    onTap: () { setState(() { _cinemaId = id; _page = 1; }); _load(); },
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _cinemaId == id ? AppColors.primary : AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ),
  );

  Widget _pagination() {
    final total = (_total / 20).ceil();
    if (total <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null),
        Text('$_page / $total', style: const TextStyle(color: Colors.white)),
        IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: _page < total ? () { setState(() => _page++); _load(); } : null),
      ]),
    );
  }
}

class _ShowtimeCard extends StatelessWidget {
  final ShowtimeSummaryResponse item;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  const _ShowtimeCard({required this.item, required this.onCancel, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColors = {'UPCOMING': AppColors.secondary, 'ONGOING': AppColors.success, 'FINISHED': Colors.white38, 'CANCELLED': AppColors.error};
    final color = statusColors[item.status?.name] ?? Colors.white38;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.movieTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${item.cinemaName} · ${item.roomName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(item.startTime, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${item.basePrice.toStringAsFixed(0)} VND · ${item.availableSeats} ghế trống',
              style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(item.status?.name ?? '', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          PopupMenuButton<String>(
            color: AppColors.surfaceDark,
            icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cancel', child: Text('Huỷ suất', style: TextStyle(color: Colors.orange))),
              const PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) { if (v == 'cancel') onCancel(); else onDelete(); },
          ),
        ]),
      ]),
    );
  }
}
