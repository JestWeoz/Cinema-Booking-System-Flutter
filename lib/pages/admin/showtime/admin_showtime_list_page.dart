import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/enums.dart';
import 'package:cinema_booking_system_app/models/requests/showtime_requests.dart';
import 'package:cinema_booking_system_app/models/responses/movie_response.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/models/responses/showtime_response.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:cinema_booking_system_app/services/movie_service.dart';
import 'package:cinema_booking_system_app/services/room_seat_service.dart';
import 'package:cinema_booking_system_app/services/showtime_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_pagination.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/confirm_dialog.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

class AdminShowtimeListPage extends StatefulWidget {
  const AdminShowtimeListPage({super.key});

  @override
  State<AdminShowtimeListPage> createState() => _AdminShowtimeListPageState();
}

class _AdminShowtimeListPageState extends State<AdminShowtimeListPage> {
  final ShowtimeService _showtimeService = ShowtimeService.instance;
  final CinemaService _cinemaService = CinemaService.instance;
  final MovieService _movieService = MovieService.instance;
  final RoomService _roomService = RoomService.instance;
  final TextEditingController _keywordController = TextEditingController();

  List<ShowtimeSummaryResponse> _items = const [];
  List<CinemaResponse> _cinemas = const [];
  List<MovieResponse> _movies = const [];
  List<RoomResponse> _rooms = const [];
  bool _loading = true;
  bool _loadingLookups = true;
  String? _error;
  int _page = 1;
  final int _size = 20;
  int _totalPages = 0;
  int _totalElements = 0;
  String? _keyword;
  String? _movieId;
  String? _cinemaId;
  String? _roomId;
  Language? _language;
  ShowTimeStatus? _status;
  DateTime? _date;

