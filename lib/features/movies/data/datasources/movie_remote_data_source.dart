import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/constants/api_paths.dart';
import 'package:cinema_booking_system_app/features/movies/data/models/movie_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getNowShowing({int page = 1});
  Future<List<MovieModel>> getComingSoon({int page = 1});
  Future<MovieModel> getMovieById(String id);
  Future<List<MovieModel>> searchMovies(String query);
  Future<List<MovieModel>> getRecommended();
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final Dio _dio;

  MovieRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  List<MovieModel> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Spring Boot often wraps in { content: [...] } for Page responses
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<MovieModel>> getNowShowing({int page = 1}) async {
    final response = await _dio.get(
      MoviePaths.nowShowing,
      queryParameters: {'page': page - 1, 'size': 10},
    );
    return _parseList(response.data);
  }

  @override
  Future<List<MovieModel>> getComingSoon({int page = 1}) async {
    final response = await _dio.get(
      MoviePaths.comingSoon,
      queryParameters: {'page': page - 1, 'size': 10},
    );
    return _parseList(response.data);
  }

  @override
  Future<MovieModel> getMovieById(String id) async {
    final response = await _dio.get(MoviePaths.byId(id));
    return MovieModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<MovieModel>> searchMovies(String query) async {
    final response = await _dio.get(
      MoviePaths.search,
      queryParameters: {'q': query, 'keyword': query},
    );
    return _parseList(response.data);
  }

  @override
  Future<List<MovieModel>> getRecommended() async {
    final response = await _dio.get(MoviePaths.recommended);
    return _parseList(response.data);
  }
}
