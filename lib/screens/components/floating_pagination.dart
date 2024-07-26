import 'package:flutter/material.dart';
import 'page_selector.dart';

class FloatingPagination extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) navigateToPage;

  const FloatingPagination({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  FloatingPaginationState createState() => FloatingPaginationState();
}

class FloatingPaginationState extends State<FloatingPagination> {
  bool showPageSelector = false;

  void _handlePageSelected(int page) {
    setState(() {
      showPageSelector = false;
    });
    widget.navigateToPage(page);
  }

  void _handleCancel() {
    setState(() {
      showPageSelector = false;
    });
  }

  void _showPageSelector() {
    setState(() {
      showPageSelector = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showPageSelector)
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: PageSelector(
                    totalPages: widget.totalPages,
                    onPageSelected: _handlePageSelected,
                    onCancel: _handleCancel,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          top: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: _showPageSelector,
                  child: Opacity(
                    opacity: 0.5,
                    child: FloatingActionButton(
                      heroTag: 'prevPage',
                      mini: true,
                      onPressed: widget.currentPage == 1 ? null : () => widget.navigateToPage(widget.currentPage - 1),
                      backgroundColor: widget.currentPage == 1 ? Colors.grey.shade400 : const Color(0xFFEBDDFF),
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onLongPress: _showPageSelector,
                  child: Opacity(
                    opacity: 0.5,
                    child: FloatingActionButton(
                      heroTag: 'nextPage',
                      mini: true,
                      onPressed: null,
                      backgroundColor: const Color(0xFFEBDDFF),
                      child: Text(
                        '${widget.currentPage}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onLongPress: _showPageSelector,
                  child: Opacity(
                    opacity: 0.5,
                    child: FloatingActionButton(
                      heroTag: 'nextPage',
                      mini: true,
                      onPressed: widget.currentPage == widget.totalPages
                          ? null
                          : () => widget.navigateToPage(widget.currentPage + 1),
                      backgroundColor:
                          widget.currentPage == widget.totalPages ? Colors.grey.shade400 : const Color(0xFFEBDDFF),
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
