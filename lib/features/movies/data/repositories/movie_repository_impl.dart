import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:cinema_booking_system_app/core/errors/failures.dart';
import 'package:cinema_booking_system_app/core/network/api_interceptor.dart';
import 'package:cinema_booking_system_app/features/movies/domain/entities/movie_entity.dart';
import 'package:cinema_booking_system_app/features/movies/domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource _remoteDataSource;

  MovieRepositoryImpl({required MovieRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<MovieEntity>>> getNowShowing({int page = 1}) async {
    try {
      final movies = await _remoteDataSource.getNowShowing(page: page);
      return Right(movies);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MovieEntity>>> getComingSoon({int page = 1}) async {
    try {
      final movies = await _remoteDataSource.getComingSoon(page: page);
      return Right(movies);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MovieEntity>> getMovieById(String id) async {
    try {
      final movie = await _remoteDataSource.getMovieById(id);
      return Right(movie);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MovieEntity>>> searchMovies(String query) async {
    try {
      final movies = await _remoteDataSource.searchMovies(query);
      return Right(movies);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
