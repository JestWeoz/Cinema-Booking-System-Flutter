import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';

// ─── Dashboard Summary ────────────────────────────────────────────────────

class DashboardSummaryResponse {
  final int totalUsers;
  final int totalMovies;
  final int totalBookings;
  final double totalRevenue;
  final int totalCinemas;
  final int pendingBookings;

  const DashboardSummaryResponse({
    required this.totalUsers,
    required this.totalMovies,
    required this.totalBookings,
    required this.totalRevenue,
    required this.totalCinemas,
    required this.pendingBookings,
  });

  factory DashboardSummaryResponse.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryResponse(
        totalUsers: json['totalUsers'] ?? 0,
        totalMovies: json['totalMovies'] ?? 0,
        totalBookings: json['totalBookings'] ?? 0,
        totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
        totalCinemas: json['totalCinemas'] ?? 0,
        pendingBookings: json['pendingBookings'] ?? 0,
      );
}

// ─── Revenue Chart ────────────────────────────────────────────────────────

class RevenueChartPoint {
  final String date;
  final double revenue;

  const RevenueChartPoint({required this.date, required this.revenue});

  factory RevenueChartPoint.fromJson(Map<String, dynamic> json) =>
      RevenueChartPoint(
        date: json['date'] ?? '',
        revenue: (json['revenue'] ?? 0).toDouble(),
      );
}

// ─── Statistics ────────────────────────────────────────────────────────────

class StatisticsSummaryResponse {
  final double totalRevenue;
  final int totalTickets;
  final int totalBookings;
  final int totalMovies;

  const StatisticsSummaryResponse({
    required this.totalRevenue,
    required this.totalTickets,
    required this.totalBookings,
    required this.totalMovies,
  });

  factory StatisticsSummaryResponse.fromJson(Map<String, dynamic> json) =>
      StatisticsSummaryResponse(
        totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
        totalTickets: json['totalTickets'] ?? 0,
        totalBookings: json['totalBookings'] ?? 0,
        totalMovies: json['totalMovies'] ?? 0,
      );
}

class TicketChartPoint {
  final String date;
  final int ticketCount;

  const TicketChartPoint({required this.date, required this.ticketCount});

  factory TicketChartPoint.fromJson(Map<String, dynamic> json) =>
      TicketChartPoint(
        date: json['date'] ?? '',
        ticketCount: json['ticketCount'] ?? 0,
      );
}

class TopMovieResponse {
  final String movieId;
  final String movieTitle;
  final String? posterUrl;
  final int totalTickets;
  final double totalRevenue;

  const TopMovieResponse({
    required this.movieId,
    required this.movieTitle,
    this.posterUrl,
    required this.totalTickets,
    required this.totalRevenue,
  });

  factory TopMovieResponse.fromJson(Map<String, dynamic> json) =>
      TopMovieResponse(
        movieId: json['movieId'] ?? '',
        movieTitle: json['movieTitle'] ?? '',
        posterUrl: json['posterUrl'],
        totalTickets: json['totalTickets'] ?? 0,
        totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      );
}

// ─── Service ──────────────────────────────────────────────────────────────

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  final Dio _dio = DioClient.instance;

  dynamic _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] != null) return raw['data'];
    return raw;
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ─── Dashboard (Admin Dashboard) ─────────────────────────────────────────

  /// GET /dashboard/summary — Lấy tổng quan dashboard
  Future<DashboardSummaryResponse> getSummary() async {
    final response = await _dio.get(DashboardPaths.summary);
    final data = _unwrap(response.data) as Map<String, dynamic>;
    return DashboardSummaryResponse.fromJson(data);
  }

  /// GET /dashboard/revenue-chart — Lấy biểu đồ doanh thu 7 ngày
  Future<List<RevenueChartPoint>> getRevenueChart() async {
    final response = await _dio.get(DashboardPaths.revenueChart);
    return _parseList(response.data, RevenueChartPoint.fromJson);
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  /// GET /dashboard/statistics/summary — Lấy tổng quan thống kê
  Future<StatisticsSummaryResponse> getStatisticsSummary({
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.summary,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    final data = _unwrap(response.data) as Map<String, dynamic>;
    return StatisticsSummaryResponse.fromJson(data);
  }

  /// GET /dashboard/statistics/revenue-chart — Lấy biểu đồ doanh thu
  Future<List<RevenueChartPoint>> getStatisticsRevenueChart({
    String? startDate,
    String? endDate,
    String? groupBy, // DAY, WEEK, MONTH
  }) async {
    final response = await _dio.get(
      StatisticsPaths.revenueChart,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (groupBy != null) 'groupBy': groupBy,
      },
    );
    return _parseList(response.data, RevenueChartPoint.fromJson);
  }

  /// GET /dashboard/statistics/ticket-chart — Lấy biểu đồ vé bán ra
  Future<List<TicketChartPoint>> getTicketChart({
    String? startDate,
    String? endDate,
    String? groupBy,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.ticketChart,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (groupBy != null) 'groupBy': groupBy,
      },
    );
    return _parseList(response.data, TicketChartPoint.fromJson);
  }

  /// GET /dashboard/statistics/top-movies — Lấy top phim
  Future<List<TopMovieResponse>> getTopMovies({
    String? startDate,
    String? endDate,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.topMovies,
      queryParameters: {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'limit': limit,
      },
    );
    return _parseList(response.data, TopMovieResponse.fromJson);
  }
}
