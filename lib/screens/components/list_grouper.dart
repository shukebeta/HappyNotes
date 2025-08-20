class ListGrouper {
  static Map<String, List<T>> groupByDate<T>(
    List<T> items,
    String Function(T item) dateExtractor,
  ) {
    final grouped = <String, List<T>>{};
    for (final item in items) {
      final dateKey = dateExtractor(item);
      (grouped[dateKey] ??= []).add(item);
    }
    return grouped;
  }
}
