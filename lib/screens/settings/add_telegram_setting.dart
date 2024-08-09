import 'package:flutter/material.dart';
import 'package:happy_notes/entities/telegram_settings.dart';
import '../../dependency_injection.dart';
import 'note_sync_settings_controller.dart';

class AddTelegramSetting extends StatefulWidget {
  final TelegramSettings? setting;
  const AddTelegramSetting({super.key, this.setting});

  @override
  AddTelegramSettingState createState() => AddTelegramSettingState();
}

class AddTelegramSettingState extends State<AddTelegramSetting> {
  final TextEditingController _channelIdController = TextEditingController();
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  int _syncType = 3;
  final NoteSyncSettingsController _settingsController = locator<NoteSyncSettingsController>();

  @override
  void initState() {
    super.initState();
    if (widget.setting != null) {
      _tokenController.text = 'the same token as the last setting';
      _remarkController.text = widget.setting!.tokenRemark!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sync Setting - Telegram'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Source Note',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            DropdownButton<int>(
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
            if (_syncType == 4)
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag'),
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
              onPressed: () {
                _settingsController.addTelegramSetting(TelegramSettings(
                    syncType: _syncType,
                    syncValue: _syncType == 4 ? _tagController.text : '',
                    channelId: _channelIdController.text,
                    channelName: _channelNameController.text,
                    tokenRemark: _remarkController.text,
                    encryptedToken: _tokenController.text)).then(Navigator.of(context).pop);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
