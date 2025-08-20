import 'package:flutter/material.dart';
import 'dart:math';

class TagCloud extends StatelessWidget {
  final Map<String, int> tagData;
  final void Function(String tag)? onTagTap;

  const TagCloud({super.key, required this.tagData, this.onTagTap});

  @override
  Widget build(BuildContext context) {
    int minCount = tagData.values.reduce(min);
    int maxCount = tagData.values.reduce(max);

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: tagData.entries.map((entry) {
        final String tag = entry.key;
        final int count = entry.value;

        double fontSize = _calculateFontSize(count, minCount, maxCount);
        Color color = _generateRandomColor();

        return GestureDetector(
          onTap: () {
            if (onTagTap != null) {
              onTagTap!(tag);
            }
          },
          child: Text(
            tag,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  double _calculateFontSize(int count, int minCount, int maxCount) {
    double minFontSize = 16;
    double maxFontSize = 32;

    if (minCount == maxCount) {
      // If all counts are the same, return the middle font size
      return (minFontSize + maxFontSize) / 2;
    }
    return minFontSize + ((count - minCount) / (maxCount - minCount)) * (maxFontSize - minFontSize);
  }

  Color _generateRandomColor() {
    Random random = Random();
    int r, g, b;
    double brightness;
    do {
      r = random.nextInt(181); // Limit to 0-180 to bias towards darker colors
      g = random.nextInt(181);
      b = random.nextInt(181);
      brightness = 0.299 * r + 0.587 * g + 0.114 * b;
    } while (brightness > 128); // Ensure brightness is low for contrast with white background
    return Color.fromARGB(255, r, g, b);
  }
}
