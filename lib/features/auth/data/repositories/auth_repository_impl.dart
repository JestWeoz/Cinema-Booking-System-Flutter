import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cinema_booking_system_app/core/constants/storage_keys.dart';
import 'package:cinema_booking_system_app/core/errors/failures.dart';
import 'package:cinema_booking_system_app/core/network/api_interceptor.dart';
import 'package:cinema_booking_system_app/features/auth/domain/entities/user_entity.dart';
import 'package:cinema_booking_system_app/features/auth/domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    FlutterSecureStorage? secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remoteDataSource.login(email: email, password: password);
      // Save tokens to secure storage
      await _secureStorage.write(
        key: StorageKeys.accessToken,
        value: data['access_token'] as String,
      );
      await _secureStorage.write(
        key: StorageKeys.refreshToken,
        value: data['refresh_token'] as String,
      );
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );
      await _secureStorage.write(
        key: StorageKeys.accessToken,
        value: data['access_token'] as String,
      );
      await _secureStorage.write(
        key: StorageKeys.refreshToken,
        value: data['refresh_token'] as String,
      );
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Even if API fails, clear tokens locally
    }
    await _secureStorage.deleteAll();
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on DioException catch (e) {
      return Left(dioExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }
}
