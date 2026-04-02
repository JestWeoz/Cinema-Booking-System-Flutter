import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';

class AdminVoucherListPage extends StatefulWidget {
  const AdminVoucherListPage({super.key});
  @override
  State<AdminVoucherListPage> createState() => _AdminVoucherListPageState();
}

class _AdminVoucherListPageState extends State<AdminVoucherListPage> {
  final _service = AdminService.instance;
  List<PromotionResponse> _items = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.getPromotions(page: _page, size: 10);
      setState(() { _items = r.content; _total = r.totalElements; });
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Xoá voucher?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) { await _service.deletePromotion(id); _load(); }
  }

  void _showAddDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String type = 'PERCENT';

    showDialog(context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Thêm Voucher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _f(codeCtrl, 'Mã voucher *'),
          const SizedBox(height: 8),
          _f(nameCtrl, 'Tên *'),
          const SizedBox(height: 8),
          _f(valueCtrl, 'Giá trị *', keyboard: TextInputType.number),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: type,
            dropdownColor: AppColors.surfaceDark,
            decoration: _deco('Loại giảm giá'),
            style: const TextStyle(color: Colors.white),
            items: ['PERCENT', 'FIXED'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setS(() => type = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.createPromotion({
                  'code': codeCtrl.text,
                  'name': nameCtrl.text,
                  'discountType': type,
                  'discountValue': double.tryParse(valueCtrl.text) ?? 0,
                  'active': true,
                });
                _load();
              } catch (e) { _snack('Lỗi: $e'); }
            },
            child: const Text('Tạo'),
          ),
        ],
      )),
    );
  }

  Widget _f(TextEditingController c, String hint, {TextInputType keyboard = TextInputType.text}) =>
      TextField(controller: c, keyboardType: keyboard, style: const TextStyle(color: Colors.white),
          decoration: _deco(hint));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    filled: true, fillColor: AppColors.surfaceDark,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Voucher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: _showAddDialog)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('$_total voucher', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _items.isEmpty
                    ? const Center(child: Text('Không có voucher', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final v = _items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.local_offer, color: AppColors.secondary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(6)),
                                    child: Text(v.code, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: v.active ? AppColors.success.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(v.active ? 'Đang hoạt động' : 'Dừng',
                                        style: TextStyle(color: v.active ? AppColors.success : Colors.grey, fontSize: 10)),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Text(v.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('${v.discountValue}${v.discountType?.name == 'PERCENT' ? '%' : '₫'} giảm',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ])),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _delete(v.id),
                              ),
                            ]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
