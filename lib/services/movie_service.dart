import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/network/dio_client.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/models/movie_model.dart';

class MovieService {
  MovieService._();
  static final MovieService instance = MovieService._();

  final Dio _dio = DioClient.instance;

  List<MovieModel> _parseList(dynamic data) {
    if (data is List) {
      return data.map((e) => MovieModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Phim đang chiếu
  Future<List<MovieModel>> getNowShowing({int page = 1}) async {
    final response = await _dio.get(
      MoviePaths.nowShowing,
      queryParameters: {'page': page - 1, 'size': 10},
    );
    return _parseList(response.data);
  }

  /// Phim sắp chiếu
  Future<List<MovieModel>> getComingSoon({int page = 1}) async {
    final response = await _dio.get(
      MoviePaths.comingSoon,
      queryParameters: {'page': page - 1, 'size': 10},
    );
    return _parseList(response.data);
  }

  /// Chi tiết phim theo ID
  Future<MovieModel> getById(String id) async {
    final response = await _dio.get(MoviePaths.byId(id));
    return MovieModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Tìm kiếm phim
  Future<List<MovieModel>> search(String query) async {
    final response = await _dio.get(
      MoviePaths.searchByKeyword(query),
      queryParameters: {'page': 0, 'size': 10},
    );
    return _parseList(response.data);
  }

  /// Phim đề xuất
  Future<List<MovieModel>> getRecommended() async {
    final response = await _dio.get(MoviePaths.recommended);
    return _parseList(response.data);
  }
}
