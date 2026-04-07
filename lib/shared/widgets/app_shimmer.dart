import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    // Shimmer is noticeably expensive on Android emulators and lower-end
    // devices. A static placeholder keeps scroll and navigation smoother.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return placeholder;
    }

    return RepaintBoundary(
      child: Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
      child: placeholder,
      ),
    );
  }
}
