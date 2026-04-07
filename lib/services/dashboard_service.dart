import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

// ─── Dashboard Summary ────────────────────────────────────────────────────

class DashboardSummaryResponse {
  final double totalRevenue;
  final int totalTickets;
  final int totalUsers;
  final int totalShowtimes;

  const DashboardSummaryResponse({
    required this.totalRevenue,
    required this.totalTickets,
    required this.totalUsers,
    required this.totalShowtimes,
  });

  factory DashboardSummaryResponse.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryResponse(
        totalRevenue: _asDouble(
          json['totalRevenue'] ?? json['revenueToday'],
        ),
        totalTickets: _asInt(
          json['totalTickets'] ?? json['ticketsToday'],
        ),
        totalUsers: _asInt(
          json['totalUsers'] ?? json['usersToday'],
        ),
        totalShowtimes: _asInt(
          json['totalShowtimes'] ?? json['showtimeToday'],
        ),
      );
}

// ─── Revenue Chart ────────────────────────────────────────────────────────

class RevenueChartPoint {
  final String date;
  final double revenue;

  const RevenueChartPoint({required this.date, required this.revenue});

  factory RevenueChartPoint.fromJson(Map<String, dynamic> json) =>
      RevenueChartPoint(
        date: (json['date'] ?? '').toString(),
        revenue: _asDouble(json['revenue'] ?? json['value']),
      );
}

// ─── Statistics ────────────────────────────────────────────────────────────

class StatisticsSummaryResponse {
  final double totalRevenue;
  final int totalTickets;
  final int totalUsers;
  final int totalShowtimes;
  final int totalBookings;
  final int totalMovies;

  const StatisticsSummaryResponse({
    required this.totalRevenue,
    required this.totalTickets,
    required this.totalUsers,
    required this.totalShowtimes,
    required this.totalBookings,
    required this.totalMovies,
  });

  factory StatisticsSummaryResponse.fromJson(Map<String, dynamic> json) =>
      StatisticsSummaryResponse(
        totalRevenue: _asDouble(
          json['totalRevenue'] ?? json['revenueToday'],
        ),
        totalTickets: _asInt(
          json['totalTickets'] ?? json['ticketsToday'],
        ),
        totalUsers: _asInt(
          json['totalUsers'] ?? json['usersToday'],
        ),
        totalShowtimes: _asInt(
          json['totalShowtimes'] ?? json['showtimeToday'],
        ),
        totalBookings: _asInt(
          json['totalBookings'] ?? json['bookingsToday'] ?? json['bookingCount'],
        ),
        totalMovies: _asInt(
          json['totalMovies'] ?? json['moviesToday'] ?? json['movieCount'],
        ),
      );
}

class TicketChartPoint {
  final String date;
  final int ticketCount;

  const TicketChartPoint({required this.date, required this.ticketCount});

  factory TicketChartPoint.fromJson(Map<String, dynamic> json) =>
      TicketChartPoint(
        date: (json['date'] ?? '').toString(),
        ticketCount: _asInt(json['ticketCount'] ?? json['count']),
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
        movieTitle: json['movieTitle'] ?? json['movieName'] ?? '',
        posterUrl: json['posterUrl'] ?? json['imageUrl'],
        totalTickets: _asInt(json['totalTickets'] ?? json['tickets']),
        totalRevenue: _asDouble(json['totalRevenue'] ?? json['revenue']),
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
    required String from,
    required String to,
    String? cinemaId,
    String? movieId,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.summary,
      queryParameters: {
        'from': from,
        'to': to,
        if (cinemaId != null && cinemaId.isNotEmpty) 'cinemaId': cinemaId,
        if (movieId != null && movieId.isNotEmpty) 'movieId': movieId,
      },
    );
    final data = _unwrap(response.data) as Map<String, dynamic>;
    return StatisticsSummaryResponse.fromJson(data);
  }

  /// GET /dashboard/statistics/revenue-chart — Lấy biểu đồ doanh thu
  Future<List<RevenueChartPoint>> getStatisticsRevenueChart({
    required String from,
    required String to,
    String? cinemaId,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.revenueChart,
      queryParameters: {
        'from': from,
        'to': to,
        if (cinemaId != null && cinemaId.isNotEmpty) 'cinemaId': cinemaId,
      },
    );
    return _parseList(response.data, RevenueChartPoint.fromJson);
  }

  /// GET /dashboard/statistics/ticket-chart — Lấy biểu đồ vé bán ra
  Future<List<TicketChartPoint>> getTicketChart({
    required String from,
    required String to,
    String? cinemaId,
    String? movieId,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.ticketChart,
      queryParameters: {
        'from': from,
        'to': to,
        if (cinemaId != null && cinemaId.isNotEmpty) 'cinemaId': cinemaId,
        if (movieId != null && movieId.isNotEmpty) 'movieId': movieId,
      },
    );
    return _parseList(response.data, TicketChartPoint.fromJson);
  }

  /// GET /dashboard/statistics/top-movies — Lấy top phim
  Future<List<TopMovieResponse>> getTopMovies({
    required String from,
    required String to,
    String? cinemaId,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      StatisticsPaths.topMovies,
      queryParameters: {
        'from': from,
        'to': to,
        if (cinemaId != null && cinemaId.isNotEmpty) 'cinemaId': cinemaId,
        'limit': limit,
      },
    );
    return _parseList(response.data, TopMovieResponse.fromJson);
  }
}
