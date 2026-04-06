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

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ImageUrlResolver.normalize(url);
    final image = resolvedUrl == null || resolvedUrl.isEmpty
        ? _fallback()
        : _isSvg(resolvedUrl)
            ? SvgPicture.network(
                resolvedUrl,
                width: width,
                height: height,
                fit: fit,
                placeholderBuilder: (_) => AppShimmer(
                  width: width ?? double.infinity,
                  height: height ?? 200,
                  borderRadius: borderRadius,
                ),
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : CachedNetworkImage(
                imageUrl: resolvedUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (_, __) => AppShimmer(
                  width: width ?? double.infinity,
                  height: height ?? 200,
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
      width: width,
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: iconColor),
    );
  }
}
