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

    return minFontSize +
        ((count - minCount) / (maxCount - minCount)) * (maxFontSize - minFontSize);
  }

  Color _generateRandomColor() {
    Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }
}
