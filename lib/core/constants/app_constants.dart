import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// Core Constants - App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Cinema Booking';
  static const String appVersion = '1.0.0';

  // API Base URL — tự động chọn theo platform:
  //   • Web (Chrome)          → localhost:8081
  //   • Android Emulator      → 10.0.2.2:8081  (loopback alias → host machine)
  //   • iOS Simulator         → localhost:8081
  //   • Physical device       → đổi thành IP LAN của máy, vd: 192.168.1.x:8081
  static String get baseUrl {
    const port = '8081';
    const path = '/api/v1';

    if (kIsWeb) {
      return 'http://localhost:$port$path';
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 là địa chỉ đặc biệt của Android Emulator để kết nối về host PC
      return 'http://10.0.2.2:$port$path';
    }

    // iOS Simulator, macOS, Windows, Linux
    return 'http://localhost:$port$path';
  }

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
