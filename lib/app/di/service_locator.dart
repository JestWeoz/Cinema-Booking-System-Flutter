import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core
import 'package:cinema_booking_system_app/core/network/dio_client.dart';

// Auth
import 'package:cinema_booking_system_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cinema_booking_system_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cinema_booking_system_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:cinema_booking_system_app/features/auth/presentation/bloc/auth_bloc.dart';

// Movies
import 'package:cinema_booking_system_app/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:cinema_booking_system_app/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:cinema_booking_system_app/features/movies/domain/repositories/movie_repository.dart';
import 'package:cinema_booking_system_app/features/movies/presentation/bloc/movie_bloc.dart';

// Booking
import 'package:cinema_booking_system_app/features/booking/data/datasources/booking_remote_data_source.dart';
import 'package:cinema_booking_system_app/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:cinema_booking_system_app/features/booking/domain/repositories/booking_repository.dart';
import 'package:cinema_booking_system_app/features/booking/presentation/bloc/booking_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Core ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<Dio>(() => DioClient.instance);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ─── Auth ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
    ),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl()),
  );

  // ─── Movies ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MovieRemoteDataSource>(
    () => MovieRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<MovieBloc>(
    () => MovieBloc(movieRepository: sl()),
  );

  // ─── Booking ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<BookingBloc>(
    () => BookingBloc(bookingRepository: sl()),
  );
}
