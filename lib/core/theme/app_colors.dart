import 'package:flutter/material.dart';

/// App Color Palette
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFFE50914); // Netflix-style red
  static const Color primaryDark = Color(0xFFB20710);
  static const Color primaryLight = Color(0xFFFF3D3D);

  static const Color secondary = Color(0xFFFFC107); // Gold accent
  static const Color secondaryDark = Color(0xFFE5A800);

  // Background Dark Theme
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color dividerDark = Color(0xFF2C2C2C);

  // Background Light Theme
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textHintDark = Color(0xFF666666);

  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF555555);
  static const Color textHintLight = Color(0xFF999999);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Seat Colors
  static const Color seatAvailable = Color(0xFF2C2C2C);
  static const Color seatSelected = Color(0xFFE50914);
  static const Color seatBooked = Color(0xFF555555);
  static const Color seatVip = Color(0xFFFFD700);
  static const Color seatCouple = Color(0xFFFF69B4);
}
