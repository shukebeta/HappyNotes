import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousPage,
    required this.onNextPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: currentPage > 1 ? onPreviousPage : null,
              child: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 20),
          Text('$currentPage of $totalPages'),
          const SizedBox(width: 20),
          SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: currentPage < totalPages ? onNextPage : null,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
