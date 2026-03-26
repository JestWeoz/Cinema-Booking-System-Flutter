import 'package:equatable/equatable.dart';
import 'package:cinema_booking_system_app/features/movies/domain/entities/movie_entity.dart';

abstract class MovieState extends Equatable {
  const MovieState();

  @override
  List<Object?> get props => [];
}

class MovieInitial extends MovieState {
  const MovieInitial();
}

class MovieLoading extends MovieState {
  const MovieLoading();
}

class NowShowingLoaded extends MovieState {
  final List<MovieEntity> movies;
  final bool hasReachedMax;
  final int currentPage;

  const NowShowingLoaded({
    required this.movies,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [movies, hasReachedMax, currentPage];

  NowShowingLoaded copyWith({
    List<MovieEntity>? movies,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return NowShowingLoaded(
      movies: movies ?? this.movies,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ComingSoonLoaded extends MovieState {
  final List<MovieEntity> movies;
  final bool hasReachedMax;

  const ComingSoonLoaded({required this.movies, this.hasReachedMax = false});

  @override
  List<Object?> get props => [movies, hasReachedMax];
}

class MovieDetailLoaded extends MovieState {
  final MovieEntity movie;
  const MovieDetailLoaded(this.movie);

  @override
  List<Object?> get props => [movie];
}

class MovieSearchLoaded extends MovieState {
  final List<MovieEntity> results;
  final String query;

  const MovieSearchLoaded({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class MovieError extends MovieState {
  final String message;
  const MovieError(this.message);

  @override
  List<Object?> get props => [message];
}
