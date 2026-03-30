// Core Constants - App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Cinema Booking';
  static const String appVersion = '1.0.0';

  // API
  // Change this to your machine IP when running on physical device
  // e.g. 'http://192.168.1.x:8081/api/v1'
  static const String baseUrl = 'http://localhost:8081/api/v1'; // Android emulator → localhost
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int pageSize = 10;

  // Cache durations
  static const int cacheDurationMinutes = 30;

  // Seat types
  static const String seatTypeStandard = 'standard';
  static const String seatTypeVip = 'vip';
  static const String seatTypeCouple = 'couple';
}
