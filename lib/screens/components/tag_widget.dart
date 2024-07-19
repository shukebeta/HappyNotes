import 'package:flutter/material.dart';

class TagWidget extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;

  const TagWidget({
    Key? key,
    required this.tag,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          tag,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
