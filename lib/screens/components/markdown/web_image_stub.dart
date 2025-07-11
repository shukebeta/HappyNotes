import 'package:flutter/material.dart';

// Stub implementation for non-web platforms
Widget createWebImage(String src, VoidCallback? onTap, VoidCallback? onLongPress, {bool isFullScreen = false}) {
  if (isFullScreen) {
    return Image.network(
      src,
      fit: BoxFit.contain,
    );
  }

  // In normal mode, use a container with responsive height
  return Container(
    constraints: const BoxConstraints(
      maxHeight: 300, // Prevent excessive height
      minHeight: 150, // Ensure minimum visibility
    ),
    child: Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Image.network(
            src,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.grey),
                    const SizedBox(height: 4),
                    const Text(
                      'Failed to load image',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      src.length > 40 ? '${src.substring(0, 40)}...' : src,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Simple tap detection overlay
        if (onTap != null || onLongPress != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTap,
              onLongPress: onLongPress,
              child: const SizedBox(),
            ),
          ),
      ],
    ),
  );
}
