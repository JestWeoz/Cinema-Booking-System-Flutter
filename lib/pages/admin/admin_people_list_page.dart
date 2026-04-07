import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/services/people_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:cinema_booking_system_app/shared/widgets/image_picker_button.dart';

class AdminPeopleListPage extends StatefulWidget {
  const AdminPeopleListPage({super.key});

  @override
  State<AdminPeopleListPage> createState() => _AdminPeopleListPageState();
}

class _AdminPeopleListPageState extends State<AdminPeopleListPage> {
  final PeopleService _peopleService = PeopleService.instance;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _displayDate = DateFormat('dd/MM/yyyy');

  List<PeopleResponse> _people = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 0;
  int _total = 0;
  String _search = '';
  String? _nationFilter;
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
      final result = await _peopleService.getAll(
        page: _page - 1,
        size: 10,
        keyword: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _people = result.content;
        _total = result.totalElements;
        _totalPages = result.totalPages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được danh sách people: $e';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
      });
      _load();
    });
  }

  String _formatDob(String? rawDob) {
    if (rawDob == null || rawDob.trim().isEmpty) return 'Chưa cập nhật';
    final parsed = DateTime.tryParse(rawDob);
    if (parsed == null) return rawDob;
    return _displayDate.format(parsed);
  }

  String _roleLabel(dynamic rawRole) {
    final role = (rawRole ?? '').toString().toUpperCase();
    switch (role) {
      case 'ACTOR':
        return 'Diễn viên';
      case 'DIRECTOR':
        return 'Đạo diễn';
      case 'WRITER':
        return 'Biên kịch';
      case 'PRODUCER':
        return 'Nhà sản xuất';
      default:
        return role.isEmpty ? 'Chưa rõ vai trò' : role;
    }
  }

  List<String> get _nationOptions {
    final options = _people
        .map((e) => e.nationality?.trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return options;
  }

  List<PeopleResponse> get _visiblePeople {
    if (_nationFilter == null || _nationFilter!.isEmpty) return _people;
    return _people.where((e) => (e.nationality?.trim() ?? '') == _nationFilter).toList();
  }

  Future<void> _showMoviesByPeople(PeopleResponse person) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            'Phim đã tham gia: ${person.fullName}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _peopleService.getMoviesByPeople(person.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Không tải được danh sách phim: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }
                final movies = snapshot.data ?? const [];
                if (movies.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Chưa có phim nào', style: TextStyle(color: Colors.white54)),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: movies.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.08)),
                    itemBuilder: (_, index) {
                      final movie = movies[index];
                      final title = (movie['movieTitle'] ?? 'Không rõ tên phim').toString();
                      final role = _roleLabel(movie['role']);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Vai trò: $role', style: const TextStyle(color: Colors.white60)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openForm({PeopleResponse? person}) async {
    final changed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _PeopleFormDialog(
        service: _peopleService,
        person: person,
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(person == null ? 'Đã thêm người tham gia' : 'Đã cập nhật người tham gia'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    }
  }

  Future<void> _delete(PeopleResponse person) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Xóa người tham gia',
      message: 'Bạn có chắc muốn xóa "${person.fullName}"?',
      confirmLabel: 'Xóa',
      cancelLabel: 'Hủy',
      destructive: true,
    );
    if (!ok) return;

    try {
      await _peopleService.delete(person.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa người tham gia'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không xóa được: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nationOptions = _nationOptions;
    final visiblePeople = _visiblePeople;

    if (_nationFilter != null && !nationOptions.contains(_nationFilter)) {
      _nationFilter = null;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Người tham gia phim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên...',
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: _nationFilter,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Lọc theo quốc tịch',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả quốc tịch'),
                    ),
                    ...nationOptions.map(
                      (nation) => DropdownMenuItem<String?>(
                        value: nation,
                        child: Text(nation),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _nationFilter = value);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${visiblePeople.length}/${_people.length} người tham gia (tổng: $_total)',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, style: const TextStyle(color: Colors.white70)),
                        ),
                      )
                    : visiblePeople.isEmpty
                        ? const Center(
                            child: Text('Chưa có dữ liệu people', style: TextStyle(color: Colors.white54)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: visiblePeople.length,
                            itemBuilder: (_, index) {
                              final item = visiblePeople[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                                          ? AppNetworkImage(
                                              url: item.avatarUrl!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              borderRadius: 12,
                                              fallbackIcon: Icons.person_outline,
                                              backgroundColor: AppColors.surfaceDark,
                                            )
                                          : Container(
                                              width: 64,
                                              height: 64,
                                              color: AppColors.surfaceDark,
                                              child: const Icon(Icons.person_outline, color: Colors.white38),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.fullName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.nationality?.isNotEmpty == true ? item.nationality! : 'Chưa cập nhật quốc tịch',
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ngày sinh: ${_formatDob(item.dob)}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      color: AppColors.surfaceDark,
                                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                                      onSelected: (value) {
                                        if (value == 'movies') _showMoviesByPeople(item);
                                        if (value == 'edit') _openForm(person: item);
                                        if (value == 'delete') _delete(item);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'movies',
                                          child: Text('Xem phim đã tham gia', style: TextStyle(color: Colors.white)),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white)),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Xóa', style: TextStyle(color: Colors.redAccent)),
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
}

class _PeopleFormDialog extends StatefulWidget {
  final PeopleService service;
  final PeopleResponse? person;

  const _PeopleFormDialog({
    required this.service,
    this.person,
  });

  @override
  State<_PeopleFormDialog> createState() => _PeopleFormDialogState();
}

class _PeopleFormDialogState extends State<_PeopleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDate = DateFormat('dd/MM/yyyy');

  late final TextEditingController _name;
  late final TextEditingController _nation;
  String? _avatarUrl;
  DateTime? _dob;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person?.fullName ?? '');
    _nation = TextEditingController(text: widget.person?.nationality ?? '');
    _avatarUrl = widget.person?.avatarUrl;
    _dob = widget.person?.dob != null ? DateTime.tryParse(widget.person!.dob!) : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _nation.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (selected != null) {
      setState(() => _dob = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_avatarUrl == null || _avatarUrl!.isEmpty) {
      setState(() => _error = 'Vui lòng tải ảnh đại diện');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'nation': _nation.text.trim(),
      'avatarUrl': _avatarUrl,
      if (_dob != null) 'dob': _apiDate.format(_dob!),
    };

    try {
      if (widget.person == null) {
        await widget.service.create(payload);
      } else {
        await widget.service.update(widget.person!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không lưu được người tham gia: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 560 ? 520.0 : (screenWidth - 32).clamp(280.0, 520.0);

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: Text(
        widget.person == null ? 'Thêm người tham gia' : 'Chỉnh sửa người tham gia',
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
                  height: 160,
                  child: ImagePickerButton(
                    label: '',
                    currentImageUrl: _avatarUrl,
                    size: 160,
                    shape: ImagePickerButtonShape.rectangle,
                    onUploaded: (url) => setState(() => _avatarUrl = url),
                    onError: (e) => setState(() => _error = e),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nation,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập quốc tịch' : null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Quốc tịch'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      _dob == null ? 'Chọn ngày sinh' : _displayDate.format(_dob!),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context, rootNavigator: true).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.person == null ? 'Tạo mới' : 'Lưu thay đổi'),
        ),
      ],
    );
  }
}
