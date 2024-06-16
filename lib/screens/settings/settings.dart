import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';

import '../../dependency_injection.dart';

class Settings extends StatefulWidget {
  final VoidCallback? onLogout;
  const Settings({super.key, required this.onLogout});
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool isMarkdownModeOn = false;
  int pageSize = 20; // Default page size
  SettingsController _settingsController = locator<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   children: [
            //     const Text('Page size: '),
            //     const SizedBox(width: 16),
            //     DropdownButton<int>(
            //       value: pageSize,
            //       onChanged: (int? newValue) {
            //         setState(() {
            //           pageSize = newValue ?? 20;
            //         });
            //       },
            //       items: <int>[20, 40, 60, 80].map<DropdownMenuItem<int>>(
            //         (int value) {
            //           return DropdownMenuItem<int>(
            //             value: value,
            //             child: Text(value.toString()),
            //           );
            //         },
            //       ).toList(),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // Row(
            //   children: [
            //     Checkbox(
            //       value: isMarkdownModeOn,
            //       onChanged: (bool? value) {
            //         setState(() {
            //           isMarkdownModeOn = value ?? false;
            //         });
            //       },
            //     ),
            //     const Text('Markdown mode on'),
            //   ],
            // ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _settingsController.logout();
                  widget.onLogout!();
                  // Handle logout
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
