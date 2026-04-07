import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cinema_booking_system_app/core/utils/image_url_resolver.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_shimmer.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Color backgroundColor;
  final Color iconColor;
  final IconData fallbackIcon;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.iconColor = Colors.grey,
    this.fallbackIcon = Icons.broken_image_outlined,
  });

  bool _isSvg(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.svg') || lower.contains('.svg?');
  }

  double? _normalizeLogicalSize(double? logicalSize) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }
    return logicalSize;
  }

  int? _cacheDimension(BuildContext context, double? logicalSize) {
    final normalizedSize = _normalizeLogicalSize(logicalSize);
    if (normalizedSize == null) {
      return null;
    }

    final devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final rawPixels = normalizedSize * devicePixelRatio;
    if (!rawPixels.isFinite || rawPixels <= 0) {
      return null;
    }

    final pixels = rawPixels.round();
    if (pixels < 64) return 64;
    if (pixels > 2048) return 2048;
    return pixels;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ImageUrlResolver.normalize(url);
    final resolvedWidth = _normalizeLogicalSize(width);
    final resolvedHeight = _normalizeLogicalSize(height);
    final cacheWidth = _cacheDimension(context, resolvedWidth);
    final cacheHeight = _cacheDimension(context, resolvedHeight);
    final image = resolvedUrl == null || resolvedUrl.isEmpty
        ? _fallback()
        : _isSvg(resolvedUrl)
            ? SvgPicture.network(
                resolvedUrl,
                width: resolvedWidth,
                height: resolvedHeight,
                fit: fit,
                placeholderBuilder: (_) => AppShimmer(
                  width: resolvedWidth ?? double.infinity,
                  height: resolvedHeight ?? 200,
                  borderRadius: borderRadius,
                ),
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                width: resolvedWidth,
                height: resolvedHeight,
                fit: fit,
                memCacheWidth: cacheWidth,
                memCacheHeight: cacheHeight,
                maxWidthDiskCache: cacheWidth,
                maxHeightDiskCache: cacheHeight,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                filterQuality: FilterQuality.low,
                placeholder: (_, __) => AppShimmer(
                  width: resolvedWidth ?? double.infinity,
                  height: resolvedHeight ?? 200,
                  borderRadius: borderRadius,
                ),
                errorWidget: (_, __, ___) => _fallback(),
              );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }

  Widget _fallback() {
    return Container(
      width: _normalizeLogicalSize(width),
      height: _normalizeLogicalSize(height),
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: iconColor),
    );
  }
}
