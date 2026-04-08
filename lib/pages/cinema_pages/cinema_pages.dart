import 'dart:async';

import 'package:cinema_booking_system_app/core/constants/app_routes.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_list_view.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_models.dart';
import 'package:cinema_booking_system_app/pages/cinema_pages/cinema_page_utils.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CinemaPages extends StatefulWidget {
  const CinemaPages({super.key});

  @override
  State<CinemaPages> createState() => _CinemaPagesState();
}

class _CinemaPagesState extends State<CinemaPages> {
  final CinemaService _cinemaService = CinemaService.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<CinemaResponse> _cinemas = const [];
  bool _loading = true;
  String? _error;
  String _keyword = '';
  String _selectedBrand = '__all__';

  @override
  void initState() {
    super.initState();
    _loadCinemas();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCinemas() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cinemas = await _cinemaService.getAll();
      cinemas.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) {
        return;
      }
      setState(() {
        _cinemas = cinemas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Không thể tải danh sách rạp.';
      });
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _keyword = value.trim().toLowerCase());
      }
    });
  }

  void _openCinema(CinemaResponse cinema) {
    context.push(AppRoutes.scheduleByCinemaId(cinema.id));
  }

  List<CinemaResponse> get _filteredCinemas {
    return _cinemas.where((cinema) {
      final brandMatches = _selectedBrand == '__all__' ||
          cinemaBrandOf(cinema) == _selectedBrand;
      final keyword = _keyword;
      final textMatches = keyword.isEmpty ||
          cinema.name.toLowerCase().contains(keyword) ||
          cinema.address.toLowerCase().contains(keyword);
      return brandMatches && textMatches;
    }).toList();
  }

  List<CinemaBrandItem> get _brands {
    final seen = <String>{};
    final items = <CinemaBrandItem>[
      const CinemaBrandItem(key: '__all__', label: 'Tất cả'),
    ];

    for (final cinema in _cinemas) {
      final brand = cinemaBrandOf(cinema);
      if (seen.add(brand)) {
        items.add(CinemaBrandItem(
          key: brand,
          label: brand,
          logoUrl: cinema.logoUrl,
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cinemaPageBackground,
      appBar: AppBar(
        backgroundColor: cinemaPageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Chọn theo rạp',
          style: TextStyle(
            color: cinemaPageText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: cinemaPageAccent),
      );
    }

    if (_error != null) {
      return CinemaStatusView(
        icon: Icons.error_outline_rounded,
        message: _error!,
        onRetry: _loadCinemas,
      );
    }

    return CinemaListView(
      searchController: _searchController,
      onSearchChanged: _handleSearchChanged,
      brands: _brands,
      selectedBrand: _selectedBrand,
      onBrandChanged: (value) => setState(() => _selectedBrand = value),
      cinemas: _filteredCinemas,
      onRefresh: _loadCinemas,
      onOpenCinema: _openCinema,
    );
  }
}
