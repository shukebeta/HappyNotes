import 'package:flutter/material.dart';

class TappableAppBarTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TappableAppBarTitle({
    super.key,
    required this.title,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        mainAxisSize: MainAxisSize.min, // Prevent Row from expanding
        children: [
          Text(title),
          const SizedBox(width: 8), // Add some spacing
          const Icon(Icons.touch_app, size: 18, color: Colors.blue), // Use blue color
        ],
      ),
    );
  }
}
