import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/product_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:cinema_booking_system_app/shared/widgets/image_picker_button.dart';

class AdminProductListPage extends StatefulWidget {
  const AdminProductListPage({super.key});

  @override
  State<AdminProductListPage> createState() => _AdminProductListPageState();
}

class _AdminProductListPageState extends State<AdminProductListPage> {
  final ProductService _service = ProductService.instance;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  List<ProductResponse> _items = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 0;
  int _total = 0;
  String _search = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getAll(
        page: _page - 1,
        size: 10,
        keyword: _search.isEmpty ? null : _search,
      );
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
        _error = 'Không tải được sản phẩm: $e';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
      });
      _load();
    });
  }

  Future<void> _toggle(ProductResponse item) async {
    await _service.toggleActive(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.active == true ? 'Đã tắt sản phẩm' : 'Đã kích hoạt sản phẩm'),
        backgroundColor: AppColors.success,
      ),
    );
    _load();
  }

  Future<void> _delete(ProductResponse item) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá sản phẩm',
      message: 'Xoá "${item.name}" sẽ không thể hoàn tác.',
      confirmLabel: 'Xoá sản phẩm',
      destructive: true,
    );
    if (!ok) return;
    await _service.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá sản phẩm'), backgroundColor: AppColors.success),
    );
    _load();
  }

  Future<void> _openForm({ProductResponse? product}) async {
    final changed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _ProductFormDialog(service: _service, product: product),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(product == null ? 'Đã tạo sản phẩm' : 'Đã cập nhật sản phẩm'),
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
        title: const Text('Sản phẩm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _onSearchChanged(value);
                setState(() {});
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$_total sản phẩm', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white70))))
                    : _items.isEmpty
                        ? const Center(child: Text('Chưa có sản phẩm nào', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            itemBuilder: (_, i) {
                              final item = _items[i];
                              final active = item.active == true;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item.image != null && item.image!.isNotEmpty
                                          ? AppNetworkImage(
                                              url: item.image!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              borderRadius: 12,
                                              fallbackIcon: Icons.fastfood_outlined,
                                              backgroundColor: AppColors.surfaceDark,
                                            )
                                          : _placeholder(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                          const SizedBox(height: 6),
                                          Text(_money.format(item.price), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Switch(value: active, onChanged: (_) => _toggle(item), activeThumbColor: AppColors.success),
                                    PopupMenuButton<String>(
                                      color: AppColors.surfaceDark,
                                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white))),
                                        PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: Colors.redAccent))),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') _openForm(product: item);
                                        if (value == 'delete') _delete(item);
                                      },
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

  static Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.surfaceDark,
      child: const Icon(Icons.fastfood_outlined, color: Colors.white38),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final ProductService service;
  final ProductResponse? product;

  const _ProductFormDialog({
    required this.service,
    this.product,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  String? _imageUrl;
  bool _saving = false;
  String? _error;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _price = TextEditingController(text: widget.product == null ? '' : widget.product!.price.toString());
    _imageUrl = widget.product?.image;
    _active = widget.product?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      setState(() => _error = 'Vui lòng upload ảnh sản phẩm');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'price': double.parse(_price.text.trim()),
      'image': _imageUrl,
      'active': _active,
    };
    try {
      if (widget.product == null) {
        await widget.service.create(payload);
      } else {
        await widget.service.update(widget.product!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không lưu được sản phẩm: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text(
        widget.product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: ImagePickerButton(
                    label: '',
                    currentImageUrl: _imageUrl,
                    size: 180,
                    shape: ImagePickerButtonShape.rectangle,
                    onUploaded: (url) => setState(() => _imageUrl = url),
                    onError: (e) => setState(() => _error = e),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Giá phải lớn hơn 0' : null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Giá bán', suffixText: 'VND'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Đang hoạt động', style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
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
              : Text(widget.product == null ? 'Tạo sản phẩm' : 'Lưu thay đổi'),
        ),
      ],
    );
  }
}
