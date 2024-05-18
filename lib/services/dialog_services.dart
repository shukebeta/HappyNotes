import 'package:flutter/material.dart';

class DialogService {
  static Future<bool?> showUnsavedChangesDialog(BuildContext context) {
    return showConfirmDialog(context, title: 'Unsaved changes', text: 'You have unsaved changes. Do you really want to leave?');
  }
  static Future<bool?> showConfirmDialog(BuildContext context, {String title='User confirmation', String text="Are you sure?"}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
