import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;
  final TextStyle? style;

  const DateHeader({
    super.key,
    required this.date,
    this.onTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            _formatDate(date),
            style: style ?? const TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '- ${DateFormat('EEEE, MMM d, yyyy').format(date)} -';
  }
}