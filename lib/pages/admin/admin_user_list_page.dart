import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';

class AdminUserListPage extends StatefulWidget {
  final bool staffOnly;
  const AdminUserListPage({super.key, this.staffOnly = false});
  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  final _service = AdminService.instance;
  List<UserResponse> _users = [];
  bool _loading = true;
  int _page = 0;
  int _total = 0;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.getUsers(page: _page, size: 10, key: _search.isEmpty ? null : _search);
      List<UserResponse> filtered = r.content;
      if (widget.staffOnly) {
        filtered = filtered.where((u) => u.roles.any((r) => r.toUpperCase().contains('STAFF'))).toList();
      }
      setState(() { _users = filtered; _total = r.totalElements; });
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.error));

  Future<void> _toggleLock(UserResponse u) async {
    try {
      if (u.status) {
        await _service.lockUser(u.id);
        _snack('Đã khoá tài khoản ${u.username}');
      } else {
        await _service.unlockUser(u.id);
        _snack('Đã mở khoá ${u.username}');
      }
      _load();
    } catch (e) { _snack('Lỗi: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(widget.staffOnly ? 'Nhân Viên' : 'Người Dùng',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true, fillColor: AppColors.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (v) { setState(() { _search = v; _page = 0; }); _load(); },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _users.isEmpty
                  ? const Center(child: Text('Không tìm thấy', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        final isAdmin = u.roles.any((r) => r.toUpperCase().contains('ADMIN'));
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.info.withValues(alpha: 0.2),
                              backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                              child: u.avatarUrl == null
                                  ? Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : u.username[0].toUpperCase(),
                                      style: TextStyle(color: isAdmin ? AppColors.primary : AppColors.info, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            title: Text(u.fullName.isNotEmpty ? u.fullName : u.username,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(u.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 2),
                              Row(children: u.roles.map((r) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: r.contains('ADMIN') ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.info.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(r, style: TextStyle(
                                  color: r.contains('ADMIN') ? AppColors.primary : AppColors.info,
                                  fontSize: 9, fontWeight: FontWeight.w600,
                                )),
                              )).toList()),
                            ]),
                            trailing: isAdmin ? null : IconButton(
                              icon: Icon(u.status ? Icons.lock_open_outlined : Icons.lock_outlined,
                                  color: u.status ? AppColors.success : AppColors.error),
                              onPressed: () => _toggleLock(u),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        _pagination(),
      ]),
    );
  }

  Widget _pagination() {
    final total = (_total / 10).ceil();
    if (total <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: _page > 0 ? () { setState(() => _page--); _load(); } : null),
        Text('${_page + 1} / $total', style: const TextStyle(color: Colors.white)),
        IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: _page < total - 1 ? () { setState(() => _page++); _load(); } : null),
      ]),
    );
  }
}
