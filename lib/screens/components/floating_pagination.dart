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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 6,
      top: 100,
      bottom: 100,
      child: showPageSelector
          ? PageSelector(
              totalPages: widget.totalPages,
              onPageSelected: _handlePageSelected,
              onCancel: _handleCancel,
            )
          : GestureDetector(
              onLongPress: () {
                setState(() {
                  showPageSelector = true;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: FloatingActionButton(
                      heroTag: 'prevPage',
                      mini: true,
                      onPressed: widget.currentPage == 1 ? null : () => widget.navigateToPage(widget.currentPage - 1),
                      backgroundColor: widget.currentPage == 1 ? Colors.grey.shade400 : const Color(0xFFEBDDFF),
                      child: const Icon(Icons.arrow_upward),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '${widget.currentPage}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
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
                ],
              ),
            ),
    );
  }
}
