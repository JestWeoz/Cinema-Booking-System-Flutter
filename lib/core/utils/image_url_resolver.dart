import 'package:cinema_booking_system_app/core/constants/app_constants.dart';

class ImageUrlResolver {
  ImageUrlResolver._();

  static String? normalize(String? raw) {
    if (raw == null) {
      return null;
    }

    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    if (lower == 'null' ||
        lower == 'undefined' ||
        lower == 'n/a' ||
        lower == 'nan') {
      return null;
    }

    final embeddedUrl = _extractEmbeddedHttpUrl(trimmed);
    if (embeddedUrl != null) {
      return embeddedUrl;
    }

    final sanitized = trimmed.replaceAll('\\', '/');
    final encoded = Uri.encodeFull(sanitized);

    if (encoded.startsWith('http://') || encoded.startsWith('https://')) {
      return encoded;
    }
    if (encoded.startsWith('//')) {
      return 'https:$encoded';
    }

    final apiUri = Uri.parse(AppConstants.baseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';

    if (encoded.startsWith('/')) {
      return '$origin$encoded';
    }

    return '$origin/$encoded';
  }

  static String? pick(
    Map<String, dynamic> json, {
    List<String> keys = const [],
  }) {
    for (final key in [
      ...keys,
      'posterUrl',
      'poster_url',
      'backdropUrl',
      'backdrop_url',
      'imageUrl',
      'image',
      'url',
      'avatarUrl',
      'avatar_url',
      'logoUrl',
      'logo_url',
      'thumbnailUrl',
      'thumbnail_url',
    ]) {
      final value = _extract(json[key]);
      if (value != null) {
        return value;
      }
    }

    for (final listKey in ['images', 'movieImages', 'gallery', 'media']) {
      final value = _extract(json[listKey]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static String? _extract(dynamic value) {
    if (value is String) {
      return normalize(value);
    }
    if (value is Map<String, dynamic>) {
      return pick(value);
    }
    if (value is List) {
      for (final item in value) {
        final nested = _extract(item);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  static String? _extractEmbeddedHttpUrl(String value) {
    final decoded = _safeDecode(value);
    final patterns = <RegExp>[
      RegExp(r'https?://[^\s,}"]+'),
      RegExp(r'url\s*:\s*(https?://[^\s,}"]+)'),
      RegExp(r'"url"\s*:\s*"(https?://[^"]+)"'),
    ];

    for (final candidate in [value, decoded]) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(candidate);
        if (match == null) {
          continue;
        }
        final extracted = match.group(match.groupCount >= 1 ? 1 : 0) ?? match.group(0);
        if (extracted != null && extracted.startsWith('http')) {
          return Uri.encodeFull(extracted);
        }
      }
    }
    return null;
  }

  static String _safeDecode(String value) {
    try {
      return Uri.decodeFull(value);
    } catch (_) {
      return value;
    }
  }
}
