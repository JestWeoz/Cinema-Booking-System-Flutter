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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _page = 1;
    });
    _load();
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

  Widget _buildFilterDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T?>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: (newValue) {
        onChanged(newValue);
        setState(() => _page = 1);
        _load();
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
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
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useTwoColumns = constraints.maxWidth >= 640;
                    final children = <Widget>[
                      _buildFilterDropdown<String>(
                        value: _movieId,
                        label: 'Phim',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tat ca phim', overflow: TextOverflow.ellipsis),
                          ),
                          ..._movies.map(
                            (movie) => DropdownMenuItem<String?>(
                              value: movie.id,
                              child: Text(movie.title, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (value) => _movieId = value,
                      ),
                      _buildFilterDropdown<String>(
                        value: _cinemaId,
                        label: 'Rap',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tat ca rap', overflow: TextOverflow.ellipsis),
                          ),
                          ..._cinemas.map(
                            (cinema) => DropdownMenuItem<String?>(
                              value: cinema.id,
                              child: Text(cinema.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          _cinemaId = value;
                          _rooms = const [];
                          _roomId = null;
                          if (value != null && value.isNotEmpty) {
                            _loadRooms(value);
                          }
                        },
                      ),
                      _buildFilterDropdown<String>(
                        value: _roomId,
                        label: 'Phong',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tat ca phong', overflow: TextOverflow.ellipsis),
                          ),
                          ..._rooms.map(
                            (room) => DropdownMenuItem<String?>(
                              value: room.id,
                              child: Text(room.name, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (value) => _roomId = value,
                      ),
                      _buildFilterDropdown<Language>(
                        value: _language,
                        label: 'Ngon ngu',
                        items: [
                          const DropdownMenuItem<Language?>(
                            value: null,
                            child: Text('Tat ca', overflow: TextOverflow.ellipsis),
                          ),
                          ...Language.values.map(
                            (language) => DropdownMenuItem<Language?>(
                              value: language,
                              child: Text(languageLabel(language)),
                            ),
                          ),
                        ],
                        onChanged: (value) => _language = value,
                      ),
                      _buildFilterDropdown<ShowTimeStatus>(
                        value: _status,
                        label: 'Trang thai',
                        items: [
                          const DropdownMenuItem<ShowTimeStatus?>(
                            value: null,
                            child: Text('Tat ca', overflow: TextOverflow.ellipsis),
                          ),
                          ...ShowTimeStatus.values.map(
                            (status) => DropdownMenuItem<ShowTimeStatus?>(
                              value: status,
                              child: Text(showTimeStatusLabel(status)),
                            ),
                          ),
                        ],
                        onChanged: (value) => _status = value,
                      ),
                    ];

                    if (!useTwoColumns) {
                      return Column(
                        children: [
                          for (int index = 0; index < children.length; index++) ...[
                            children[index],
                            if (index != children.length - 1) const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: children
                          .map(
                            (child) => SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: child,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngay chieu',
                      suffixIcon: _date == null
                          ? const Icon(Icons.calendar_today_outlined)
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  _date = null;
                                  _page = 1;
                                });
                                _load();
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                    child: Text(
                      _date == null
                          ? 'Chon ngay de loc'
                          : DateFormat('dd/MM/yyyy').format(_date!),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 8),
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
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: AppNetworkImage(
                                              url: item.posterUrl,
                                              width: 64,
                                              height: 88,
                                              fit: BoxFit.cover,
                                              fallbackIcon: Icons.movie_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  _formatDateTime(item.startTime),
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
                                              color: statusColor.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(999),
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
                                            item.bookable ? 'Bookable' : 'Locked',
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
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _openEditPage(item),
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            label: const Text('Chinh sua'),
                                          ),
                                          if (item.status != ShowTimeStatus.CANCELLED)
                                            OutlinedButton.icon(
                                              onPressed: () => _cancelShowtime(item),
                                              icon: const Icon(Icons.cancel_outlined, size: 18),
                                              label: const Text('Huy suat'),
                                            ),
                                          IconButton(
                                            onPressed: () => _deleteShowtime(item),
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
