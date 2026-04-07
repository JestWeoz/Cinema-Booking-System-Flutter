import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/core/theme/app_text_styles.dart';
import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/movie/add_people_to_movie_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/people_role_request.dart';
import 'package:cinema_booking_system_app/models/requests/movie/update_movie_people_request.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/people_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class AdminMovieContentPage extends StatelessWidget {
  final MovieResponse movie;
  final int initialTabIndex;

  const AdminMovieContentPage({
    super.key,
    required this.movie,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tabIndex = initialTabIndex < 0
        ? 0
        : initialTabIndex > 1
            ? 1
            : initialTabIndex;

    return DefaultTabController(
      length: 2,
      initialIndex: tabIndex,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Quản lý nội dung phim',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            unselectedLabelStyle: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            tabs: const [
              Tab(text: 'Ảnh phim'),
              Tab(text: 'Người tham gia'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _MovieHeaderCard(movie: movie),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MovieImagesTab(movie: movie),
                  _MoviePeopleTab(movie: movie),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieHeaderCard extends StatelessWidget {
  final MovieResponse movie;

  const _MovieHeaderCard({required this.movie});

  String _statusLabel(MovieStatus? status) {
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

  Color _statusColor(MovieStatus? status) {
    switch (status) {
      case MovieStatus.NOW_SHOWING:
        return AppColors.success;
      case MovieStatus.COMING_SOON:
        return AppColors.secondary;
      case MovieStatus.ENDED:
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }

  String _formatReleaseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Chưa cập nhật';
    }
    final parts = value.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(movie.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AppNetworkImage(
              url: movie.posterUrl,
              width: 88,
              height: 124,
              fit: BoxFit.cover,
              fallbackIcon: Icons.movie_outlined,
              backgroundColor: AppColors.surfaceDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderChip(
                      label: _statusLabel(movie.status),
                      color: statusColor,
                    ),
                    _HeaderChip(
                      label: '${movie.duration} phút',
                      color: AppColors.info,
                    ),
                    _HeaderChip(
                      label: _formatReleaseDate(movie.releaseDate),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                if (movie.categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    movie.categories.map((item) => item.name).join(' • '),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Quản lý bộ ảnh của phim và gán người tham gia đã tạo sẵn trong khu vực admin.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;
  final Widget? action;

  const _SectionCard({
    required this.title,
    required this.description,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white54,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white30, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MovieImagesTab extends StatefulWidget {
  final MovieResponse movie;

  const _MovieImagesTab({required this.movie});

  @override
  State<_MovieImagesTab> createState() => _MovieImagesTabState();
}

class _MovieImagesTabState extends State<_MovieImagesTab> {
  final MovieService _movieService = MovieService.instance;

  List<MovieImageResponse> _images = const [];
  bool _loading = true;
  bool _uploading = false;
  String? _busyImageId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final images = await _movieService.getImages(widget.movie.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _images = images;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showSnack('Không tải được ảnh phim: $error');
    }
  }

  void _showSnack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _uploadImages() async {
    setState(() => _uploading = true);
    try {
      final urls = await MediaUploadHelper.pickAndUploadMultipleImages();
      if (urls.isEmpty) {
        return;
      }
      final images = await _movieService.addImages(widget.movie.id, urls);
      if (!mounted) {
        return;
      }
      setState(() => _images = images);
      _showSnack('Đã thêm ${urls.length} ảnh mới', error: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('Không tải ảnh lên được: $error');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _replaceImage(MovieImageResponse image) async {
    setState(() => _busyImageId = image.imageId);
    try {
      final url = await _movieService.pickAndUploadBackdrop(
        onError: (message) => _showSnack(message),
      );
      if (url == null || url.isEmpty) {
        return;
      }
      final updated = await _movieService.updateImages(
        widget.movie.id,
        _images
            .map((item) => item.imageId == image.imageId ? url : item.imageUrl)
            .toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _images = updated);
      _showSnack('Đã thay ảnh phim', error: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('Không thay được ảnh: $error');
    } finally {
      if (mounted) {
        setState(() => _busyImageId = null);
      }
    }
  }

  Future<void> _deleteImage(MovieImageResponse image) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Xóa ảnh phim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Ảnh này sẽ bị xóa khỏi bộ ảnh của phim.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    setState(() => _busyImageId = image.imageId);
    try {
      await _movieService.deleteImage(widget.movie.id, image.imageId);
      if (!mounted) {
        return;
      }
      setState(() {
        _images = _images.where((item) => item.imageId != image.imageId).toList();
      });
      _showSnack('Đã xóa ảnh khỏi phim', error: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('Không xóa được ảnh: $error');
    } finally {
      if (mounted) {
        setState(() => _busyImageId = null);
      }
    }
  }

  void _previewImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AppNetworkImage(
                url: imageUrl,
                fit: BoxFit.contain,
                backgroundColor: AppColors.surfaceDark,
                fallbackIcon: Icons.image_outlined,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _gridCount(double width) {
    if (width >= 1100) {
      return 4;
    }
    if (width >= 700) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _SectionCard(
            title: 'Bộ ảnh phim',
            description: 'Tải ảnh mới, thay ảnh cũ hoặc xóa ảnh không còn dùng.',
            action: FilledButton.icon(
              onPressed: _uploading ? null : _uploadImages,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Tải ảnh'),
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : _images.isEmpty
                    ? const _EmptyState(
                        icon: Icons.image_not_supported_outlined,
                        message: 'Phim này chưa có ảnh phụ.',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _gridCount(constraints.maxWidth),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: _images.length,
                            itemBuilder: (_, index) {
                              final image = _images[index];
                              final busy = _busyImageId == image.imageId;
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _previewImage(image.imageUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AppNetworkImage(
                                          url: image.imageUrl,
                                          fit: BoxFit.cover,
                                          fallbackIcon: Icons.image_outlined,
                                          backgroundColor: AppColors.surfaceDark,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Ảnh ${index + 1}',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      right: 10,
                                      bottom: 10,
                                      child: LayoutBuilder(
                                        builder: (context, buttonConstraints) {
                                          final compact = buttonConstraints.maxWidth < 165;
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: FilledButton.tonalIcon(
                                                  onPressed: busy ? null : () => _replaceImage(image),
                                                  style: FilledButton.styleFrom(
                                                    minimumSize: const Size(0, 42),
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: compact ? 10 : 12,
                                                      vertical: 10,
                                                    ),
                                                    backgroundColor: Colors.black.withValues(alpha: 0.56),
                                                    foregroundColor: Colors.white,
                                                    textStyle: AppTextStyles.labelLarge.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                  ),
                                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                                  label: Text(
                                                    compact ? 'Thay' : 'Thay ảnh',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: busy ? null : () => _deleteImage(image),
                                                tooltip: 'Xóa ảnh',
                                                style: IconButton.styleFrom(
                                                  minimumSize: const Size(42, 42),
                                                  backgroundColor: Colors.black.withValues(alpha: 0.62),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    if (busy)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MoviePeopleTab extends StatefulWidget {
  final MovieResponse movie;

  const _MoviePeopleTab({required this.movie});

  @override
  State<_MoviePeopleTab> createState() => _MoviePeopleTabState();
}

class _MoviePeopleTabState extends State<_MoviePeopleTab> {
  final MovieService _movieService = MovieService.instance;
  final PeopleService _peopleService = PeopleService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<MoviePersonResponse> _currentPeople = const [];
  List<PeopleResponse> _searchResults = const [];
  bool _loading = true;
  bool _searching = false;
  bool _saving = false;
  MovieRole _selectedRole = MovieRole.ACTOR;

  @override
  void initState() {
    super.initState();
    _loadCurrentPeople();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPeople() async {
    setState(() => _loading = true);
    try {
      final people = await _movieService.getPeople(widget.movie.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPeople = people;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _showSnack('Không tải được người tham gia: $error');
    }
  }

  void _showSnack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _searchPeople() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }

    setState(() => _searching = true);
    try {
      final result = await _peopleService.getAll(page: 0, size: 20, keyword: keyword);
      if (!mounted) {
        return;
      }
      final currentIds = _currentPeople.map((item) => item.peopleId).toSet();
      setState(() {
        _searchResults = result.content
            .where((person) => !currentIds.contains(person.id))
            .toList();
        _searching = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _searching = false);
      _showSnack('Không tìm được người tham gia: $error');
    }
  }

  Future<void> _addPerson(PeopleResponse person) async {
    setState(() => _saving = true);
    try {
      final updated = await _movieService.addPeopleToMovie(
        widget.movie.id,
        AddPeopleToMovieRequest(
          people: [
            PeopleRoleRequest(peopleId: person.id, role: _selectedRole),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPeople = updated;
        _searchResults = _searchResults.where((item) => item.id != person.id).toList();
      });
      _showSnack('Đã thêm ${person.fullName} vào phim', error: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('Không thêm được người tham gia: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editRole(MoviePersonResponse person) async {
    var selectedRole = _roleFromRaw(person.role);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          'Đổi vai trò: ${person.fullName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return DropdownButtonFormField<MovieRole>(
              initialValue: selectedRole,
              dropdownColor: AppColors.surfaceDark,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Vai trò'),
              items: MovieRole.values
                  .map(
                    (role) => DropdownMenuItem<MovieRole>(
                      value: role,
                      child: Text(movieRoleLabel(role)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => selectedRole = value);
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await _movieService.replacePeople(
        widget.movie.id,
        UpdateMoviePeopleRequest(
          people: _currentPeople
              .map(
                (item) => PeopleRoleRequest(
                  peopleId: item.peopleId,
                  role: item.peopleId == person.peopleId ? selectedRole : _roleFromRaw(item.role),
                ),
              )
              .toList(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _currentPeople = updated);
      _showSnack('Đã cập nhật vai trò cho ${person.fullName}', error: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('Không cập nhật được vai trò: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _removePerson(MoviePersonResponse person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Xóa khỏi phim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Gỡ ${person.fullName} khỏi danh sách người tham gia của phim này?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gỡ', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _movieService.deletePerson(widget.movie.id, person.peopleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPeople = _currentPeople.where((item) => item.peopleId != person.peopleId).toList();
      });
      _showSnack('Đã gỡ ${person.fullName} khỏi phim', error: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack('Không gỡ được người tham gia: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  MovieRole _roleFromRaw(String rawRole) {
    final value = rawRole.trim().toUpperCase();
    return MovieRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => MovieRole.ACTOR,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadCurrentPeople,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _SectionCard(
            title: 'Chọn từ admin người tham gia',
            description: 'Tìm người đã tạo sẵn trong admin rồi gán vai trò cho phim.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    if (compact) {
                      return Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Tìm theo tên người tham gia...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _searchPeople(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<MovieRole>(
                                  initialValue: _selectedRole,
                                  dropdownColor: AppColors.surfaceDark,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: 'Vai trò'),
                                  items: MovieRole.values
                                      .map(
                                        (role) => DropdownMenuItem<MovieRole>(
                                          value: role,
                                          child: Text(movieRoleLabel(role)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedRole = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _searching ? null : _searchPeople,
                                style: ElevatedButton.styleFrom(
                                  textStyle: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                                child: _searching
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Tìm'),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Tìm theo tên người tham gia...',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onSubmitted: (_) => _searchPeople(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<MovieRole>(
                            initialValue: _selectedRole,
                            dropdownColor: AppColors.surfaceDark,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Vai trò'),
                            items: MovieRole.values
                                .map(
                                  (role) => DropdownMenuItem<MovieRole>(
                                    value: role,
                                    child: Text(movieRoleLabel(role)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _searching ? null : _searchPeople,
                          style: ElevatedButton.styleFrom(
                            textStyle: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                          child: _searching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Tìm'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Kết quả bên dưới lấy từ danh sách Người tham gia đã được tạo trong admin.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Kết quả tìm kiếm',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._searchResults.map(
                    (person) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: AppNetworkImage(
                              url: person.avatarUrl,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.person_outline,
                              backgroundColor: AppColors.cardDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.fullName,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                                if (person.nationality?.isNotEmpty == true)
                                  Text(
                                    person.nationality!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white54,
                                      height: 1.35,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saving ? null : () => _addPerson(person),
                            style: ElevatedButton.styleFrom(
                              textStyle: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('Thêm'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_searchController.text.trim().isNotEmpty && !_searching) ...[
                  const SizedBox(height: 14),
                  const _EmptyState(
                    icon: Icons.search_off_outlined,
                    message: 'Không có người phù hợp hoặc người đó đã nằm trong phim.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Người tham gia hiện tại',
            description: 'Thêm, đổi vai trò hoặc gỡ người tham gia khỏi phim.',
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : _currentPeople.isEmpty
                    ? const _EmptyState(
                        icon: Icons.groups_outlined,
                        message: 'Phim này chưa có người tham gia nào.',
                      )
                    : Column(
                        children: _currentPeople.map((person) {
                          final role = _roleFromRaw(person.role);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: AppNetworkImage(
                                    url: person.avatarUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    fallbackIcon: Icons.person_outline,
                                    backgroundColor: AppColors.cardDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.fullName,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          movieRoleLabel(role),
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _saving ? null : () => _editRole(person),
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                ),
                                IconButton(
                                  onPressed: _saving ? null : () => _removePerson(person),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
