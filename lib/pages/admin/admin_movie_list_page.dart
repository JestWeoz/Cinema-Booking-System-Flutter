import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/pages/admin/admin_movie_content_page.dart';
import 'package:cinema_booking_system_app/services/admin_service.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/category_service.dart';
import 'package:cinema_booking_system_app/services/people_service.dart';
import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/create_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/Movie/update_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/add_people_to_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/create_movie_image_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/people_role_request.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';
import 'package:cinema_booking_system_app/shared/widgets/image_picker_button.dart';
import 'package:cinema_booking_system_app/shared/widgets/video_picker_button.dart';

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

  void _snack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        content: const Text('Xoá phim này?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
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
      useRootNavigator: true,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Đổi trạng thái', style: TextStyle(color: Colors.white)),
        children: statuses
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, s),
                  child: Text(_movieStatusLabel(s), style: const TextStyle(color: Colors.white70)),
                ))
            .toList(),
      ),
    );
    if (chosen != null) {
      await _service.updateMovieStatus(id, chosen.name);
      _load();
    }
  }

  Color _statusColor(MovieStatus? s) {
    switch (s) {
      case MovieStatus.NOW_SHOWING:
        return AppColors.success;
      case MovieStatus.COMING_SOON:
        return AppColors.secondary;
      case MovieStatus.ENDED:
        return AppColors.textHintDark;
      default:
        return AppColors.textHintDark;
    }
  }

  String _movieStatusLabel(MovieStatus? status) {
    switch (status) {
      case MovieStatus.NOW_SHOWING:
        return 'Đang chiếu';
      case MovieStatus.COMING_SOON:
        return 'Sắp chiếu';
      case MovieStatus.ENDED:
        return 'Đã kết thúc';
      default:
        return 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Quản lý Phim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _showAddMovieSheet,
          ),
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
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _load();
                        },
                      ),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) {
                setState(() {
                  _search = v;
                  _page = 1;
                });
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _movies.isEmpty
                    ? const Center(
                        child: Text('Không có phim', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _movies.length,
                        itemBuilder: (_, i) {
                          final m = _movies[i];
                          return _MovieCard(
                            movie: m,
                            statusColor: _statusColor(m.status),
                            onOpen: () => _openMovieContentPage(m),
                            onDelete: () => _delete(m.id),
                            onStatus: () =>
                                _changeStatus(m.id, m.status ?? MovieStatus.COMING_SOON),
                            onEdit: () => _showEditMovieSheet(m),
                            onImages: () => _showManageImagesSheet(m),
                            onPeople: () => _showManagePeopleSheet(m),
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
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _load();
                  }
                : null,
          ),
          Text('$_page / $totalPages', style: const TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _page < totalPages
                ? () {
                    setState(() => _page++);
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ─── Add Movie Bottom Sheet ──────────────────────────────────────────────

  void _showAddMovieSheet() {
    // Lưu messenger trước khi mở sheet để dùng sau
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddMovieSheet(
        onCreated: () {
          _load();
          messenger.showSnackBar(const SnackBar(
            content: Text('Tạo phim thành công!'),
            backgroundColor: AppColors.success,
          ));
        },
      ),
    );
  }

  void _showEditMovieSheet(MovieResponse movie) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditMovieSheet(
        movie: movie,
        onUpdated: () {
          _load();
          messenger.showSnackBar(const SnackBar(
            content: Text('Cập nhật phim thành công!'),
            backgroundColor: AppColors.success,
          ));
        },
      ),
    );
  }

  void _showManageImagesSheet(MovieResponse movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ManageMovieImagesSheet(movie: movie, onChanged: _load),
    );
  }

  void _showManagePeopleSheet(MovieResponse movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ManageMoviePeopleSheet(movie: movie, onChanged: _load),
    );
  }

  Future<void> _openMovieContentPage(
    MovieResponse movie, {
    int initialTabIndex = 0,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminMovieContentPage(
          movie: movie,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    _load();
  }
}

// ─── Add Movie Sheet ─────────────────────────────────────────────────────────

class _AddMovieSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _AddMovieSheet({required this.onCreated});

  @override
  State<_AddMovieSheet> createState() => _AddMovieSheetState();
}

