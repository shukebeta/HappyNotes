// First add shared_preferences to pubspec.yaml dependencies:
// shared_preferences: ^2.2.0

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageWarningDialog extends StatefulWidget {
  const ImageWarningDialog({Key? key}) : super(key: key);

  @override
  State<ImageWarningDialog> createState() => _ImageWarningDialogState();
}

class _ImageWarningDialogState extends State<ImageWarningDialog> {
  bool _dontShowAgain = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy Warning'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Any images you upload will be publicly accessible to anyone with the image URL, even in private notes. Please do not upload sensitive or private photos.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (bool? value) {
                  setState(() {
                    _dontShowAgain = value ?? true;
                  });
                },
              ),
              const Text("Don't show this warning again"),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            var navigator = Navigator.of(context);
            if (_dontShowAgain) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hideImageWarning', true);
            }
            navigator.pop(true);
          },
          child: const Text('I understand'),
        ),
      ],
    );
  }
}
