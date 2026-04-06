import 'package:cinema_booking_system_app/models/responses/paginated_response.dart';

class ApiPayloadParser {
  ApiPayloadParser._();

  static dynamic unwrap(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('data')) {
      return raw['data'];
    }
    return raw;
  }

  static String extractMessage(dynamic raw, {String fallback = 'Unknown error'}) {
    final unwrapped = unwrap(raw);
    if (unwrapped is Map<String, dynamic>) {
      final direct = unwrapped['message'] ?? unwrapped['error'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct;
      }
    }
    if (raw is Map<String, dynamic>) {
      final direct = raw['message'] ?? raw['error'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct;
      }
    }
    return fallback;
  }

  static Map<String, dynamic> map(dynamic raw) {
    final unwrapped = unwrap(raw);
    if (unwrapped is Map<String, dynamic>) {
      return unwrapped;
    }
    return <String, dynamic>{};
  }

  static List<dynamic> list(dynamic raw) {
    final unwrapped = unwrap(raw);
    if (unwrapped is List) {
      return unwrapped;
    }
    if (unwrapped is Map<String, dynamic>) {
      final candidates = [
        unwrapped['items'],
        unwrapped['content'],
        unwrapped['results'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate;
        }
      }
    }
    return const [];
  }

  static PaginatedResponse<T> page<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson, {
    int defaultSize = 10,
  }) {
    final unwrapped = unwrap(raw);
    if (unwrapped is Map<String, dynamic>) {
      final items = ((unwrapped['items'] ?? unwrapped['content']) as List?)
              ?.map((entry) => fromJson(entry as Map<String, dynamic>))
              .toList() ??
          <T>[];
      final pageNumber = (unwrapped['page'] ?? unwrapped['number'] ?? 0) as int;
      final totalPages = (unwrapped['totalPages'] ?? 1) as int;
      final last = unwrapped['last'] as bool? ?? (pageNumber + 1 >= totalPages);
      return PaginatedResponse<T>(
        content: items,
        totalElements: (unwrapped['totalElements'] ?? items.length) as int,
        totalPages: totalPages,
        size: (unwrapped['size'] ?? defaultSize) as int,
        number: pageNumber,
        first: unwrapped['first'] as bool? ?? pageNumber == 0,
        last: last,
      );
    }
      return PaginatedResponse<T>(
        content: <T>[],
        totalElements: 0,
        totalPages: 0,
        size: defaultSize,
      number: 0,
      first: true,
      last: true,
    );
  }
}