class _AddMovieSheetState extends State<_AddMovieSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String? _posterUrl;
  String? _trailerUrl;
  bool _saving = false;
  String? _errorMsg;

  // ── Category ──
  List<CategoryResponse> _categories = [];
  final Set<String> _selectedCategoryIds = {};
  bool _categoriesLoading = false;

  AgeRating _ageRating = AgeRating.P;
  Language _language = Language.ORIGINAL;
  DateTime _releaseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final list = await CategoryService.instance.getAll();
      if (mounted) setState(() => _categories = list);
    } catch (_) {
      // categories not critical — form still usable
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _setError(String msg) {
    if (mounted) setState(() => _errorMsg = msg);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _releaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null && mounted) setState(() => _releaseDate = d);
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);

    if (_titleCtrl.text.trim().isEmpty) {
      _setError('Vui lòng nhập tiêu đề phim');
      return;
    }
    if (_durationCtrl.text.trim().isEmpty) {
      _setError('Vui lòng nhập thời lượng');
      return;
    }
    if (_posterUrl == null || _posterUrl!.isEmpty) {
      _setError('Vui lòng tải poster phim lên trước khi tạo');
      return;
    }
    if (_trailerUrl == null || _trailerUrl!.isEmpty) {
      _setError('Vui lòng tải trailer phim lên trước khi tạo');
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _setError('Vui lòng chọn ít nhất 1 thể loại');
      return;
    }

    setState(() => _saving = true);
    try {
      await MovieService.instance.create(CreateMovieRequest(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        duration: int.tryParse(_durationCtrl.text) ?? 90,
        releaseDate: _releaseDate,
        ageRating: _ageRating,
        language: _language.name,
        posterUrl: _posterUrl!,
        trailerUrl: _trailerUrl!,
        categoryIds: _selectedCategoryIds.toList(),
      ));
      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } catch (e) {
      _setError('Lỗi tạo phim: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text('Thêm Phim Mới',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Poster ──
            const Text('Poster phim *',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ImagePickerButton(
                label: '',
                currentImageUrl: _posterUrl,
                size: 180,
                shape: ImagePickerButtonShape.rectangle,
                onUploaded: (url) => setState(() => _posterUrl = url),
                onError: _setError,
              ),
            ),
            const SizedBox(height: 12),

            // ── Trailer ──
            VideoPickerButton(
              label: 'Trailer phim *',
              currentVideoUrl: _trailerUrl,
              onUploaded: (url) => setState(() => _trailerUrl = url),
              onError: _setError,
            ),
            const SizedBox(height: 16),

            // ── Fields ──
            _field(_titleCtrl, 'Tiêu đề *'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Slug sẽ được tự động tạo từ tiêu đề phim.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            _field(_descCtrl, 'Mô tả', maxLines: 3),
            const SizedBox(height: 10),
            _field(_durationCtrl, 'Thời lượng (phút) *', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _languageDropdown(
              value: _language,
              onChanged: (value) => setState(() => _language = value),
            ),
            const SizedBox(height: 16),

            // ── Thể loại ──
            _CategoryPicker(
              categories: _categories,
              loading: _categoriesLoading,
              selectedIds: _selectedCategoryIds,
              onToggle: (id) => setState(() {
                if (_selectedCategoryIds.contains(id)) {
                  _selectedCategoryIds.remove(id);
                } else {
                  _selectedCategoryIds.add(id);
                }
              }),
            ),
            const SizedBox(height: 10),

            // ── Age Rating ──
            DropdownButtonFormField<AgeRating>(
              initialValue: _ageRating,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              decoration: _deco('Giới hạn tuổi'),
              style: const TextStyle(color: Colors.white),
              items: AgeRating.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => setState(() => _ageRating = v!),
            ),
            const SizedBox(height: 10),

            // ── Release Date ──
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ngày chiếu: ${_releaseDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tạo Phim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            // ── Inline error message ──
            if (_errorMsg != null) ...
              [
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _languageDropdown({
    required Language value,
    required ValueChanged<Language> onChanged,
  }) {
    return DropdownButtonFormField<Language>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      decoration: _deco('Ngôn ngữ'),
      style: const TextStyle(color: Colors.white),
      items: Language.values
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(languageLabel(item)),
              ))
          .toList(),
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }

  Widget _field(TextEditingController c, String hint,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: _deco(hint),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

// ─── Edit Movie Sheet ────────────────────────────────────────────────────────

class _EditMovieSheet extends StatefulWidget {
  final MovieResponse movie;
  final VoidCallback onUpdated;
  const _EditMovieSheet({required this.movie, required this.onUpdated});

  @override
  State<_EditMovieSheet> createState() => _EditMovieSheetState();
}

class _EditMovieSheetState extends State<_EditMovieSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _durationCtrl;

  late String? _posterUrl;
  late String? _trailerUrl;
  bool _saving = false;
  String? _errorMsg;

  // ── Category ──
  List<CategoryResponse> _categories = [];
  late Set<String> _selectedCategoryIds;
  bool _categoriesLoading = false;
  AgeRating _ageRating = AgeRating.P;
  Language _language = Language.ORIGINAL;
  DateTime _releaseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final m = widget.movie;
    _titleCtrl = TextEditingController(text: m.title);
    _descCtrl = TextEditingController(text: m.description);
    _durationCtrl = TextEditingController(text: m.duration.toString());
    _ageRating = m.ageRating ?? AgeRating.P;
    _language = languageFromJson(m.language) ?? Language.ORIGINAL;
    _releaseDate = DateTime.tryParse(m.releaseDate ?? '') ?? DateTime.now();
    _posterUrl = m.posterUrl;
    _trailerUrl = m.trailerUrl;
    // Khởi tạo category đã chọn từ movie hiện tại
    _selectedCategoryIds = m.categories.map((c) => c.id).toSet();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final list = await CategoryService.instance.getAll();
      if (mounted) setState(() => _categories = list);
    } catch (_) {
      // not critical
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _setError(String msg) {
    if (mounted) setState(() => _errorMsg = msg);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _releaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null && mounted) {
      setState(() => _releaseDate = d);
    }
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);
    if (_titleCtrl.text.trim().isEmpty) {
      _setError('Vui lòng nhập tiêu đề phim');
      return;
    }
    if (_durationCtrl.text.trim().isEmpty) {
      _setError('Vui lòng nhập thời lượng');
      return;
    }
    if (_posterUrl == null || _posterUrl!.isEmpty) {
      _setError('Vui lòng tải poster phim');
      return;
    }
    if (_trailerUrl == null || _trailerUrl!.isEmpty) {
      _setError('Vui lòng tải trailer phim');
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      _setError('Vui lòng chọn ít nhất 1 thể loại');
      return;
    }
    setState(() => _saving = true);
    try {
      await MovieService.instance.update(
        widget.movie.id,
        UpdateMovieRequest(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          duration: int.tryParse(_durationCtrl.text) ?? widget.movie.duration,
          releaseDate: _releaseDate,
          ageRating: _ageRating,
          language: _language.name,
          posterUrl: _posterUrl,
          trailerUrl: _trailerUrl,
          categoryIds: _selectedCategoryIds.toList(),
        ),
      );
      if (mounted) Navigator.pop(context);
      widget.onUpdated();
    } catch (e) {
      _setError('Lỗi cập nhật: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Chỉnh Sửa Phim',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Poster ──
            const Text('Poster phim',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ImagePickerButton(
                label: '',
                currentImageUrl: _posterUrl,
                size: 180,
                shape: ImagePickerButtonShape.rectangle,
                onUploaded: (url) => setState(() => _posterUrl = url),
                onError: _setError,
              ),
            ),
            const SizedBox(height: 12),

            // ── Trailer ──
            VideoPickerButton(
              label: 'Trailer phim',
              currentVideoUrl: _trailerUrl,
              onUploaded: (url) => setState(() => _trailerUrl = url),
              onError: _setError,
            ),
            const SizedBox(height: 16),

            _field(_titleCtrl, 'Tiêu đề'),
            const SizedBox(height: 10),
            _field(_descCtrl, 'Mô tả', maxLines: 3),
            const SizedBox(height: 10),
            _field(_durationCtrl, 'Thời lượng (phút)', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _languageDropdown(
              value: _language,
              onChanged: (value) => setState(() => _language = value),
            ),
            const SizedBox(height: 16),

            // ── Thể loại ──
            _CategoryPicker(
              categories: _categories,
              loading: _categoriesLoading,
              selectedIds: _selectedCategoryIds,
              onToggle: (id) => setState(() {
                if (_selectedCategoryIds.contains(id)) {
                  _selectedCategoryIds.remove(id);
                } else {
                  _selectedCategoryIds.add(id);
                }
              }),
            ),
            const SizedBox(height: 10),

            // ── Age Rating ──
            _ageRatingDropdown(),
            const SizedBox(height: 10),

            // ── Release Date ──
            _releaseDatePicker(),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Lưu Thay Đổi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            // ── Inline error message ──
            if (_errorMsg != null) ...
              [
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _languageDropdown({
    required Language value,
    required ValueChanged<Language> onChanged,
  }) {
    return DropdownButtonFormField<Language>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      decoration: _deco('Ngôn ngữ'),
      style: const TextStyle(color: Colors.white),
      items: Language.values
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(languageLabel(item)),
              ))
          .toList(),
      onChanged: (next) {
        if (next != null) {
          onChanged(next);
        }
      },
    );
  }

  Widget _field(TextEditingController c, String hint,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _ageRatingDropdown() {
    return DropdownButtonFormField<AgeRating>(
      initialValue: _ageRating,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      decoration: _deco('Giới hạn tuổi'),
      style: const TextStyle(color: Colors.white),
      items: AgeRating.values
          .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _ageRating = v);
      },
    );
  }

  Widget _releaseDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(
              'Ngày chiếu: ${_releaseDate.toLocal().toString().split(" ")[0]}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Picker Widget ───────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final List<CategoryResponse> categories;
  final Set<String> selectedIds;
  final bool loading;
  final void Function(String id) onToggle;

  const _CategoryPicker({
    required this.categories,
    required this.selectedIds,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Thể loại',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (loading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (!loading && categories.isEmpty)
          Text(
            'Chưa có thể loại nào. Hãy tạo thể loại trong Quản lý Thể Loại.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: categories.map((cat) {
              final selected = selectedIds.contains(cat.id);
              return FilterChip(
                label: Text(cat.name),
                selected: selected,
                onSelected: (_) => onToggle(cat.id),
                selectedColor: AppColors.primary.withValues(alpha: 0.25),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: AppColors.surfaceDark,
                side: BorderSide(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.15),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ManageMovieImagesSheet extends StatefulWidget {
  final MovieResponse movie;
  final VoidCallback onChanged;

  const _ManageMovieImagesSheet({
    required this.movie,
    required this.onChanged,
  });

  @override
  State<_ManageMovieImagesSheet> createState() => _ManageMovieImagesSheetState();
}

class _ManageMovieImagesSheetState extends State<_ManageMovieImagesSheet> {
  final MovieService _movieService = MovieService.instance;
  List<MovieImageResponse> _images = const [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final images = await _movieService.getImages(widget.movie.id);
      if (!mounted) return;
      setState(() {
        _images = images;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadMultiple() async {
    setState(() => _uploading = true);
    try {
      final urls = await MediaUploadHelper.pickAndUploadMultipleImages();
      final request = CreateMovieImageRequest(imageUrls: urls);
      for (final url in request.imageUrls) {
        await _movieService.addImage(widget.movie.id, {'imageUrl': url});
      }
      if (!mounted) return;
      widget.onChanged();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải ảnh lên được: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteImage(MovieImageResponse image) async {
    await _movieService.deleteImage(widget.movie.id, image.imageId);
    if (!mounted) return;
    widget.onChanged();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Ảnh phim • ${widget.movie.title}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: _uploading ? null : _uploadMultiple,
                  icon: _uploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Tải lên'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _images.isEmpty
                      ? const Center(child: Text('Chưa có ảnh nào', style: TextStyle(color: Colors.white54)))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (_, index) {
                            final image = _images[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AppNetworkImage(
                                    url: image.imageUrl,
                                    fit: BoxFit.cover,
                                    borderRadius: 12,
                                    backgroundColor: AppColors.surfaceDark,
                                    iconColor: Colors.white38,
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: IconButton(
                                    onPressed: () => _deleteImage(image),
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageMoviePeopleSheet extends StatefulWidget {
  final MovieResponse movie;
  final VoidCallback onChanged;

  const _ManageMoviePeopleSheet({
    required this.movie,
    required this.onChanged,
  });

  @override
  State<_ManageMoviePeopleSheet> createState() => _ManageMoviePeopleSheetState();
}

class _ManageMoviePeopleSheetState extends State<_ManageMoviePeopleSheet> {
  final MovieService _movieService = MovieService.instance;
  final PeopleService _peopleService = PeopleService.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  List<MoviePersonResponse> _currentPeople = const [];
  List<PeopleResponse> _searchResults = const [];
  final Set<String> _selectedPeopleIds = <String>{};
  bool _loading = true;
  bool _searching = false;
  MovieRole _role = MovieRole.ACTOR;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    setState(() => _loading = true);
    try {
      final people = await _movieService.getPeople(widget.movie.id);
      if (!mounted) return;
      setState(() {
        _currentPeople = people;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchPeople() async {
    final keyword = _searchCtrl.text.trim();
    if (keyword.isEmpty) return;
    setState(() => _searching = true);
    try {
      final result = await _peopleService.getAll(keyword: keyword, page: 0, size: 20);
      if (!mounted) return;
      setState(() {
        _searchResults = result.content
            .where((person) => !_currentPeople.any((item) => item.peopleId == person.id))
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addSelected() async {
    if (_selectedPeopleIds.isEmpty) return;
    final request = AddPeopleToMovieRequest(
      people: _selectedPeopleIds
          .map((id) => PeopleRoleRequest(peopleId: id, role: _role))
          .toList(),
    );
    await _movieService.addPerson(widget.movie.id, request.toJson());
    if (!mounted) return;
    _selectedPeopleIds.clear();
    _searchCtrl.clear();
    _searchResults = const [];
    widget.onChanged();
    _loadCurrent();
  }

  Future<void> _removePerson(MoviePersonResponse person) async {
    await _movieService.deletePerson(widget.movie.id, person.peopleId);
    if (!mounted) return;
    widget.onChanged();
    _loadCurrent();
  }

  String _personRoleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ACTOR':
        return 'Diễn viên';
      case 'DIRECTOR':
        return 'Đạo diễn';
      case 'PRODUCER':
        return 'Nhà sản xuất';
      case 'WRITER':
        return 'Biên kịch';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SizedBox(
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diễn viên • ${widget.movie.title}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm diễn viên/đạo diễn...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _searchPeople(),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<MovieRole>(
                  value: _role,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  items: MovieRole.values
                      .map((role) => DropdownMenuItem<MovieRole>(value: role, child: Text(movieRoleLabel(role))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searching ? null : _searchPeople,
                  child: _searching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tìm'),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchResults.map((person) {
                  final selected = _selectedPeopleIds.contains(person.id);
                  return FilterChip(
                    label: Text(person.fullName),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedPeopleIds.remove(person.id);
                        } else {
                          _selectedPeopleIds.add(person.id);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.22),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(color: selected ? AppColors.primary : Colors.white70),
                    backgroundColor: AppColors.surfaceDark,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _selectedPeopleIds.isEmpty ? null : _addSelected,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text('Thêm ${_selectedPeopleIds.length} người'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _currentPeople.isEmpty
                      ? const Center(child: Text('Chưa có cast nào', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          itemCount: _currentPeople.length,
                          itemBuilder: (_, index) {
                            final person = _currentPeople[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceDark,
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: AppNetworkImage(
                                      url: person.avatarUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.person_outline,
                                      backgroundColor: AppColors.surfaceDark,
                                      iconColor: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(person.fullName, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(_personRoleLabel(person.role), style: const TextStyle(color: Colors.white54)),
                              trailing: IconButton(
                                onPressed: () => _removePerson(person),
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Movie Card ───────────────────────────────────────────────────────────────


class _MovieCard extends StatelessWidget {
  final MovieResponse movie;
  final Color statusColor;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onStatus;
  final VoidCallback onEdit;
  final VoidCallback onImages;
  final VoidCallback onPeople;

  const _MovieCard({
    required this.movie,
    required this.statusColor,
    required this.onOpen,
    required this.onDelete,
    required this.onStatus,
    required this.onEdit,
    required this.onImages,
    required this.onPeople,
  });

  String _movieStatusLabel(MovieStatus? status) {
    switch (status) {
      case MovieStatus.NOW_SHOWING:
        return 'Đang chiếu';
      case MovieStatus.COMING_SOON:
        return 'Sắp chiếu';
      case MovieStatus.ENDED:
        return 'Đã kết thúc';
      default:
        return 'Không rõ';
    }
  }

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
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: movie.posterUrl != null
              ? AppNetworkImage(
                  url: movie.posterUrl!,
                  width: 44,
                  height: 56,
                  fit: BoxFit.cover,
                  borderRadius: 8,
                  fallbackIcon: Icons.movie,
                  backgroundColor: AppColors.surfaceDark,
                  iconColor: Colors.white54,
                )
              : const Icon(Icons.movie, color: Colors.white54, size: 44),
        ),
        title: Text(
          movie.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${movie.duration} phút · ${movie.releaseDate ?? ""}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _movieStatusLabel(movie.status),
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ActionChip(label: 'Ảnh', onTap: onImages),
                _ActionChip(label: 'Diễn viên', onTap: onPeople),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceDark,
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit',
                child: Text('Chỉnh sửa', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(
                value: 'status',
                child: Text('Đổi trạng thái', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Xoá', style: TextStyle(color: Colors.redAccent))),
          ],
          onSelected: (v) {
            if (v == 'delete') onDelete();
            if (v == 'status') onStatus();
            if (v == 'edit') onEdit();
          },
        ),
      ),
    );
  }
}
