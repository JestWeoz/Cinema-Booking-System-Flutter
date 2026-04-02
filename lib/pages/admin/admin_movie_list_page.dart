import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/create_movie_request.dart';
import 'package:cinema_booking_system_app/models/enums.dart';

class AdminMovieListPage extends StatefulWidget {
  const AdminMovieListPage({super.key});
  @override
  State<AdminMovieListPage> createState() => _AdminMovieListPageState();
}

class _AdminMovieListPageState extends State<AdminMovieListPage> {
  final _service = AdminService.instance;
  List<MovieResponse> _movies = [];
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getMovies(page: _page, size: 10, keyword: _search);
      setState(() {
        _movies = result.content;
        _total = result.totalElements;
      });
    } catch (e) {
      _snack('Lỗi tải phim: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        content: const Text('Xoá phim này?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteMovie(id);
      _load();
    }
  }

  Future<void> _changeStatus(String id, MovieStatus current) async {
    final statuses = MovieStatus.values.where((s) => s != current).toList();
    final chosen = await showDialog<MovieStatus>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Đổi trạng thái', style: TextStyle(color: Colors.white)),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, s),
          child: Text(s.name, style: const TextStyle(color: Colors.white70)),
        )).toList(),
      ),
    );
    if (chosen != null) {
      await _service.updateMovieStatus(id, chosen.name);
      _load();
    }
  }

  Color _statusColor(MovieStatus? s) {
    switch (s) {
      case MovieStatus.NOW_SHOWING: return AppColors.success;
      case MovieStatus.COMING_SOON: return AppColors.secondary;
      case MovieStatus.ENDED: return AppColors.textHintDark;
      default: return AppColors.textHintDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Quản lý Phim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: AppColors.primary), onPressed: _showAddDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phim...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _search.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () { _searchCtrl.clear(); setState(() { _search = ''; }); _load(); },
                ),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) { setState(() { _search = v; _page = 1; }); _load(); },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _movies.isEmpty
                    ? const Center(child: Text('Không có phim', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _movies.length,
                        itemBuilder: (_, i) {
                          final m = _movies[i];
                          return _MovieCard(
                            movie: m,
                            statusColor: _statusColor(m.status),
                            onDelete: () => _delete(m.id),
                            onStatus: () => _changeStatus(m.id, m.status ?? MovieStatus.COMING_SOON),
                          );
                        },
                      ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / 10).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
          ),
          Text('$_page / $totalPages', style: const TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _page < totalPages ? () { setState(() => _page++); _load(); } : null,
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final posterCtrl = TextEditingController();
    final trailerCtrl = TextEditingController();
    final langCtrl = TextEditingController(text: 'VIETNAMESE');
    AgeRating selectedRating = AgeRating.G;
    DateTime releaseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Thêm Phim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(titleCtrl, 'Tiêu đề *'),
                const SizedBox(height: 8),
                _field(slugCtrl, 'Slug *'),
                const SizedBox(height: 8),
                _field(descCtrl, 'Mô tả', maxLines: 3),
                const SizedBox(height: 8),
                _field(durationCtrl, 'Thời lượng (phút) *', keyboard: TextInputType.number),
                const SizedBox(height: 8),
                _field(posterCtrl, 'URL Poster *'),
                const SizedBox(height: 8),
                _field(trailerCtrl, 'URL Trailer *'),
                const SizedBox(height: 8),
                _field(langCtrl, 'Ngôn ngữ (vd: VIETNAMESE)'),
                const SizedBox(height: 8),
                DropdownButtonFormField<AgeRating>(
                  value: selectedRating,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: _inputDeco('Giới hạn tuổi'),
                  style: const TextStyle(color: Colors.white),
                  items: AgeRating.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                  onChanged: (v) => setS(() => selectedRating = v!),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ngày chiếu: ${releaseDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: releaseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setS(() => releaseDate = d);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || slugCtrl.text.isEmpty || durationCtrl.text.isEmpty ||
                    posterCtrl.text.isEmpty || trailerCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đủ thông tin *')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _service.createMovie(CreateMovieRequest(
                    title: titleCtrl.text,
                    slug: slugCtrl.text,
                    description: descCtrl.text,
                    duration: int.tryParse(durationCtrl.text) ?? 90,
                    releaseDate: releaseDate,
                    ageRating: selectedRating,
                    language: langCtrl.text,
                    posterUrl: posterCtrl.text,
                    trailerUrl: trailerCtrl.text,
                    categoryIds: [],
                  ));
                  _load();
                } catch (e) {
                  _snack('Lỗi: $e');
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
    filled: true,
    fillColor: AppColors.surfaceDark,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

class _MovieCard extends StatelessWidget {
  final MovieResponse movie;
  final Color statusColor;
  final VoidCallback onDelete;
  final VoidCallback onStatus;

  const _MovieCard({required this.movie, required this.statusColor, required this.onDelete, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: movie.posterUrl != null
              ? Image.network(movie.posterUrl!, width: 44, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: Colors.white54, size: 44))
              : const Icon(Icons.movie, color: Colors.white54, size: 44),
        ),
        title: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${movie.duration} phút · ${movie.releaseDate ?? ""}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(movie.status?.name ?? 'N/A',
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceDark,
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'status', child: Text('Đổi trạng thái', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'delete', child: Text('Xoá', style: TextStyle(color: Colors.redAccent))),
          ],
          onSelected: (v) { if (v == 'delete') onDelete(); else if (v == 'status') onStatus(); },
        ),
      ),
    );
  }
}
