import 'package:dartz/dartz.dart';
import 'package:cinema_booking_system_app/core/errors/failures.dart';
import '../entities/movie_entity.dart';

abstract class MovieRepository {
  Future<Either<Failure, List<MovieEntity>>> getNowShowing({int page = 1});
  Future<Either<Failure, List<MovieEntity>>> getComingSoon({int page = 1});
  Future<Either<Failure, MovieEntity>> getMovieById(String id);
  Future<Either<Failure, List<MovieEntity>>> searchMovies(String query);
}
