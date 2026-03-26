import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinema_booking_system_app/features/movies/domain/repositories/movie_repository.dart';
import 'movie_event.dart';
import 'movie_state.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final MovieRepository _movieRepository;

  MovieBloc({required MovieRepository movieRepository})
      : _movieRepository = movieRepository,
        super(const MovieInitial()) {
    on<LoadNowShowing>(_onLoadNowShowing);
    on<LoadComingSoon>(_onLoadComingSoon);
    on<LoadMovieDetail>(_onLoadMovieDetail);
    on<SearchMovies>(_onSearchMovies);
    on<ClearMovieSearch>(_onClearMovieSearch);
  }

  Future<void> _onLoadNowShowing(
    LoadNowShowing event,
    Emitter<MovieState> emit,
  ) async {
    // Avoid fetching if already have data and request is page 1 (refresh)
    if (event.page == 1) emit(const MovieLoading());

    final result = await _movieRepository.getNowShowing(page: event.page);
    result.fold(
      (failure) => emit(MovieError(failure.message)),
      (movies) {
        if (state is NowShowingLoaded && event.page > 1) {
          final current = state as NowShowingLoaded;
          emit(current.copyWith(
            movies: [...current.movies, ...movies],
            hasReachedMax: movies.isEmpty,
            currentPage: event.page,
          ));
        } else {
          emit(NowShowingLoaded(
            movies: movies,
            hasReachedMax: movies.isEmpty,
            currentPage: event.page,
          ));
        }
      },
    );
  }

  Future<void> _onLoadComingSoon(
    LoadComingSoon event,
    Emitter<MovieState> emit,
  ) async {
    emit(const MovieLoading());
    final result = await _movieRepository.getComingSoon(page: event.page);
    result.fold(
      (failure) => emit(MovieError(failure.message)),
      (movies) => emit(ComingSoonLoaded(movies: movies)),
    );
  }

  Future<void> _onLoadMovieDetail(
    LoadMovieDetail event,
    Emitter<MovieState> emit,
  ) async {
    emit(const MovieLoading());
    final result = await _movieRepository.getMovieById(event.movieId);
    result.fold(
      (failure) => emit(MovieError(failure.message)),
      (movie) => emit(MovieDetailLoaded(movie)),
    );
  }

  Future<void> _onSearchMovies(
    SearchMovies event,
    Emitter<MovieState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const MovieInitial());
      return;
    }
    emit(const MovieLoading());
    final result = await _movieRepository.searchMovies(event.query);
    result.fold(
      (failure) => emit(MovieError(failure.message)),
      (movies) => emit(MovieSearchLoaded(results: movies, query: event.query)),
    );
  }

  void _onClearMovieSearch(ClearMovieSearch event, Emitter<MovieState> emit) {
    emit(const MovieInitial());
  }
}
