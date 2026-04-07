import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/models/responses/misc_responses.dart';
import 'package:cinema_booking_system_app/services/cinema_service.dart';
import 'package:cinema_booking_system_app/services/dashboard_service.dart';
import 'package:cinema_booking_system_app/shared/widgets/admin/app_table.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_shimmer.dart';

class AdminStatPage extends StatefulWidget {
  const AdminStatPage({super.key});

  @override
  State<AdminStatPage> createState() => _AdminStatPageState();
}

class _AdminStatPageState extends State<AdminStatPage> {
  final DashboardService _service = DashboardService.instance;
  final CinemaService _cinemaService = CinemaService.instance;
  final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );
  final NumberFormat _compact = NumberFormat.compact(locale: 'vi');

  bool _loading = true;
  String? _error;
  DateTimeRange? _range;
  StatisticsSummaryResponse? _summary;
  List<RevenueChartPoint> _revenue = const [];
  List<TicketChartPoint> _tickets = const [];
  List<TopMovieResponse> _topMovies = const [];
  List<CinemaResponse> _cinemas = const [];
  String? _cinemaId;

  @override
  void initState() {
    super.initState();
    _applyDefaultRange();
    _loadCinemas();
    _load();
  }

  void _applyDefaultRange() {
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> _loadCinemas() async {
    try {
      final cinemas = await _cinemaService.getAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _cinemas = cinemas;
      });
    } catch (_) {
      // Keep "all cinemas" option available even if cinema list fails to load.
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked == null) {
      return;
    }
    setState(() => _range = picked);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final from = _range == null ? '2000-01-01' : _isoDate(_range!.start);
      final to = _range == null ? _isoDate(DateTime.now()) : _isoDate(_range!.end);
      final results = await Future.wait<dynamic>([
        _service.getStatisticsSummary(
          from: from,
          to: to,
          cinemaId: _cinemaId,
        ),
        _service.getStatisticsRevenueChart(
          from: from,
          to: to,
          cinemaId: _cinemaId,
        ),
        _service.getTicketChart(
          from: from,
          to: to,
          cinemaId: _cinemaId,
        ),
        _service.getTopMovies(
          from: from,
          to: to,
          cinemaId: _cinemaId,
          limit: 10,
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = results[0] as StatisticsSummaryResponse;
        _revenue = results[1] as List<RevenueChartPoint>;
        _tickets = results[2] as List<TicketChartPoint>;
        _topMovies = results[3] as List<TopMovieResponse>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Không tải được thống kê: $error';
        _loading = false;
      });
    }
  }

  String _isoDate(DateTime value) => value.toIso8601String().split('T').first;

  String _formatRange() {
    if (_range == null) {
      return 'Toàn thời gian';
    }
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(_range!.start)} - ${formatter.format(_range!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Thống kê',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Chọn khoảng ngày',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              label: _formatRange(),
              cinemaLabel: _selectedCinemaLabel(),
            ),
            const SizedBox(height: 16),
            _CinemaFilterCard(
              cinemas: _cinemas,
              selectedCinemaId: _cinemaId,
              onChanged: (value) async {
                setState(() => _cinemaId = value);
                await _load();
              },
            ),
            const SizedBox(height: 16),
            if (_loading) ..._buildLoading()
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              _SummaryGrid(
                summary: _summary!,
                money: _money,
                compact: _compact,
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Doanh thu',
                subtitle: 'Biểu đồ doanh thu theo ngày',
                child: _RevenueChart(
                  points: _revenue,
                  money: _money,
                  useCompactDateFormat: _useCompactAxisDateFormat(),
                ),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Vé bán ra',
                subtitle: 'Sản lượng vé theo ngày',
                child: _TicketChart(
                  points: _tickets,
                  useCompactDateFormat: _useCompactAxisDateFormat(),
                ),
              ),
              const SizedBox(height: 16),
              _TopMoviesCard(
                movies: _topMovies,
                money: _money,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoading() {
    return [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          4,
          (_) => const SizedBox(
            width: 170,
            child: AppShimmer(width: 170, height: 104, borderRadius: 18),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const AppShimmer(width: double.infinity, height: 280, borderRadius: 18),
      const SizedBox(height: 16),
      const AppShimmer(width: double.infinity, height: 280, borderRadius: 18),
      const SizedBox(height: 16),
      const AppShimmer(width: double.infinity, height: 320, borderRadius: 18),
    ];
  }

  String _selectedCinemaLabel() {
    if (_cinemaId == null || _cinemaId!.isEmpty) {
      return 'Toàn bộ rạp';
    }
    for (final cinema in _cinemas) {
      if (cinema.id == _cinemaId) {
        return cinema.name;
      }
    }
    return 'Toàn bộ rạp';
  }

  bool _useCompactAxisDateFormat() {
    if (_range == null) {
      return true;
    }
    final days = _range!.end.difference(_range!.start).inDays + 1;
    return days > 30;
  }
}

class _HeaderCard extends StatelessWidget {
  final String label;
  final String cinemaLabel;

  const _HeaderCard({
    required this.label,
    required this.cinemaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B0B0C), Color(0xFF0D141F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Báo cáo quản trị',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cinemaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CinemaFilterCard extends StatelessWidget {
  final List<CinemaResponse> cinemas;
  final String? selectedCinemaId;
  final ValueChanged<String?> onChanged;

  const _CinemaFilterCard({
    required this.cinemas,
    required this.selectedCinemaId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonFormField<String?>(
        initialValue: selectedCinemaId,
        isExpanded: true,
        dropdownColor: AppColors.surfaceDark,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Rạp',
          prefixIcon: Icon(Icons.location_city_outlined),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Toàn bộ rạp', overflow: TextOverflow.ellipsis),
          ),
          ...cinemas.map(
            (cinema) => DropdownMenuItem<String?>(
              value: cinema.id,
              child: Text(cinema.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatisticsSummaryResponse summary;
  final NumberFormat money;
  final NumberFormat compact;

  const _SummaryGrid({
    required this.summary,
    required this.money,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Doanh thu',
        value: money.format(summary.totalRevenue),
        icon: Icons.attach_money_rounded,
        color: AppColors.secondary,
      ),
      _SummaryItem(
        label: 'Vé đã bán',
        value: compact.format(summary.totalTickets),
        icon: Icons.confirmation_number_outlined,
        color: AppColors.primary,
      ),
      _SummaryItem(
        label: 'Đơn đặt vé',
        value: compact.format(summary.totalBookings),
        icon: Icons.receipt_long_outlined,
        color: AppColors.info,
      ),
      _SummaryItem(
        label: 'Phim có doanh thu',
        value: compact.format(summary.totalMovies),
        icon: Icons.movie_outlined,
        color: AppColors.success,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _SummaryCard(item: item)).toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            item.color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(height: 18),
          Text(
            item.label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<RevenueChartPoint> points;
  final NumberFormat money;
  final bool useCompactDateFormat;

  const _RevenueChart({
    required this.points,
    required this.money,
    required this.useCompactDateFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _ChartEmpty(message: 'Chưa có dữ liệu doanh thu');
    }

    final spots = <FlSpot>[];
    for (var index = 0; index < points.length; index++) {
      spots.add(FlSpot(index.toDouble(), points[index].revenue));
    }

    final maxRevenue = points
        .map((point) => point.revenue)
        .fold<double>(0, (current, next) => next > current ? next : current);
    final labelStep = _xAxisLabelStep(points.length);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxRevenue == 0 ? 1 : maxRevenue * 1.2,
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxRevenue == 0 ? 1 : maxRevenue / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, _) => Text(
                money.format(value),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                if ((value - value.roundToDouble()).abs() > 0.001) {
                  return const SizedBox.shrink();
                }
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                if (index % labelStep != 0 && index != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatAxisDate(
                      points[index].date,
                      compact: useCompactDateFormat,
                    ),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceDark,
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    money.format(spot.y),
                    const TextStyle(color: Colors.white),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.secondary,
                strokeColor: Colors.black,
                strokeWidth: 1,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketChart extends StatelessWidget {
  final List<TicketChartPoint> points;
  final bool useCompactDateFormat;

  const _TicketChart({
    required this.points,
    required this.useCompactDateFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _ChartEmpty(message: 'Chưa có dữ liệu vé');
    }

    final maxTickets = points
        .map((point) => point.ticketCount.toDouble())
        .fold<double>(0, (current, next) => next > current ? next : current);
    final labelStep = _xAxisLabelStep(points.length);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxTickets == 0 ? 1 : maxTickets * 1.25,
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxTickets == 0 ? 1 : maxTickets / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep.toDouble(),
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                if ((value - value.roundToDouble()).abs() > 0.001) {
                  return const SizedBox.shrink();
                }
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                if (index % labelStep != 0 && index != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatAxisDate(
                      points[index].date,
                      compact: useCompactDateFormat,
                    ),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          points.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: points[index].ticketCount.toDouble(),
                width: 18,
                color: AppColors.info,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMoviesCard extends StatelessWidget {
  final List<TopMovieResponse> movies;
  final NumberFormat money;

  const _TopMoviesCard({
    required this.movies,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top phim',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Top phim theo doanh thu trong khoảng lọc',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          AppTable(
            columns: const [
              AppTableColumn(label: '#', width: FixedColumnWidth(50)),
              AppTableColumn(label: 'Phim', width: FlexColumnWidth(2.4)),
              AppTableColumn(label: 'Vé bán', width: FlexColumnWidth(1.2)),
              AppTableColumn(label: 'Doanh thu', width: FlexColumnWidth(1.6)),
            ],
            rows: List.generate(
              movies.length,
              (index) => AppTableRowData(
                cells: [
                  Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    movies[index].movieTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    movies[index].totalTickets.toString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    money.format(movies[index].totalRevenue),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            empty: const _ChartEmpty(message: 'Chưa có phim nào trong kỳ'),
          ),
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  final String message;

  const _ChartEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, color: Colors.white.withValues(alpha: 0.24), size: 40),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}

String _formatAxisDate(String raw, {bool compact = false}) {
  try {
    final date = DateTime.parse(raw);
    return DateFormat(compact ? 'MM/dd' : 'dd/MM').format(date);
  } catch (_) {
    return raw;
  }
}

int _xAxisLabelStep(int pointCount) {
  if (pointCount <= 1) {
    return 1;
  }
  const maxLabels = 6;
  return ((pointCount - 1) / (maxLabels - 1)).ceil();
}
