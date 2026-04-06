import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/promotion_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';

class AdminVoucherListPage extends StatefulWidget {
  const AdminVoucherListPage({super.key});

  @override
  State<AdminVoucherListPage> createState() => _AdminVoucherListPageState();
}

class _AdminVoucherListPageState extends State<AdminVoucherListPage> {
  final PromotionService _service = PromotionService.instance;
  final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  List<PromotionResponse> _items = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 0;
  int _total = 0;

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
      final result = await _service.getAll(page: _page, size: 10);
      if (!mounted) return;
      setState(() {
        _items = result.content;
        _total = result.totalElements;
        _totalPages = result.totalPages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được voucher: $e';
      });
    }
  }

  Future<void> _delete(PromotionResponse item) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá voucher',
      message: 'Xoá voucher "${item.code}" sẽ không thể hoàn tác.',
      confirmLabel: 'Xoá voucher',
      destructive: true,
    );
    if (!ok) return;
    await _service.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá voucher'), backgroundColor: AppColors.success),
    );
    _load();
  }

  Future<void> _toggleActive(PromotionResponse item) async {
    await _service.update(item.id, {'active': !item.active});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.active ? 'Đã tắt voucher' : 'Đã kích hoạt voucher'),
        backgroundColor: AppColors.success,
      ),
    );
    _load();
  }

  Future<void> _openForm({PromotionResponse? promotion}) async {
    final changed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _PromotionFormDialog(service: _service, promotion: promotion),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(promotion == null ? 'Đã tạo voucher' : 'Đã cập nhật voucher'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Voucher', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _openForm, icon: const Icon(Icons.add, color: AppColors.primary)),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$_total voucher', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white70))))
                    : _items.isEmpty
                        ? const Center(child: Text('Chưa có voucher nào', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            itemBuilder: (_, i) {
                              final v = _items[i];
                              final valueText = v.discountType == DiscountType.PERCENTAGE
                                  ? '${v.discountValue.toInt()}%'
                                  : _money.format(v.discountValue);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(v.code, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          value: v.active,
                                          onChanged: (_) => _toggleActive(v),
                                          activeThumbColor: AppColors.success,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(v.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                    if (v.description != null && v.description!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(v.description!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _pill('Giảm $valueText', AppColors.secondary),
                                        if (v.minOrderValue != null) _pill('Tối thiểu ${_money.format(v.minOrderValue)}', Colors.white70),
                                        if (v.quantity != null) _pill('SL ${v.usedQuantity ?? 0}/${v.quantity}', AppColors.info),
                                        if (v.startDate != null || v.endDate != null)
                                          _pill('${_date(v.startDate)} - ${_date(v.endDate)}', Colors.white70),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _openForm(promotion: v),
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          label: const Text('Chỉnh sửa'),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () => _delete(v),
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          AppPagination(
            page: _page,
            totalPages: _totalPages,
            onPageChanged: (value) {
              setState(() => _page = value);
              _load();
            },
          ),
        ],
      ),
    );
  }

  static Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  static String _date(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final value = DateTime.tryParse(raw);
    return value == null ? raw : DateFormat('dd/MM/yyyy').format(value);
  }
}

class _PromotionFormDialog extends StatefulWidget {
  final PromotionService service;
  final PromotionResponse? promotion;

  const _PromotionFormDialog({
    required this.service,
    this.promotion,
  });

  @override
  State<_PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<_PromotionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _discountValue;
  late final TextEditingController _minOrderValue;
  late final TextEditingController _maxDiscount;
  late final TextEditingController _quantity;
  late final TextEditingController _maxUsagePerUser;
  final TextEditingController _previewOrderTotal = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _previewText;
  bool _previewing = false;
  DiscountType _discountType = DiscountType.PERCENTAGE;
  bool _active = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final item = widget.promotion;
    _code = TextEditingController(text: item?.code ?? '');
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _discountValue = TextEditingController(text: item == null ? '' : item.discountValue.toString());
    _minOrderValue = TextEditingController(text: item?.minOrderValue?.toString() ?? '');
    _maxDiscount = TextEditingController(text: item?.maxDiscount?.toString() ?? '');
    _quantity = TextEditingController(text: item?.quantity?.toString() ?? '');
    _maxUsagePerUser = TextEditingController(text: item?.maxUsagePerUser?.toString() ?? '');
    _discountType = item?.discountType ?? DiscountType.PERCENTAGE;
    _active = item?.active ?? true;
    _startDate = item?.startDate == null ? null : DateTime.tryParse(item!.startDate!);
    _endDate = item?.endDate == null ? null : DateTime.tryParse(item!.endDate!);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _discountValue.dispose();
    _minOrderValue.dispose();
    _maxDiscount.dispose();
    _quantity.dispose();
    _maxUsagePerUser.dispose();
    _previewOrderTotal.dispose();
    super.dispose();
  }

  double? _toDouble(TextEditingController c) => c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());
  int? _toInt(TextEditingController c) => c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _preview() async {
    final orderTotal = double.tryParse(_previewOrderTotal.text.trim());
    if (orderTotal == null || orderTotal <= 0) {
      setState(() => _previewText = 'Nhập số tiền đơn hàng hợp lệ');
      return;
    }
    setState(() {
      _previewing = true;
      _previewText = null;
    });
    try {
      final result = await widget.service.preview(code: _code.text.trim(), orderTotal: orderTotal);
      final discount = result['discount'] ?? result['discountAmount'] ?? 0;
      final finalTotal = result['finalTotal'] ?? result['payableAmount'] ?? 0;
      setState(() {
        _previewing = false;
        _previewText = 'Giảm ${discount.toString()} • Còn lại ${finalTotal.toString()}';
      });
    } catch (e) {
      setState(() {
        _previewing = false;
        _previewText = 'Không preview được: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'code': _code.text.trim(),
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'discountType': _discountType.name,
      'discountValue': double.parse(_discountValue.text.trim()),
      'minOrderValue': _toDouble(_minOrderValue),
      'maxDiscount': _toDouble(_maxDiscount),
      'quantity': _toInt(_quantity),
      'maxUsagePerUser': _toInt(_maxUsagePerUser),
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'active': _active,
    };
    try {
      if (widget.promotion == null) {
        await widget.service.create(payload);
      } else {
        await widget.service.update(widget.promotion!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không lưu được voucher: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        widget.promotion == null ? 'Thêm voucher' : 'Chỉnh sửa voucher',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _field(_code, 'Mã voucher', validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_name, 'Tên voucher', validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null)),
                ]),
                const SizedBox(height: 12),
                _field(_description, 'Mô tả', maxLines: 2),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<DiscountType>(
                      initialValue: _discountType,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                      items: DiscountType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _discountType = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_discountValue, 'Giá trị giảm', keyboard: TextInputType.number, validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Phải > 0' : null)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_minOrderValue, 'Đơn tối thiểu', keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_maxDiscount, 'Giảm tối đa', keyboard: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_quantity, 'Số lượng', keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_maxUsagePerUser, 'Giới hạn / user', keyboard: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dateField('Ngày bắt đầu', _startDate, () => _pickDate(start: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField('Ngày kết thúc', _endDate, () => _pickDate(start: false))),
                ]),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Đang hoạt động', style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(color: AppColors.dividerDark),
                Row(children: [
                  Expanded(child: _field(_previewOrderTotal, 'Preview đơn hàng', keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _previewing ? null : _preview,
                      child: _previewing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Preview'),
                    ),
                  ),
                ]),
                if (_previewText != null) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text(_previewText!, style: const TextStyle(color: Colors.white70))),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context, rootNavigator: true).pop(false), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.promotion == null ? 'Tạo voucher' : 'Lưu thay đổi'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.date_range_outlined)),
        child: Text(
          value == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(value),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
