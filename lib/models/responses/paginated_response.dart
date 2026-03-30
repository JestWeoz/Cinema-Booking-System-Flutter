/// Phân trang — Spring Boot Page<T> trả về:
/// {
///   "content": [...],
///   "pageable": { ... },
///   "totalElements": 50,
///   "totalPages": 5,
///   "size": 10,
///   "number": 0,  ← page hiện tại (0-indexed)
///   "first": true,
///   "last": false
/// }
class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number; // page hiện tại (0-indexed)
  final bool first;
  final bool last;

  const PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
  });

  /// Trang hiện tại (1-indexed, thân thiện hơn với UI)
  int get currentPage => number + 1;

  bool get hasNextPage => !last;
  bool get hasPreviousPage => !first;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawContent = json['content'];
    final content = rawContent is List
        ? rawContent.map((e) => fromItem(e as Map<String, dynamic>)).toList()
        : <T>[];

    return PaginatedResponse<T>(
      content: content,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      size: json['size'] as int? ?? 10,
      number: json['number'] as int? ?? 0,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
    );
  }
}
