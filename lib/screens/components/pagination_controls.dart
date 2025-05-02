import 'package:flutter/material.dart';
import 'package:happy_notes/utils/util.dart'; // Import Util

class PaginationControls extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) navigateToPage;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  PaginationControlsState createState() => PaginationControlsState();
}

class PaginationControlsState extends State<PaginationControls> {
  final TextEditingController _pageController = TextEditingController();
  bool showPageSelector = false;

  @override
  void initState() {
    super.initState();
    _pageController.text = widget.currentPage.toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChange() {
    final int? newPage = int.tryParse(_pageController.text);
    if (newPage != null && newPage > 0 && newPage <= widget.totalPages) {
      widget.navigateToPage(newPage);
      _hidePageSelector();
    } else {
      Util.showError(ScaffoldMessenger.of(context), 'Invalid page number'); // Replaced showSnackBar
    }
  }

  void _showPageSelector() {
    setState(() {
      showPageSelector = true;
      _pageController.text = widget.currentPage.toString();
    });
  }

  void _hidePageSelector() {
    setState(() {
      showPageSelector = false;
    });
  }

  Widget _buildButton(String text, VoidCallback? onPressed) {
    return GestureDetector(
      onLongPress: _showPageSelector,
      child: SizedBox(
        width: 120,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // This transparent container ensures the GestureDetector covers the whole area
        Positioned.fill(
          child: GestureDetector(
            onTap: _hidePageSelector,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                  'Previous',
                  widget.currentPage > 1
                      ? () {
                          widget.navigateToPage(widget.currentPage - 1);
                        }
                      : null),
              const SizedBox(width: 20),
              if (!showPageSelector)
                GestureDetector(
                  onLongPress: _showPageSelector,
                  child: Text(
                    '${widget.currentPage} of ${widget.totalPages}',
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    /* Prevent taps from bubbling up */
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: _pageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _handlePageChange(),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: _handlePageChange,
                        child: const Text('Go'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 20),
              _buildButton(
                  'Next',
                  widget.currentPage < widget.totalPages
                      ? () {
                          widget.navigateToPage(widget.currentPage + 1);
                        }
                      : null),
            ],
          ),
        ),
      ],
    );
  }
}
