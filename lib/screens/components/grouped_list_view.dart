import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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

  // Pull-down functionality
  final Future<void> Function()? onLoadPrevious;
  final bool canAutoLoadPrevious;
  final bool pullDownToLoadEnabled;
  final int currentPage; // To determine behavior (refresh vs load previous)

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
    this.onLoadPrevious,
    this.canAutoLoadPrevious = false,
    this.pullDownToLoadEnabled = false,
    this.currentPage = 1,
  });

  @override
  State<GroupedListView<T>> createState() => _GroupedListViewState<T>();
}

class _GroupedListViewState<T> extends State<GroupedListView<T>> {
  static const double _pullUpThreshold = 100.0;
  static const double _pullDownThreshold = 100.0;

  // Pull-up state (existing)
  bool _isPullingUp = false;
  double _pullUpDistance = 0.0;
  bool _hasTriggeredUp = false; // Prevent duplicate triggers

  // Pull-down state (new)
  bool _isPullingDown = false;
  double _pullDownDistance = 0.0;
  bool _hasTriggeredDown = false; // Prevent duplicate triggers

  @override
  Widget build(BuildContext context) {
    final sortedDates = widget.groupedItems.keys.toList()..sort((a, b) => b.compareTo(a)); // Newest first

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
    // Skip if loading or no pull features enabled
    if (widget.isAutoLoading || (!widget.pullUpToLoadEnabled && !widget.pullDownToLoadEnabled)) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;

      // Handle pull-down (top overscroll)
      if (widget.pullDownToLoadEnabled && widget.canAutoLoadPrevious && metrics.pixels <= 0) {
        final overscroll = -metrics.pixels; // Convert to positive value
        if (overscroll > 0) {
          setState(() {
            _isPullingDown = true;
            _pullDownDistance = overscroll;
          });

          // Trigger action immediately when threshold is reached
          if (_pullDownDistance >= _pullDownThreshold && !_hasTriggeredDown) {
            _hasTriggeredDown = true;
            _handlePullDownTrigger();
            setState(() {
              _isPullingDown = false;
              _pullDownDistance = 0.0;
            });
          }
        }
      } else if (_isPullingDown && metrics.pixels > 0) {
        // Reset pull-down state when leaving top
        setState(() {
          _isPullingDown = false;
          _pullDownDistance = 0.0;
          _hasTriggeredDown = false; // Reset trigger flag when leaving top
        });
      }

      // Handle pull-up (bottom overscroll) - existing logic
      if (widget.pullUpToLoadEnabled && widget.canAutoLoadNext && metrics.pixels >= metrics.maxScrollExtent) {
        final overscroll = metrics.pixels - metrics.maxScrollExtent;
        if (overscroll > 0) {
          setState(() {
            _isPullingUp = true;
            _pullUpDistance = overscroll;
          });

          // Trigger loading immediately when threshold is reached
          if (_pullUpDistance >= _pullUpThreshold && !_hasTriggeredUp) {
            _hasTriggeredUp = true;
            widget.onLoadMore?.call();
            setState(() {
              _isPullingUp = false;
              _pullUpDistance = 0.0;
            });
          }
        }
      } else {
        if (_isPullingUp) {
          setState(() {
            _isPullingUp = false;
            _pullUpDistance = 0.0;
            _hasTriggeredUp = false; // Reset trigger flag when leaving bottom
          });
        }
      }
    }

    if (notification is ScrollEndNotification) {
      // Backup triggers for ScrollEndNotification (in case ScrollUpdate didn't trigger)
      if (_isPullingUp && _pullUpDistance >= _pullUpThreshold && !_hasTriggeredUp) {
        widget.onLoadMore?.call();
      }

      if (_isPullingDown && _pullDownDistance >= _pullDownThreshold && !_hasTriggeredDown) {
        _handlePullDownTrigger();
      }

      setState(() {
        // Reset all pull states on scroll end
        _isPullingUp = false;
        _pullUpDistance = 0.0;
        _hasTriggeredUp = false;
        _isPullingDown = false;
        _pullDownDistance = 0.0;
        _hasTriggeredDown = false;
      });
    }

    return false;
  }

  // Handle pull-down behavior based on current page
  void _handlePullDownTrigger() {
    if (widget.currentPage == 1) {
      // First page: refresh

      widget.onRefresh?.call();
    } else {
      // Other pages: load previous page

      widget.onLoadPrevious?.call();
    }
  }

  int _calculateItemCount(List<String> sortedDates) {
    int count = 0;
    for (final dateKey in sortedDates) {
      if (widget.headerBuilder != null) count += 1; // Header (only if headerBuilder provided)
      count += widget.groupedItems[dateKey]!.length; // Items
    }
    if (widget.canLoadMore) count += 1; // Loading indicator
    if (widget.canAutoLoadNext && widget.pullUpToLoadEnabled) count += 1; // Pull-up indicator
    if (widget.canAutoLoadPrevious && widget.pullDownToLoadEnabled) count += 1; // Pull-down indicator
    return count;
  }

  Widget _buildItem(BuildContext context, int index, List<String> sortedDates) {
    final totalItemCount = _calculateItemCount(sortedDates);
    final pullDownOffset = widget.canAutoLoadPrevious && widget.pullDownToLoadEnabled ? 1 : 0;

    // Pull-down indicator (top-most) - if enabled
    if (widget.canAutoLoadPrevious && widget.pullDownToLoadEnabled && index == 0) {
      return _buildPullDownIndicator();
    }

    // Adjust index for pull-down indicator offset
    final adjustedIndex = index - pullDownOffset;
    final baseItemCount = totalItemCount -
        (widget.canAutoLoadNext && widget.pullUpToLoadEnabled ? 1 : 0) -
        (widget.canLoadMore ? 1 : 0) -
        pullDownOffset;

    // Auto-load next page indicator (bottom-most) - if enabled
    if (widget.canAutoLoadNext && widget.pullUpToLoadEnabled && index == totalItemCount - 1) {
      return _buildPullUpIndicator();
    }

    // Legacy loading indicator
    if (widget.canLoadMore && adjustedIndex == baseItemCount) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    int currentIndex = 0;
    for (final dateKey in sortedDates) {
      // Check if this is the header (only if headerBuilder is provided)
      if (widget.headerBuilder != null && currentIndex == adjustedIndex) {
        return widget.headerBuilder!(dateKey, DateTime.parse(dateKey));
      }
      if (widget.headerBuilder != null) currentIndex++;

      // Check if this is one of the items for this date
      final items = widget.groupedItems[dateKey]!;
      if (adjustedIndex < currentIndex + items.length) {
        final itemIndex = adjustedIndex - currentIndex;
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

  Widget _buildPullDownIndicator() {
    if (widget.isAutoLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(widget.currentPage == 1 ? 'Refreshing...' : 'Loading previous page...'),
          ],
        ),
      );
    }

    final progress = (_pullDownDistance / _pullDownThreshold).clamp(0.0, 1.0);
    final shouldTrigger = progress >= 1.0;

    // Different messages based on current page
    final pullMessage = widget.currentPage == 1 ? 'Pull down to refresh' : 'Pull down to load previous page';
    final releaseMessage = widget.currentPage == 1 ? 'Release to refresh' : 'Release to load previous page';

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: shouldTrigger ? 3.14159 : 0, // Flip arrow when ready
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: shouldTrigger ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                shouldTrigger ? releaseMessage : pullMessage,
                style: TextStyle(
                  color: shouldTrigger ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          if (_isPullingDown) ...[
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
