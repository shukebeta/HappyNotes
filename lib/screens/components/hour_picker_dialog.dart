import 'package:flutter/material.dart';

class HourPickerDialog extends StatelessWidget {
  final DateTime date;

  const HourPickerDialog({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final currentHour = DateTime.now().hour;

    return AlertDialog(
      title: Text('Choose an hour on ${_formatDateOnly()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Or click OK to use current hour',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(24, (index) {
                final hour = (index + 7) % 24; // Start from 7 AM
                final isCurrentHour = hour == currentHour;

                return SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentHour
                          ? Colors.blue.shade200
                          : null,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => Navigator.pop(context, hour),
                    child: Text(hour.toString().padLeft(2, '0')),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, currentHour),
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _formatDateOnly() {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Static method to show the dialog and return selected hour
  static Future<int?> show(BuildContext context, DateTime date) async {
    return showDialog<int>(
      context: context,
      builder: (context) => HourPickerDialog(date: date),
    );
  }
}
