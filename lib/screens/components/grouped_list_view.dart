import 'package:flutter/material.dart';

class GroupedListView<T> extends StatelessWidget {
  final Map<String, List<T>> groupedItems;
  final Widget Function(T item) itemBuilder;
  final Widget Function(String dateKey, DateTime date)? headerBuilder;
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final bool canLoadMore;
  final Widget? loadingWidget;

  const GroupedListView({
    super.key,
    required this.groupedItems,
    required this.itemBuilder,
    this.headerBuilder,
    this.scrollController,
    this.onRefresh,
    this.canLoadMore = false,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDates = groupedItems.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        controller: scrollController,
        itemCount: _calculateItemCount(sortedDates),
        itemBuilder: (context, index) => _buildItem(context, index, sortedDates),
      ),
    );
  }

  int _calculateItemCount(List<String> sortedDates) {
    int count = 0;
    for (final dateKey in sortedDates) {
      if (headerBuilder != null) count += 1; // Header (only if headerBuilder provided)
      count += groupedItems[dateKey]!.length; // Items
    }
    if (canLoadMore) count += 1; // Loading indicator
    return count;
  }

  Widget _buildItem(BuildContext context, int index, List<String> sortedDates) {
    if (canLoadMore && index == _calculateItemCount(sortedDates) - 1) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    int currentIndex = 0;
    for (final dateKey in sortedDates) {
      // Check if this is the header (only if headerBuilder is provided)
      if (headerBuilder != null && currentIndex == index) {
        return headerBuilder!(dateKey, DateTime.parse(dateKey));
      }
      if (headerBuilder != null) currentIndex++;

      // Check if this is one of the items for this date
      final items = groupedItems[dateKey]!;
      if (index < currentIndex + items.length) {
        final itemIndex = index - currentIndex;
        return itemBuilder(items[itemIndex]);
      }
      currentIndex += items.length;
    }

    throw StateError('Index out of bounds');
  }
}
