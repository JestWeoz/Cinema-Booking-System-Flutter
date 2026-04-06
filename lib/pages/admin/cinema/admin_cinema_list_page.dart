import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/cinema_form_dialog.dart';
import 'package:cinema_booking_system_app/pages/admin/cinema/cinema_views.dart';

class AdminCinemaListPage extends StatefulWidget {
  const AdminCinemaListPage({super.key});

  @override
  State<AdminCinemaListPage> createState() => _AdminCinemaListPageState();
}

class _AdminCinemaListPageState extends State<AdminCinemaListPage> {
  final CinemaService _service = CinemaService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<CinemaResponse> _items = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _size = 10;
  int _totalPages = 0;
  int _totalElements = 0;
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
      final response = await _service.getAllPaginated(
        page: _page,
        size: _size,
        keyword: _search.isEmpty ? null : _search,
      );
      if (!mounted) return;
      setState(() {
        _items = response.content;
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách rạp: $error';
        _loading = false;
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

  Future<void> _openForm({CinemaResponse? cinema}) async {
    final payload = await showCinemaFormDialog(
      context,
      initial: cinema == null
          ? null
          : CinemaFormPayload(
              name: cinema.name,
              address: cinema.address,
              phone: cinema.phone ?? '',
              hotline: cinema.hotline ?? '',
            ),
    );
    if (payload == null) return;

    try {
      final body = {
        'name': payload.name,
        'address': payload.address,
        'phone': payload.phone,
        'hotline': payload.hotline,
      };
      if (cinema == null) {
        await _service.create(body);
      } else {
        await _service.update(cinema.id, body);
      }
      if (!mounted) return;
      _showSnackBar(cinema == null ? 'Đã tạo rạp thành công' : 'Đã cập nhật rạp thành công');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể lưu rạp: $error', isError: true);
    }
  }

  Future<void> _deleteCinema(CinemaResponse cinema) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xoá rạp chiếu',
      message: 'Xoá "${cinema.name}" sẽ ảnh hưởng đến phòng chiếu và suất chiếu liên quan.',
      confirmLabel: 'Xoá rạp',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await _service.delete(cinema.id);
      if (!mounted) return;
      _showSnackBar('Đã xoá rạp');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể xoá rạp: $error', isError: true);
    }
  }

  Future<void> _toggleCinema(CinemaResponse cinema) async {
    try {
      await _service.toggleStatus(cinema.id);
      if (!mounted) return;
      _showSnackBar('Đã cập nhật trạng thái "${cinema.name}"');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Không thể cập nhật trạng thái: $error', isError: true);
    }
  }

  void _openRooms(CinemaResponse cinema) {
    context.push(
      '${AppRoutes.adminRooms}?cinemaId=${cinema.id}&cinemaName=${Uri.encodeComponent(cinema.name)}',
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
        title: const Text(
          'Rạp chiếu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _openForm,
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _onSearchChanged(value);
                setState(() {});
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên rạp hoặc địa chỉ...',
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
            child: Row(
              children: [
                Text('$_totalElements rạp', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                if (_search.isNotEmpty)
                  Text('Từ khoá: $_search', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? CinemaErrorView(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? const CinemaEmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                            itemCount: _items.length,
                            itemBuilder: (_, index) {
                              final cinema = _items[index];
                              return CinemaCard(
                                cinema: cinema,
                                onOpenRooms: () => _openRooms(cinema),
                                onEdit: () => _openForm(cinema: cinema),
                                onToggle: () => _toggleCinema(cinema),
                                onDelete: () => _deleteCinema(cinema),
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
