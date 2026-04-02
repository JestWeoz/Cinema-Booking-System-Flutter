import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';

class AdminCinemaListPage extends StatefulWidget {
  const AdminCinemaListPage({super.key});
  @override
  State<AdminCinemaListPage> createState() => _AdminCinemaListPageState();
}

class _AdminCinemaListPageState extends State<AdminCinemaListPage> {
  final _service = AdminService.instance;
  List<CinemaResponse> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.getCinemas(size: 50);
      setState(() => _items = r.content);
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Thêm Rạp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _f(nameCtrl, 'Tên rạp *'),
          const SizedBox(height: 8),
          _f(addrCtrl, 'Địa chỉ *'),
          const SizedBox(height: 8),
          _f(phoneCtrl, 'SĐT', keyboard: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.createCinema({'name': nameCtrl.text, 'address': addrCtrl.text, 'phone': phoneCtrl.text});
                _load();
              } catch (e) { _snack('Lỗi: $e'); }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String hint, {TextInputType keyboard = TextInputType.text}) =>
      TextField(controller: c, keyboardType: keyboard, style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true, fillColor: AppColors.surfaceDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Rạp Chiếu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: _showAddDialog)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? const Center(child: Text('Không có rạp', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
                      child: ListTile(
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: const Color(0xFF9C27B0).withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.theater_comedy, color: Color(0xFF9C27B0), size: 24),
                        ),
                        title: Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.address, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          if (c.phone != null) Text(c.phone!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.status?.name == 'ACTIVE' ? AppColors.success.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c.status?.name ?? 'N/A',
                                style: TextStyle(color: c.status?.name == 'ACTIVE' ? AppColors.success : Colors.grey, fontSize: 10)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.meeting_room_outlined, color: Colors.white54),
                            onPressed: () => context.push('${AppRoutes.adminRooms}?cinemaId=${c.id}&cinemaName=${c.name}'),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
