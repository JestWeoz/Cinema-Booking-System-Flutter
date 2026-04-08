import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

class AdminShowtimeFormPage extends StatefulWidget {
  final String? showtimeId;

  const AdminShowtimeFormPage({
    super.key,
    this.showtimeId,
  });

  bool get isEdit => showtimeId != null && showtimeId!.isNotEmpty;

  @override
  State<AdminShowtimeFormPage> createState() => _AdminShowtimeFormPageState();
}

class _AdminShowtimeFormPageState extends State<AdminShowtimeFormPage> {
  final ShowtimeService _showtimeService = ShowtimeService.instance;
  final CinemaService _cinemaService = CinemaService.instance;
  final MovieService _movieService = MovieService.instance;
  final RoomService _roomService = RoomService.instance;
  final TextEditingController _priceController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<CinemaResponse> _cinemas = const [];
  List<MovieResponse> _movies = const [];
  List<RoomResponse> _rooms = const [];
  CinemaResponse? _selectedCinema;
  MovieResponse? _selectedMovie;
  RoomResponse? _selectedRoom;
  DateTime? _selectedDate;
  final List<TimeOfDay> _startTimes = [];
  Language _language = Language.ORIGINAL;
  ShowTimeStatus _status = ShowTimeStatus.SCHEDULED;
  bool _bulkMode = false;
  ShowtimeDetailResponse? _detail;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _cinemaService.getAll(keyword: null),
        _movieService.getAll(page: 1, size: 200),
        if (widget.isEdit) _showtimeService.getById(widget.showtimeId!),
      ]);

      final cinemas = results[0] as List<CinemaResponse>;
      final movies = (results[1] as dynamic).content as List<MovieResponse>;
      ShowtimeDetailResponse? detail;
      if (widget.isEdit) {
        detail = results[2] as ShowtimeDetailResponse;
      }

      List<RoomResponse> rooms = const [];
      CinemaResponse? selectedCinema;
      MovieResponse? selectedMovie;
      RoomResponse? selectedRoom;
      DateTime? selectedDate;
      final startTimes = <TimeOfDay>[];

      if (detail != null) {
        selectedCinema = cinemas.cast<CinemaResponse?>().firstWhere(
              (cinema) => cinema?.id == detail!.cinemaId,
              orElse: () => null,
            );
        selectedMovie = movies.cast<MovieResponse?>().firstWhere(
              (movie) => movie?.id == detail!.movieId,
              orElse: () => null,
            );
        rooms = await _roomService.getByCinema(detail.cinemaId, size: 100);
        selectedRoom = rooms.cast<RoomResponse?>().firstWhere(
              (room) => room?.id == detail!.roomId,
              orElse: () => null,
            );
        final startAt = DateTime.tryParse(detail.startTime);
        if (startAt != null) {
          selectedDate = DateTime(startAt.year, startAt.month, startAt.day);
          startTimes.add(TimeOfDay(hour: startAt.hour, minute: startAt.minute));
        }
      }

      if (!mounted) return;
      setState(() {
        _cinemas = cinemas;
        _movies = movies;
        _detail = detail;
        _selectedCinema = selectedCinema;
        _selectedMovie = selectedMovie;
        _rooms = rooms;
        _selectedRoom = selectedRoom;
        _selectedDate = selectedDate;
        _startTimes
          ..clear()
          ..addAll(startTimes);
        _priceController.text = detail?.basePrice.toStringAsFixed(0) ?? '';
        _language = detail?.language ?? Language.ORIGINAL;
        _status = detail?.status ?? ShowTimeStatus.SCHEDULED;
        _bulkMode = false;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Khong tai duoc du lieu form: $error';
      });
    }
  }

  Future<void> _loadRooms(String cinemaId) async {
    try {
      final rooms = await _roomService.getByCinema(cinemaId, size: 100);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        final stillExists = rooms.any((room) => room.id == _selectedRoom?.id);
        if (!stillExists) {
          _selectedRoom = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _rooms = const [];
        _selectedRoom = null;
        _error = 'Khong tai duoc danh sach phong: $error';
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _addTime() async {
    final initialTime = _startTimes.isNotEmpty
        ? _startTimes.last
        : TimeOfDay.fromDateTime(
            DateTime.now().add(const Duration(hours: 1)),
          );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceDark,
              onSurface: Colors.white,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.surfaceDark,
              hourMinuteColor: AppColors.cardDark,
              hourMinuteTextColor: Colors.white,
              dayPeriodColor: AppColors.cardDark,
              dayPeriodTextColor: Colors.white,
              dialBackgroundColor: AppColors.cardDark,
              dialHandColor: AppColors.primary,
              dialTextColor: Colors.white,
              entryModeIconColor: Colors.white70,
              helpTextStyle: TextStyle(color: Colors.white70),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;

    final exists = _startTimes.any(
      (time) => time.hour == picked.hour && time.minute == picked.minute,
    );
    if (exists) {
      setState(() => _error = 'Khung gio nay da ton tai trong danh sach.');
      return;
    }

    setState(() {
      if (widget.isEdit || !_bulkMode) {
        _startTimes
          ..clear()
          ..add(picked);
      } else {
        _startTimes.add(picked);
        _startTimes.sort(_compareTime);
      }
      _error = null;
    });
  }

  int _compareTime(TimeOfDay left, TimeOfDay right) {
    final leftMinutes = left.hour * 60 + left.minute;
    final rightMinutes = right.hour * 60 + right.minute;
    return leftMinutes.compareTo(rightMinutes);
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String? _validateForm() {
    if (!widget.isEdit && _selectedMovie == null) {
      return 'Vui long chon phim.';
    }
    if (_selectedCinema == null) {
      return 'Vui long chon rap.';
    }
    if (_selectedRoom == null) {
      return 'Vui long chon phong.';
    }
    if (_selectedDate == null) {
      return 'Vui long chon ngay chieu.';
    }
    if (_startTimes.isEmpty) {
      return widget.isEdit
          ? 'Vui long chon gio chieu.'
          : 'Vui long them it nhat mot gio chieu.';
    }
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      return 'Gia ve phai lon hon 0.';
    }

    final now = DateTime.now();
    for (final time in _startTimes) {
      final startAt = _combineDateTime(_selectedDate!, time);
      if (startAt.isBefore(now)) {
        return 'Khong the tao hoac cap nhat suat chieu trong qua khu.';
      }
    }
    return null;
  }

  Future<String?> _validateOverlaps() async {
    if (_selectedDate == null || _selectedRoom == null) {
      return null;
    }

    final durationMinutes = widget.isEdit
        ? (_detail?.durationMinutes ?? 0)
        : (_selectedMovie?.duration ?? 0);

    if (durationMinutes <= 0) {
      return null;
    }

    final existing = await _showtimeService.getPaginated(
      filter: ShowtimeFilterRequest(
        roomId: _selectedRoom!.id,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        page: 1,
        size: 200,
      ),
    );

    final selectedStartTimes = _startTimes
        .map((time) => _combineDateTime(_selectedDate!, time))
        .toList()
      ..sort();

    for (int i = 0; i < selectedStartTimes.length; i++) {
      final currentStart = selectedStartTimes[i];
      final currentEnd = currentStart.add(Duration(minutes: durationMinutes));

      for (int j = i + 1; j < selectedStartTimes.length; j++) {
        final nextStart = selectedStartTimes[j];
        if (nextStart.isBefore(currentEnd)) {
          return 'Danh sach gio tao hang loat dang bi trung nhau.';
        }
      }

      for (final item in existing.content) {
        if (widget.isEdit && item.id == widget.showtimeId) {
          continue;
        }
        final existingStart = DateTime.tryParse(item.startTime);
        final existingEnd = DateTime.tryParse(item.endTime);
        if (existingStart == null || existingEnd == null) {
          continue;
        }

        final overlaps = currentStart.isBefore(existingEnd) &&
            currentEnd.isAfter(existingStart);
        if (overlaps) {
          return 'Phong da co suat trung gio ${DateFormat('HH:mm').format(currentStart)}.';
        }
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final validation = _validateForm();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final overlapError = await _validateOverlaps();
      if (overlapError != null) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = overlapError;
        });
        return;
      }

      final basePrice = double.parse(_priceController.text.trim());

      if (widget.isEdit) {
        final startAt = _combineDateTime(_selectedDate!, _startTimes.first);
        await _showtimeService.update(
          widget.showtimeId!,
          UpdateShowtimeRequest(
            roomId: _selectedRoom!.id,
            startTime: startAt.toIso8601String(),
            basePrice: basePrice,
            language: _language.name,
            status: showTimeStatusToApi(_status),
          ),
        );
      } else {
        final requests = _startTimes
            .map(
              (time) => CreateShowtimeRequest(
                movieId: _selectedMovie!.id,
                roomId: _selectedRoom!.id,
                startTime:
                    _combineDateTime(_selectedDate!, time).toIso8601String(),
                basePrice: basePrice,
                language: _language.name,
              ),
            )
            .toList();
        await _showtimeService.createMany(requests);
      }

      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Khong the luu suat chieu: $error';
      });
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          widget.isEdit ? 'Chinh sua suat chieu' : 'Tao suat chieu',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isEdit)
                    SwitchListTile(
                      value: _bulkMode,
                      onChanged: (value) => setState(() {
                        _bulkMode = value;
                        if (!value && _startTimes.length > 1) {
                          final first = _startTimes.first;
                          _startTimes
                            ..clear()
                            ..add(first);
                        }
                      }),
                      activeThumbColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Tao nhieu suat trong cung ngay',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Ban co the them nhieu gio bat dau roi luu mot lan.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  if (!widget.isEdit) const SizedBox(height: 12),
                  _buildDropdown<MovieResponse>(
                    label: 'Phim',
                    value: _selectedMovie,
                    items: _movies
                        .map(
                          (movie) => DropdownMenuItem<MovieResponse>(
                            value: movie,
                            child: Text(
                              '${movie.title} • ${movie.duration} phut',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: widget.isEdit
                        ? null
                        : (movie) {
                            setState(() => _selectedMovie = movie);
                          },
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<CinemaResponse>(
                    label: 'Rap',
                    value: _selectedCinema,
                    items: _cinemas
                        .map(
                          (cinema) => DropdownMenuItem<CinemaResponse>(
                            value: cinema,
                            child: Text(cinema.name,
                                overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (cinema) async {
                      if (cinema == null) return;
                      setState(() {
                        _selectedCinema = cinema;
                        _selectedRoom = null;
                        _rooms = const [];
                      });
                      await _loadRooms(cinema.id);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<RoomResponse>(
                    label: 'Phong',
                    value: _selectedRoom,
                    items: _rooms
                        .map(
                          (room) => DropdownMenuItem<RoomResponse>(
                            value: room,
                            child: Text(
                              '${room.name} • ${roomTypeLabel(room.roomType)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (room) {
                      setState(() => _selectedRoom = room);
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngay chieu',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Chon ngay chieu'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gio chieu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_startTimes.isEmpty)
                                const Text(
                                  'Chua co gio nao duoc chon.',
                                  style: TextStyle(color: Colors.white54),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _startTimes
                                      .map(
                                        (time) => InputChip(
                                          label: Text(
                                            time.format(context),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          backgroundColor:
                                              AppColors.surfaceDark,
                                          selectedColor: AppColors.surfaceDark,
                                          disabledColor: AppColors.surfaceDark,
                                          deleteIconColor: Colors.white70,
                                          side: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.14),
                                          ),
                                          onDeleted: widget.isEdit &&
                                                  _startTimes.length == 1
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _startTimes.removeWhere(
                                                      (item) =>
                                                          item.hour ==
                                                              time.hour &&
                                                          item.minute ==
                                                              time.minute,
                                                    );
                                                  });
                                                },
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _addTime,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(widget.isEdit || !_bulkMode
                              ? 'Chon gio'
                              : 'Them gio'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Gia ve co ban',
                      suffixText: 'VND',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<Language>(
                    label: 'Ngon ngu',
                    value: _language,
                    items: Language.values
                        .map(
                          (language) => DropdownMenuItem<Language>(
                            value: language,
                            child: Text(languageLabel(language)),
                          ),
                        )
                        .toList(),
                    onChanged: (language) {
                      if (language != null) {
                        setState(() => _language = language);
                      }
                    },
                  ),
                  if (widget.isEdit) ...[
                    const SizedBox(height: 12),
                    _buildDropdown<ShowTimeStatus>(
                      label: 'Trang thai',
                      value: _status,
                      items: ShowTimeStatus.values
                          .map(
                            (status) => DropdownMenuItem<ShowTimeStatus>(
                              value: status,
                              child: Text(showTimeStatusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (status) {
                        if (status != null) {
                          setState(() => _status = status);
                        }
                      },
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEdit
                                  ? 'Luu thay doi'
                                  : _bulkMode
                                      ? 'Tao nhieu suat chieu'
                                      : 'Tao suat chieu',
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
