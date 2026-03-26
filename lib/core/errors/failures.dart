import 'package:equatable/equatable.dart';

/// Base Failure class for error handling (using dartz Either)
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Request timed out', super.statusCode = 408});
}

// Auth Failures
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Unauthorized. Please login again.', super.statusCode = 401});
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message = 'Access denied.', super.statusCode = 403});
}

// Data Failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found.', super.statusCode = 404});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({required super.message, this.errors, super.statusCode = 422});

  @override
  List<Object?> get props => [message, errors, statusCode];
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred.'});
}