  // Đếm số filter đang active
  int get _activeFilterCount {
    int count = 0;
    if (_movieId != null) count++;
    if (_cinemaId != null) count++;
    if (_roomId != null) count++;
    if (_language != null) count++;
    if (_status != null) count++;
    if (_date != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loadingLookups = true);
    try {
      final results = await Future.wait<dynamic>([
        _cinemaService.getAll(keyword: null),
        _movieService.getAll(page: 1, size: 200),
      ]);
      if (!mounted) return;
      setState(() {
        _cinemas = results[0] as List<CinemaResponse>;
        _movies = (results[1] as dynamic).content as List<MovieResponse>;
        _loadingLookups = false;
      });
      if (_cinemaId != null && _cinemaId!.isNotEmpty) {
        await _loadRooms(_cinemaId!);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLookups = false;
        _error = 'Khong tai duoc du lieu bo loc: $error';
      });
    }
  }

  Future<void> _loadRooms(String cinemaId) async {
    try {
      final rooms = await _roomService.getByCinema(cinemaId, size: 100);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        final roomExists = _rooms.any((room) => room.id == _roomId);
        if (!roomExists) {
          _roomId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rooms = const [];
        _roomId = null;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _showtimeService.getPaginated(
        filter: ShowtimeFilterRequest(
          movieId: _movieId,
          cinemaId: _cinemaId,
          roomId: _roomId,
          date: _date == null ? null : DateFormat('yyyy-MM-dd').format(_date!),
          language: _language,
          status: _status,
          keyword: _keyword,
          page: _page,
          size: _size,
        ),
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
        _loading = false;
        _error = 'Khong tai duoc danh sach suat chieu: $error';
      });
    }
  }

  Future<void> _openCreatePage() async {
    final created = await context.push<bool>(AppRoutes.adminShowtimeCreate);
    if (created == true && mounted) {
      _showSnackBar('Da tao suat chieu');
      _load();
    }
  }

  Future<void> _openEditPage(ShowtimeSummaryResponse item) async {
    final changed = await context.push<bool>(
      AppRoutes.adminShowtimeEditById(item.id),
    );
    if (changed == true && mounted) {
      _showSnackBar('Da cap nhat suat chieu');
      _load();
    }
  }

  Future<void> _cancelShowtime(ShowtimeSummaryResponse item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Huy suat chieu',
      message: 'Huy "${item.movieTitle}" luc ${_formatDateTime(item.startTime)}?',
      confirmLabel: 'Huy suat',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await _showtimeService.cancel(item.id);
      if (!mounted) return;
      _showSnackBar('Da huy suat chieu');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Khong the huy suat chieu: $error', isError: true);
    }
  }

  Future<void> _deleteShowtime(ShowtimeSummaryResponse item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xoa suat chieu',
      message: 'Xoa "${item.movieTitle}" se khong the hoan tac.',
      confirmLabel: 'Xoa suat',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await _showtimeService.delete(item.id);
      if (!mounted) return;
      _showSnackBar('Da xoa suat chieu');
      _load();
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Khong the xoa suat chieu: $error', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }

  /// Mở dialog bộ lọc
  Future<void> _openFilterDialog() async {
    // Tạo bản sao tạm thời để edit trong dialog
    String? tmpMovieId = _movieId;
    String? tmpCinemaId = _cinemaId;
    String? tmpRoomId = _roomId;
    List<RoomResponse> tmpRooms = List.from(_rooms);
    Language? tmpLanguage = _language;
    ShowTimeStatus? tmpStatus = _status;
    DateTime? tmpDate = _date;
    bool tmpLoadingRooms = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> loadRoomsInDialog(String cinemaId) async {
              setDialogState(() => tmpLoadingRooms = true);
              try {
                final rooms = await _roomService.getByCinema(cinemaId, size: 100);
                setDialogState(() {
                  tmpRooms = rooms;
                  final stillExists = tmpRooms.any((r) => r.id == tmpRoomId);
                  if (!stillExists) tmpRoomId = null;
                  tmpLoadingRooms = false;
                });
              } catch (_) {
                setDialogState(() {
                  tmpRooms = const [];
                  tmpRoomId = null;
                  tmpLoadingRooms = false;
                });
              }
            }

            Future<void> pickDateInDialog() async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: tmpDate ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setDialogState(() => tmpDate = picked);
              }
            }

            Widget buildDropdown<T>({
              required String label,
              required T? value,
              required List<DropdownMenuItem<T?>> items,
              required ValueChanged<T?> onChanged,
            }) {
              return DropdownButtonFormField<T?>(
                initialValue: value,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                items: items,
                onChanged: onChanged,
              );
            }

            return Dialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bo loc suat chieu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  // Scrollable filter content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phim
                          buildDropdown<String>(
                            label: 'Phim',
                            value: tmpMovieId,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Tat ca phim',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ..._movies.map(
                                (movie) => DropdownMenuItem<String?>(
                                  value: movie.id,
                                  child: Text(
                                    movie.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => tmpMovieId = v),
                          ),
                          const SizedBox(height: 12),
                          // Rạp
                          buildDropdown<String>(
                            label: 'Rap',
                            value: tmpCinemaId,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Tat ca rap',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ..._cinemas.map(
                                (cinema) => DropdownMenuItem<String?>(
                                  value: cinema.id,
                                  child: Text(
                                    cinema.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setDialogState(() {
                                tmpCinemaId = v;
                                tmpRooms = const [];
                                tmpRoomId = null;
                              });
                              if (v != null && v.isNotEmpty) {
                                loadRoomsInDialog(v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          // Phòng
                          if (tmpLoadingRooms)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          else
                            buildDropdown<String>(
                              label: 'Phong',
                              value: tmpRoomId,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    'Tat ca phong',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ...tmpRooms.map(
                                  (room) => DropdownMenuItem<String?>(
                                    value: room.id,
                                    child: Text(
                                      room.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setDialogState(() => tmpRoomId = v),
                            ),
                          const SizedBox(height: 12),
                          // Ngôn ngữ
                          buildDropdown<Language>(
                            label: 'Ngon ngu',
                            value: tmpLanguage,
                            items: [
                              const DropdownMenuItem<Language?>(
                                value: null,
                                child: Text('Tat ca'),
                              ),
                              ...Language.values.map(
                                (language) => DropdownMenuItem<Language?>(
                                  value: language,
                                  child: Text(languageLabel(language)),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => tmpLanguage = v),
                          ),
                          const SizedBox(height: 12),
                          // Trạng thái
                          buildDropdown<ShowTimeStatus>(
                            label: 'Trang thai',
                            value: tmpStatus,
                            items: [
                              const DropdownMenuItem<ShowTimeStatus?>(
                                value: null,
                                child: Text('Tat ca'),
                              ),
                              ...ShowTimeStatus.values.map(
                                (status) => DropdownMenuItem<ShowTimeStatus?>(
                                  value: status,
                                  child: Text(showTimeStatusLabel(status)),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => tmpStatus = v),
                          ),
                          const SizedBox(height: 12),
                          // Ngày chiếu
                          InkWell(
                            onTap: pickDateInDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ngay chieu',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          tmpDate == null
                                              ? 'Chon ngay de loc'
                                              : DateFormat('dd/MM/yyyy')
                                                  .format(tmpDate!),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (tmpDate != null)
                                    GestureDetector(
                                      onTap: () =>
                                          setDialogState(() => tmpDate = null),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer buttons
                  const Divider(color: Colors.white12, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Reset
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _movieId = null;
                              _cinemaId = null;
                              _roomId = null;
                              _rooms = const [];
                              _language = null;
                              _status = null;
                              _date = null;
                              _page = 1;
                            });
                            _load();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          child: const Text('Xoa loc'),
                        ),
                        const SizedBox(width: 12),
                        // Apply
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _movieId = tmpMovieId;
                                _cinemaId = tmpCinemaId;
                                _roomId = tmpRoomId;
                                _rooms = tmpRooms;
                                _language = tmpLanguage;
                                _status = tmpStatus;
                                _date = tmpDate;
                                _page = 1;
                              });
                              _load();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Ap dung'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Suat chieu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _openCreatePage,
            icon: const Icon(Icons.add, color: AppColors.primary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePage,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar + Filter button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    onSubmitted: (value) {
                      setState(() {
                        _keyword = value.trim().isEmpty ? null : value.trim();
                        _page = 1;
                      });
                      _load();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tim theo ten phim, rap, phong...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: _keywordController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _keywordController.clear();
                                setState(() {
                                  _keyword = null;
                                  _page = 1;
                                });
                                _load();
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                              ),
                            ),
                      filled: true,
                      fillColor: AppColors.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeFilterCount > 0
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: IconButton(
                        onPressed: _openFilterDialog,
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: _activeFilterCount > 0
                              ? AppColors.primary
                              : Colors.white54,
                        ),
                        tooltip: 'Bo loc',
                      ),
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Active filter chips
          if (_activeFilterCount > 0)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (_movieId != null)
                    _filterChip(
                      label: _movies
                              .where((m) => m.id == _movieId)
                              .firstOrNull
                              ?.title ??
                          'Phim',
                      onRemove: () {
                        setState(() {
                          _movieId = null;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  if (_cinemaId != null)
                    _filterChip(
                      label: _cinemas
                              .where((c) => c.id == _cinemaId)
                              .firstOrNull
                              ?.name ??
                          'Rap',
                      onRemove: () {
                        setState(() {
                          _cinemaId = null;
                          _roomId = null;
                          _rooms = const [];
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  if (_roomId != null)
                    _filterChip(
                      label: _rooms
                              .where((r) => r.id == _roomId)
                              .firstOrNull
                              ?.name ??
                          'Phong',
                      onRemove: () {
                        setState(() {
                          _roomId = null;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  if (_language != null)
                    _filterChip(
                      label: languageLabel(_language!),
                      onRemove: () {
                        setState(() {
                          _language = null;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  if (_status != null)
                    _filterChip(
                      label: showTimeStatusLabel(_status!),
                      onRemove: () {
                        setState(() {
                          _status = null;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                  if (_date != null)
                    _filterChip(
                      label: DateFormat('dd/MM/yyyy').format(_date!),
                      onRemove: () {
                        setState(() {
                          _date = null;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                ],
              ),
            ),
          // Count row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '$_totalElements suat chieu',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                if (_loadingLookups)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              'Chua co suat chieu',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            itemBuilder: (_, index) {
                              final item = _items[index];
                              final statusColor = _statusColor(item.status);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: AppNetworkImage(
                                              url: item.posterUrl,
                                              width: 64,
                                              height: 88,
                                              fit: BoxFit.cover,
                                              fallbackIcon:
                                                  Icons.movie_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.movieTitle,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${item.cinemaName} • ${item.roomName}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDateTime(
                                                      item.startTime),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${item.durationMinutes} phut',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor
                                                  .withValues(alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              showTimeStatusLabel(item.status),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _pill(
                                            Icons.payments_outlined,
                                            NumberFormat.currency(
                                              locale: 'vi_VN',
                                              symbol: 'VND',
                                              decimalDigits: 0,
                                            ).format(item.basePrice),
                                            AppColors.secondary,
                                          ),
                                          _pill(
                                            Icons.translate_outlined,
                                            languageLabel(item.language),
                                            Colors.white70,
                                          ),
                                          _pill(
                                            Icons.event_seat_outlined,
                                            '${item.availableSeats} ghe trong',
                                            item.availableSeats > 0
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                          _pill(
                                            item.bookable
                                                ? Icons.lock_open_outlined
                                                : Icons.lock_outline,
                                            item.bookable
                                                ? 'Bookable'
                                                : 'Locked',
                                            item.bookable
                                                ? AppColors.success
                                                : Colors.orangeAccent,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _openEditPage(item),
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18),
                                            label: const Text('Chinh sua'),
                                          ),
                                          if (item.status !=
                                              ShowTimeStatus.CANCELLED)
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _cancelShowtime(item),
                                              icon: const Icon(
                                                  Icons.cancel_outlined,
                                                  size: 18),
                                              label: const Text('Huy suat'),
                                            ),
                                          IconButton(
                                            onPressed: () =>
                                                _deleteShowtime(item),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

Widget _filterChip({required String label, required VoidCallback onRemove}) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
      onDeleted: onRemove,
      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    ),
  );
}

Widget _pill(IconData icon, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 11)),
      ],
    ),
  );
}

Color _statusColor(ShowTimeStatus? status) {
  switch (status) {
    case ShowTimeStatus.SCHEDULED:
      return AppColors.secondary;
    case ShowTimeStatus.ONGOING:
      return AppColors.success;
    case ShowTimeStatus.FINISHED:
      return Colors.white54;
    case ShowTimeStatus.CANCELLED:
      return AppColors.error;
    default:
      return Colors.white54;
  }
}
