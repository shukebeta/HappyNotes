
import 'package:flutter/material.dart';

/// Floating Action Button for creating notes with visibility indicator
/// 
/// Displays a FAB with color-coded background and icon:
/// - Public notes: Primary theme color with blue globe icon
/// - Private notes: Light grey with dark grey lock icon
class CreateNoteFAB extends StatelessWidget {
  final bool isPrivate;
  final VoidCallback onPressed;

  const CreateNoteFAB({
    super.key,
    required this.isPrivate,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Opacity(
        opacity: 0.85,
        child: FloatingActionButton(
          backgroundColor: isPrivate
              ? Colors.grey[300]
              : Theme.of(context).colorScheme.primary,
          onPressed: onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.add,
                size: 28,
                color: isPrivate ? Colors.grey[800] : Colors.white,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Icon(
                  isPrivate ? Icons.lock : Icons.public,
                  size: 12,
                  color: isPrivate ? Colors.grey[700] : Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
