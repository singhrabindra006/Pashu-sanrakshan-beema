/// Mirrors the backend list envelope:
/// `{ items, page, limit, total, total_pages }`
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  const Paginated.empty()
      : items = const [],
        page = 1,
        limit = 20,
        total = 0,
        totalPages = 0;

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory Paginated.fromJson(dynamic json, T Function(Map<String, dynamic>) itemParser) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rawItems = (map['items'] as List<dynamic>? ?? const []);
    return Paginated<T>(
      items: rawItems.whereType<Map<String, dynamic>>().map(itemParser).toList(),
      page: (map['page'] as num?)?.toInt() ?? 1,
      limit: (map['limit'] as num?)?.toInt() ?? 20,
      total: (map['total'] as num?)?.toInt() ?? rawItems.length,
      totalPages: (map['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Appends the next page while keeping the newest metadata.
  Paginated<T> merge(Paginated<T> next) => Paginated<T>(
        items: [...items, ...next.items],
        page: next.page,
        limit: next.limit,
        total: next.total,
        totalPages: next.totalPages,
      );
}
