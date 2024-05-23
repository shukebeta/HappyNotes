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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: currentPage > 1 ? onPreviousPage : null,
          child: const Text('Previous Page'),
        ),
        const SizedBox(width: 20),
        Text('Page $currentPage of $totalPages'),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: currentPage < totalPages ? onNextPage : null,
          child: const Text('Next Page'),
        ),
      ],
    );
  }
}
