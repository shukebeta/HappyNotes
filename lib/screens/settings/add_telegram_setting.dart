import 'package:flutter/material.dart';

import '../../dependency_injection.dart';
import 'note_sync_settings_controller.dart';

class AddTelegramSetting extends StatefulWidget {
  const AddTelegramSetting({super.key});

  @override
  AddTelegramSettingState createState() => AddTelegramSettingState();
}

class AddTelegramSettingState extends State<AddTelegramSetting> {
  final TextEditingController _channelIdController = TextEditingController();
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  int _syncType = 3;
  final NoteSyncSettingsController _settingsController = locator<NoteSyncSettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sync Setting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Source Note'),
              subtitle: const Text('Select what note should be synced.'),
              trailing: DropdownButton<int>(
                value: _syncType,
                onChanged: (int? newValue) {
                  setState(() {
                    _syncType = newValue!;
                  });
                },
                items: const [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('Public'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('Private'),
                  ),
                  DropdownMenuItem<int>(
                    value: 3,
                    child: Text('All'),
                  ),
                  DropdownMenuItem<int>(
                    value: 4,
                    child: Text('Tag'),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _channelIdController,
              decoration: const InputDecoration(labelText: 'Channel ID'),
            ),
            TextField(
              controller: _channelNameController,
              decoration: const InputDecoration(labelText: 'Channel Name'),
            ),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'Telegram Bot Token'),
            ),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(labelText: 'Token Remark'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // await _settingsController.addTelegramSyncSetting({
                //   "syncType": _syncType,
                //   "EncryptedToken": _tokenController.text,
                //   "TokenRemark": _remarkController.text,
                //   "channelId": _channelIdController.text,
                // });
                Navigator.pop(context);
              },
              child: const Text('Add Setting'),
            ),
          ],
        ),
      ),
    );
  }
}
