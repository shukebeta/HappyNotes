import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/seq_logger.dart';

class GroupedListView<T> extends StatefulWidget {
  final Map<String, List<T>> groupedItems;
  final Widget Function(T item) itemBuilder;
  final Widget Function(String dateKey, DateTime date)? headerBuilder;
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final bool canLoadMore;
  final Widget? loadingWidget;
  final Future<void> Function()? onLoadMore;
  final bool canAutoLoadNext;
  final bool isAutoLoading;
  final bool pullUpToLoadEnabled;

  const GroupedListView({
    super.key,
    required this.groupedItems,
    required this.itemBuilder,
    this.headerBuilder,
    this.scrollController,
    this.onRefresh,
    this.canLoadMore = false,
    this.loadingWidget,
    this.onLoadMore,
    this.canAutoLoadNext = false,
    this.isAutoLoading = false,
    this.pullUpToLoadEnabled = false,
  });

  @override
  State<GroupedListView<T>> createState() => _GroupedListViewState<T>();
}

class _GroupedListViewState<T> extends State<GroupedListView<T>> {
  static const double _pullUpThreshold = 100.0;
  bool _isPullingUp = false;
  double _pullUpDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    final sortedDates = widget.groupedItems.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    SeqLogger.fine('[GroupedListView] Parameters: canAutoLoadNext=${widget.canAutoLoadNext}, isAutoLoading=${widget.isAutoLoading}, pullUpToLoadEnabled=${widget.pullUpToLoadEnabled}');

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          controller: widget.scrollController,
          physics: kIsWeb ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()) : null,
          itemCount: _calculateItemCount(sortedDates),
          itemBuilder: (context, index) => _buildItem(context, index, sortedDates),
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    SeqLogger.fine('[GroupedListView] ScrollNotification: type=${notification.runtimeType}, canAutoLoadNext=${widget.canAutoLoadNext}, isAutoLoading=${widget.isAutoLoading}, pullUpToLoadEnabled=${widget.pullUpToLoadEnabled}');
    
    if (!widget.canAutoLoadNext || widget.isAutoLoading) {
      SeqLogger.fine('[GroupedListView] Early return: conditions not met');
      return false;
    }

    if (!widget.pullUpToLoadEnabled) {
      SeqLogger.fine('[GroupedListView] Early return: pullUpToLoadEnabled=false');
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      SeqLogger.fine('[GroupedListView] ScrollUpdate: pixels=${metrics.pixels}, maxScrollExtent=${metrics.maxScrollExtent}');

      if (metrics.pixels >= metrics.maxScrollExtent) {
        final overscroll = metrics.pixels - metrics.maxScrollExtent;
        SeqLogger.fine('[GroupedListView] At bottom: overscroll=$overscroll');
        if (overscroll > 0) {
          SeqLogger.info('[GroupedListView] Overscroll detected! Setting _isPullingUp=true, _pullUpDistance=$overscroll');
          setState(() {
            _isPullingUp = true;
            _pullUpDistance = overscroll;
          });
        }
      } else {
        if (_isPullingUp) {
          SeqLogger.fine('[GroupedListView] Left bottom, resetting pull state');
          setState(() {
            _isPullingUp = false;
            _pullUpDistance = 0.0;
          });
        }
      }
    }

    if (notification is ScrollEndNotification) {
      SeqLogger.info('[GroupedListView] ScrollEnd: _isPullingUp=$_isPullingUp, _pullUpDistance=$_pullUpDistance, threshold=$_pullUpThreshold');
      if (_isPullingUp && _pullUpDistance >= _pullUpThreshold) {
        SeqLogger.info('[GroupedListView] Triggering auto-load!');
        widget.onLoadMore?.call();
      }
      setState(() {
        _isPullingUp = false;
        _pullUpDistance = 0.0;
      });
    }

    return false;
  }


  int _calculateItemCount(List<String> sortedDates) {
    int count = 0;
    for (final dateKey in sortedDates) {
      if (widget.headerBuilder != null) count += 1; // Header (only if headerBuilder provided)
      count += widget.groupedItems[dateKey]!.length; // Items
    }
    if (widget.canLoadMore) count += 1; // Loading indicator
    if (widget.canAutoLoadNext && widget.pullUpToLoadEnabled) count += 1; // Pull-up indicator
    return count;
  }

  Widget _buildItem(BuildContext context, int index, List<String> sortedDates) {
    final baseItemCount = _calculateItemCount(sortedDates) -
        (widget.canAutoLoadNext && widget.pullUpToLoadEnabled ? 1 : 0) -
        (widget.canLoadMore ? 1 : 0);

    // Auto-load next page indicator (bottom-most) - if enabled
    if (widget.canAutoLoadNext && widget.pullUpToLoadEnabled && index == _calculateItemCount(sortedDates) - 1) {
      return _buildPullUpIndicator();
    }

    // Legacy loading indicator
    if (widget.canLoadMore && index == baseItemCount + (widget.canAutoLoadNext && widget.pullUpToLoadEnabled ? 1 : 0)) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    int currentIndex = 0;
    for (final dateKey in sortedDates) {
      // Check if this is the header (only if headerBuilder is provided)
      if (widget.headerBuilder != null && currentIndex == index) {
        return widget.headerBuilder!(dateKey, DateTime.parse(dateKey));
      }
      if (widget.headerBuilder != null) currentIndex++;

      // Check if this is one of the items for this date
      final items = widget.groupedItems[dateKey]!;
      if (index < currentIndex + items.length) {
        final itemIndex = index - currentIndex;
        return widget.itemBuilder(items[itemIndex]);
      }
      currentIndex += items.length;
    }

    throw StateError('Index out of bounds');
  }

  Widget _buildPullUpIndicator() {
    if (widget.isAutoLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading next page...'),
          ],
        ),
      );
    }

    final progress = (_pullUpDistance / _pullUpThreshold).clamp(0.0, 1.0);
    final shouldTrigger = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: shouldTrigger ? 0 : 3.14159, // Flip arrow when ready
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: shouldTrigger ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                shouldTrigger ? 'Release to load next page' : 'Pull up to load next page',
                style: TextStyle(
                  color: shouldTrigger ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          if (_isPullingUp) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                shouldTrigger ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
