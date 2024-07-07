import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';

import '../../app_config.dart';
import '../../app_constants.dart';
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
  bool markdownIsEnabled = AppConfig.markdownIsEnabled;
  bool privateNoteOnlyIsEnabled = AppConfig.privateNoteOnlyIsEnabled;
  int pageSize = AppConfig.pageSize;
  String? selectedTimezone = AppConfig.timezone;
  final SettingsController _settingsController = locator<SettingsController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Page Size'),
              subtitle: const Text('Select the number of notes to display per page.'),
              trailing: DropdownButton<int>(
                value: pageSize,
                onChanged: (int? newValue) async {
                  await _settingsController.save(context, AppConstants.pageSize, newValue.toString());
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
            ),
            ListTile(
              title: const Text('Timezone'),
              trailing: SizedBox(
                width: 330,
                child: TimezoneDropdownItem(
                  items: TimezoneHelper.timezones,
                  value: selectedTimezone,
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      final result = await _settingsController.save(context, AppConstants.timezone, newValue);
                      if (result) {
                        setState(() {
                          selectedTimezone = newValue;
                        });
                      }
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Markdown'),
              subtitle: const Text('Enable or disable markdown support.'),
              trailing: Switch(
                value: markdownIsEnabled,
                onChanged: (bool newValue) async {
                  final result = await _settingsController.save(context, AppConstants.markdownIsEnabled, newValue ? "1" : "0");
                  if (result) {
                    setState(() {
                      markdownIsEnabled = newValue;
                    });
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Private Note Only'),
              subtitle: const Text('Enable to create all new notes as private by default.'),
              trailing: Switch(
                value: privateNoteOnlyIsEnabled,
                onChanged: (bool newValue) async {
                  final result = await _settingsController.save(
                      context, AppConstants.privateNoteOnlyIsEnabled, newValue ? "1" : "0");
                  if (result) {
                    setState(() {
                      privateNoteOnlyIsEnabled = newValue;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _settingsController.logout();
                  widget.onLogout!();
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
