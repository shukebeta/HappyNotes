import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/note_sync_settings_controller.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';
import '../../dependency_injection.dart';
import 'add_telegram_setting.dart';

class NoteSyncSettings extends StatefulWidget {
  const NoteSyncSettings({super.key});

  @override
  NoteSyncSettingsState createState() => NoteSyncSettingsState();
}

class NoteSyncSettingsState extends State<NoteSyncSettings> {
  final NoteSyncSettingsController _settingsController = locator<NoteSyncSettingsController>();


  @override
  void initState() {
    super.initState();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    await _settingsController.getTelegramSettings(context);
    setState(() {
      // syncSettings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Sync Settings'),
      ),
      body: ListView.builder(
        itemCount: _settingsController.telegramSettings.length,
        itemBuilder: (context, index) {
          final setting = _settingsController.telegramSettings[index];
          return ListTile(
            title: Text('Sync Type: ${setting.syncType}'),
            subtitle: Text('Channel ID: ${setting.channelId}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // await _settingsController.deleteTelegramSyncSetting(setting['id']);
                _loadSyncSettings();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTelegramSetting()),
          ).then((_) {
            _loadSyncSettings();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
