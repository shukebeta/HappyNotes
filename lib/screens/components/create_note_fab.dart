
import 'package:flutter/material.dart';
import 'package:happy_notes/screens/components/shared_fab.dart';

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
    // Wrapper around SharedFab to preserve external API while improving visuals
    return Positioned(
      right: 16,
      bottom: 16,
      child: Opacity(
        opacity: 0.95,
        child: SharedFab(
          icon: Icons.edit_outlined,
          isPrivate: isPrivate,
          busy: false,
          mini: false,
          onPressed: onPressed,
          heroTag: 'create_note_fab',
        ),
      ),
    );
  }
}
