import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';

import '../../app_config.dart';
import '../../dependency_injection.dart';
import '../../utils/timezone_helper.dart';
import '../components/timezone-dropdown-item.dart';

class Settings extends StatefulWidget {
  final VoidCallback? onLogout;

  const Settings({super.key, required this.onLogout});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool isMarkdownModeOn = false;
  int pageSize = AppConfig.pageSize;
  String? selectedTimezone = AppConfig.timezone;
  final SettingsController _settingsController = locator<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Page size: '),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: pageSize,
                  onChanged: (int? newValue) async {
                    await _settingsController.save(context, 'pageSize', newValue.toString());
                    setState(() {
                      if (newValue != null) pageSize = newValue;
                    });
                  },
                  items: <int>[10, 20, 30, 40, 50, 60].map<DropdownMenuItem<int>>(
                    (int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Timezone: '),
                const SizedBox(width: 16),
                Container(
                  width: 320,
                  child: TimezoneDropdownItem(
                    items: TimezoneHelper.timezones,
                    value: selectedTimezone,
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await _settingsController.save(context, 'timezone', newValue);
                        setState(() {
                          selectedTimezone = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: isMarkdownModeOn,
                  onChanged: (bool? value) {
                    setState(() {
                      isMarkdownModeOn = value ?? false;
                    });
                  },
                ),
                const Text('Markdown mode on'),
              ],
            ),
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
