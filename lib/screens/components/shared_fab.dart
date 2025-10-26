import 'package:flutter/material.dart';

/// Reusable Shared FAB component.
///
/// Intended to replace existing create_note_fab internal implementation.
/// Supports icon-only (default) and mini variants, privacy badge, busy state, and accessibility labels.
class SharedFab extends StatelessWidget {
  final IconData icon;
  final bool isPrivate;
  final bool busy;
  final bool mini;
  final String? label;
  final VoidCallback? onPressed;
  final String? heroTag;

  const SharedFab({
    Key? key,
    required this.icon,
    this.isPrivate = false,
    this.busy = false,
    this.mini = false,
    this.label,
    this.onPressed,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const fabSize = 56.0;
    const badgeSize = 16.0;
    final actualFabSize = mini ? 40.0 : fabSize;

    final privacyBorderColor = isPrivate ? Colors.grey.shade700 : theme.colorScheme.primary;

    return SizedBox(
      width: actualFabSize,
      height: actualFabSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            heroTag: heroTag,
            onPressed: busy ? null : onPressed,
            backgroundColor: theme.colorScheme.primaryContainer,
            elevation: 6,
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimaryContainer,
                      strokeWidth: 2.0,
                    ),
                  )
                : Icon(
                    icon,
                    size: 24,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: privacyBorderColor, width: 1.0),
              ),
              child: Center(
                child: Icon(
                  isPrivate ? Icons.lock : Icons.public,
                  size: 10,
                  color: privacyBorderColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
