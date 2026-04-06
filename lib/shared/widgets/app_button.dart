import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_text_styles.dart';

/// Reusable primary button
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double height;
  final Widget? prefixIcon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = 52,
    this.prefixIcon,
  });

  double _responsiveFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scaled = width * 0.038;
    if (scaled < 13) {
      return 13;
    }
    if (scaled > 16) {
      return 16;
    }
    return scaled;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextStyles.labelLarge.copyWith(
      fontSize: _responsiveFontSize(context),
    );
    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[prefixIcon!, const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(onPressed: isLoading ? null : onPressed, child: child),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(onPressed: isLoading ? null : onPressed, child: child),
    );
  }
}
