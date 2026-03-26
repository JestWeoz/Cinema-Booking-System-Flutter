import 'package:equatable/equatable.dart';

abstract class MovieEvent extends Equatable {
  const MovieEvent();

  @override
  List<Object?> get props => [];
}

class LoadNowShowing extends MovieEvent {
  final int page;
  const LoadNowShowing({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class LoadComingSoon extends MovieEvent {
  final int page;
  const LoadComingSoon({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class LoadMovieDetail extends MovieEvent {
  final String movieId;
  const LoadMovieDetail(this.movieId);

  @override
  List<Object?> get props => [movieId];
}

class SearchMovies extends MovieEvent {
  final String query;
  const SearchMovies(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearMovieSearch extends MovieEvent {
  const ClearMovieSearch();
}
