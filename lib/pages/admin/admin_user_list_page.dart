import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/auth_response.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';
import 'package:cinema_booking_system_app/services/user_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class AdminUserListPage extends StatefulWidget {
  final bool staffOnly;
  const AdminUserListPage({super.key, this.staffOnly = false});

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  final AdminService _adminService = AdminService.instance;
  final UserService _userService = UserService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<UserResponse> _users = const [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 0;
  int _total = 0;
  String _search = '';
  String? _roleFilter;
  bool? _statusFilter;

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'STAFF':
        return 'Nhân viên';
      case 'USER':
        return 'Người dùng';
      default:
        return role;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.staffOnly) {
        final users = await _userService.getStaff();
        if (!mounted) return;
        setState(() {
          _users = _applyFilters(users);
          _total = _users.length;
          _totalPages = 1;
          _loading = false;
        });
      } else {
        final result = await _adminService.getUsers(
          page: _page - 1,
          size: 10,
          key: _search.isEmpty ? null : _search,
        );
        final filtered = _applyFilters(result.content);
        if (!mounted) return;
        setState(() {
          _users = filtered;
          _total = result.totalElements;
          _totalPages = result.totalPages;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được người dùng: $e';
      });
    }
  }

  List<UserResponse> _applyFilters(List<UserResponse> items) {
    return items.where((user) {
      final roleOk = _roleFilter == null || user.roles.any((role) => role.toUpperCase().contains(_roleFilter!));
      final statusOk = _statusFilter == null || user.status == _statusFilter;
      return roleOk && statusOk;
    }).toList();
  }

  Future<void> _toggleLock(UserResponse user) async {
    try {
      if (user.status) {
        await _adminService.lockUser(user.id);
      } else {
        await _adminService.unlockUser(user.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user.status ? 'Đã khoá tài khoản' : 'Đã mở khoá tài khoản'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được tài khoản: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          widget.staffOnly ? 'Nhân viên' : 'Người dùng',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (value) {
                    setState(() {
                      _search = value.trim();
                      _page = 1;
                    });
                    _load();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email, username...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _roleFilter,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Vai trò'),
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('Tất cả vai trò')),
                          DropdownMenuItem<String?>(value: 'ADMIN', child: Text('Quản trị viên')),
                          DropdownMenuItem<String?>(value: 'STAFF', child: Text('Nhân viên')),
                          DropdownMenuItem<String?>(value: 'USER', child: Text('Người dùng')),
                        ],
                        onChanged: (value) {
                          setState(() => _roleFilter = value);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _statusFilter,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Trạng thái'),
                        items: const [
                          DropdownMenuItem<bool?>(value: null, child: Text('Tất cả')),
                          DropdownMenuItem<bool?>(value: true, child: Text('Đang hoạt động')),
                          DropdownMenuItem<bool?>(value: false, child: Text('Đã khoá')),
                        ],
                        onChanged: (value) {
                          setState(() => _statusFilter = value);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$_total tài khoản', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.white70))))
                    : _users.isEmpty
                        ? const Center(child: Text('Không tìm thấy người dùng', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _users.length,
                            itemBuilder: (_, i) {
                              final user = _users[i];
                              final isAdmin = user.roles.any((r) => r.toUpperCase().contains('ADMIN'));
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin
                                        ? AppColors.primary.withValues(alpha: 0.2)
                                        : AppColors.info.withValues(alpha: 0.2),
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: AppNetworkImage(
                                          url: user.avatarUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.person_outline,
                                          backgroundColor: isAdmin
                                              ? AppColors.primary.withValues(alpha: 0.2)
                                              : AppColors.info.withValues(alpha: 0.2),
                                          iconColor: isAdmin ? AppColors.primary : AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.fullName.isNotEmpty ? user.fullName : user.username,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: user.roles
                                            .map(
                                              (role) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: role.toUpperCase().contains('ADMIN')
                                                      ? AppColors.primary.withValues(alpha: 0.2)
                                                      : AppColors.info.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _roleLabel(role),
                                                  style: TextStyle(
                                                    color: role.toUpperCase().contains('ADMIN') ? AppColors.primary : AppColors.info,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                  trailing: isAdmin
                                      ? null
                                      : IconButton(
                                          onPressed: () => _toggleLock(user),
                                          icon: Icon(
                                            user.status ? Icons.lock_open_outlined : Icons.lock_outlined,
                                            color: user.status ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
          ),
          if (!widget.staffOnly)
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
