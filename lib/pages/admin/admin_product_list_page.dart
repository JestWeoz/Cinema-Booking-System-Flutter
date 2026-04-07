import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/combo_service.dart';
import 'package:cinema_booking_system_app/services/product_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:cinema_booking_system_app/shared/widgets/image_picker_button.dart';

enum _InventoryType { product, combo }

class AdminProductListPage extends StatefulWidget {
  const AdminProductListPage({super.key});

  @override
  State<AdminProductListPage> createState() => _AdminProductListPageState();
}

class _AdminProductListPageState extends State<AdminProductListPage> {
  final ProductService _productService = ProductService.instance;
  final ComboService _comboService = ComboService.instance;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  List<ProductResponse> _products = const [];
  List<ComboResponse> _combos = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 0;
  int _total = 0;
  String _search = '';
  Timer? _debounce;
  _InventoryType _type = _InventoryType.product;

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
      if (_type == _InventoryType.product) {
        final result = await _productService.getAll(
          page: _page - 1,
          size: 10,
          keyword: _search.isEmpty ? null : _search,
        );
        if (!mounted) return;
        setState(() {
          _products = result.content;
          _combos = const [];
          _total = result.totalElements;
          _totalPages = result.totalPages;
          _loading = false;
        });
      } else {
        final result = await _comboService.getAll(
          page: _page,
          size: 10,
          keyword: _search.isEmpty ? null : _search,
        );
        if (!mounted) return;
        setState(() {
          _combos = result.content;
          _products = const [];
          _total = result.totalElements;
          _totalPages = result.totalPages;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được dữ liệu: $e';
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

  Future<void> _toggleProduct(ProductResponse item) async {
    await _productService.toggleActive(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.active == true ? 'Đã tắt sản phẩm' : 'Đã kích hoạt sản phẩm'),
        backgroundColor: AppColors.success,
      ),
    );
    _load();
  }

  Future<void> _toggleCombo(ComboResponse item) async {
    await _comboService.toggleActive(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.active ? 'Đã tắt combo' : 'Đã kích hoạt combo'),
        backgroundColor: AppColors.success,
      ),
    );
    _load();
  }

  Future<void> _deleteProduct(ProductResponse item) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá sản phẩm',
      message: 'Xoá "${item.name}" sẽ không thể hoàn tác.',
      confirmLabel: 'Xoá sản phẩm',
      destructive: true,
    );
    if (!ok) return;
    await _productService.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá sản phẩm'), backgroundColor: AppColors.success),
    );
    _load();
  }

  Future<void> _deleteCombo(ComboResponse item) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xoá combo',
      message: 'Xoá "${item.name}" sẽ không thể hoàn tác.',
      confirmLabel: 'Xoá combo',
      destructive: true,
    );
    if (!ok) return;
    await _comboService.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá combo'), backgroundColor: AppColors.success),
    );
    _load();
  }

  Future<void> _openProductForm({ProductResponse? product}) async {
    final changed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _ProductFormDialog(service: _productService, product: product),
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

  Future<void> _openComboForm({ComboResponse? combo}) async {
    final changed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _ComboFormDialog(
        comboService: _comboService,
        productService: _productService,
        combo: combo,
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(combo == null ? 'Đã tạo combo' : 'Đã cập nhật combo'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    }
  }

  void _changeType(_InventoryType value) {
    if (_type == value) return;
    setState(() {
      _type = value;
      _page = 1;
      _search = '';
      _searchController.clear();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isProduct = _type == _InventoryType.product;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Sản phẩm & Combo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: isProduct ? _openProductForm : _openComboForm,
            icon: const Icon(Icons.add, color: AppColors.primary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isProduct ? _openProductForm : _openComboForm,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _typeChip(
                    label: 'Sản phẩm',
                    selected: isProduct,
                    onTap: () => _changeType(_InventoryType.product),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _typeChip(
                    label: 'Combo',
                    selected: !isProduct,
                    onTap: () => _changeType(_InventoryType.combo),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _onSearchChanged(value);
                setState(() {});
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isProduct ? 'Tìm sản phẩm...' : 'Tìm combo...',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$_total ${isProduct ? 'sản phẩm' : 'combo'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white70))))
                    : isProduct
                        ? _buildProductList()
                        : _buildComboList(),
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

  Widget _buildProductList() {
    if (_products.isEmpty) {
      return const Center(child: Text('Chưa có sản phẩm nào', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final item = _products[i];
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
                    : _placeholder(Icons.fastfood_outlined),
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
              Switch(value: active, onChanged: (_) => _toggleProduct(item), activeThumbColor: AppColors.success),
              PopupMenuButton<String>(
                color: AppColors.surfaceDark,
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: Colors.redAccent))),
                ],
                onSelected: (value) {
                  if (value == 'edit') _openProductForm(product: item);
                  if (value == 'delete') _deleteProduct(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComboList() {
    if (_combos.isEmpty) {
      return const Center(child: Text('Chưa có combo nào', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _combos.length,
      itemBuilder: (_, i) {
        final item = _combos[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fallbackIcon: Icons.local_movies_outlined,
                        backgroundColor: AppColors.surfaceDark,
                      )
                    : _placeholder(Icons.local_movies_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(_money.format(item.price), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.description!, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text('${item.items.length} sản phẩm trong combo', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Switch(value: item.active, onChanged: (_) => _toggleCombo(item), activeThumbColor: AppColors.success),
              PopupMenuButton<String>(
                color: AppColors.surfaceDark,
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: Colors.redAccent))),
                ],
                onSelected: (value) {
                  if (value == 'edit') _openComboForm(combo: item);
                  if (value == 'delete') _deleteCombo(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _placeholder(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.surfaceDark,
      child: Icon(icon, color: Colors.white38),
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
      setState(() => _error = 'Vui lòng tải ảnh sản phẩm lên');
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

class _ComboDraftItem {
  String? productId;
  int quantity;

  _ComboDraftItem({this.productId, this.quantity = 1});
}

class _ComboFormDialog extends StatefulWidget {
  final ComboService comboService;
  final ProductService productService;
  final ComboResponse? combo;

  const _ComboFormDialog({
    required this.comboService,
    required this.productService,
    this.combo,
  });

  @override
  State<_ComboFormDialog> createState() => _ComboFormDialogState();
}

class _ComboFormDialogState extends State<_ComboFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  String? _imageUrl;
  bool _saving = false;
  String? _error;
  bool _active = true;
  bool _loadingProducts = true;

  List<ProductResponse> _products = const [];
  final List<_ComboDraftItem> _items = [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.combo?.name ?? '');
    _price = TextEditingController(text: widget.combo == null ? '' : widget.combo!.price.toString());
    _description = TextEditingController(text: widget.combo?.description ?? '');
    _imageUrl = widget.combo?.image;
    _active = widget.combo?.active ?? true;
    if (widget.combo != null && widget.combo!.items.isNotEmpty) {
      for (final item in widget.combo!.items) {
        _items.add(_ComboDraftItem(productId: item.productId, quantity: item.quantity));
      }
    } else {
      _items.add(_ComboDraftItem());
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final result = await widget.productService.getAll(page: 0, size: 100);
      if (!mounted) return;
      setState(() {
        _products = result.content;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _error = 'Không tải được sản phẩm để ghép combo: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      setState(() => _error = 'Vui lòng tải ảnh combo lên');
      return;
    }

    final validItems = _items
        .where((e) => e.productId != null && e.productId!.isNotEmpty && e.quantity > 0)
        .toList();
    if (validItems.isEmpty) {
      setState(() => _error = 'Vui lòng chọn ít nhất 1 sản phẩm cho combo');
      return;
    }

    final unique = <String>{};
    for (final item in validItems) {
      if (!unique.add(item.productId!)) {
        setState(() => _error = 'Không được chọn trùng sản phẩm trong combo');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'price': double.parse(_price.text.trim()),
      'image': _imageUrl,
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'active': _active,
      'items': validItems
          .map((e) => {
                'productId': e.productId,
                'quantity': e.quantity,
              })
          .toList(),
    };

    try {
      if (widget.combo == null) {
        await widget.comboService.create(payload);
      } else {
        await widget.comboService.update(widget.combo!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không lưu được combo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 620 ? 560.0 : (screenWidth - 32).clamp(280.0, 560.0);
    final isCompact = dialogWidth < 430;
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text(
        widget.combo == null ? 'Thêm combo' : 'Chỉnh sửa combo',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tên combo' : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tên combo'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Giá phải lớn hơn 0' : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Giá combo', suffixText: 'VND'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                      title: const Text('Đang hoạt động', style: TextStyle(color: Colors.white)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sản phẩm trong combo',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _items.add(_ComboDraftItem())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm dòng'),
                        ),
                      ],
                    ),
                    if (_loadingProducts)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    else
                      ...List.generate(_items.length, (index) {
                        final row = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: isCompact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      initialValue: row.productId,
                                      isExpanded: true,
                                      dropdownColor: AppColors.surfaceDark,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(labelText: 'Sản phẩm'),
                                      items: _products
                                          .map(
                                            (p) => DropdownMenuItem<String>(
                                              value: p.id,
                                              child: Text(p.name, overflow: TextOverflow.ellipsis),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => row.productId = value,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: TextFormField(
                                            initialValue: row.quantity.toString(),
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: const InputDecoration(labelText: 'Số lượng'),
                                            onChanged: (value) => row.quantity = int.tryParse(value) ?? 0,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: _items.length <= 1 ? null : () => setState(() => _items.removeAt(index)),
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: row.productId,
                                        isExpanded: true,
                                        dropdownColor: AppColors.surfaceDark,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(labelText: 'Sản phẩm'),
                                        items: _products
                                            .map(
                                              (p) => DropdownMenuItem<String>(
                                                value: p.id,
                                                child: Text(p.name, overflow: TextOverflow.ellipsis),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) => row.productId = value,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue: row.quantity.toString(),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: const InputDecoration(labelText: 'SL'),
                                        onChanged: (value) => row.quantity = int.tryParse(value) ?? 0,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _items.length <= 1 ? null : () => setState(() => _items.removeAt(index)),
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                        );
                      }),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.combo == null ? 'Tạo combo' : 'Lưu thay đổi'),
        ),
      ],
    );
  }
}
