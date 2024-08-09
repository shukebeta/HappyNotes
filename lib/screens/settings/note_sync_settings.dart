import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/note_sync_settings_controller.dart';
import 'package:happy_notes/services/dialog_services.dart';
import '../../dependency_injection.dart';
import '../../utils/util.dart';
import 'add_telegram_setting.dart';

class NoteSyncSettings extends StatefulWidget {
  const NoteSyncSettings({super.key});

  @override
  NoteSyncSettingsState createState() => NoteSyncSettingsState();
}

class NoteSyncSettingsState extends State<NoteSyncSettings> {
  final NoteSyncSettingsController _settingsController = locator<NoteSyncSettingsController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        actions: [
          FloatingActionButton(
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
        ],
      ),
      body: ListView.builder(
        itemCount: _settingsController.telegramSettings.length,
        itemBuilder: (context, index) {
          final setting = _settingsController.telegramSettings[index];
          return Card(
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Sync Type: ${_getSyncTypeDescription(setting.syncType)}${setting.syncType == 4 ? ' - ${setting.syncValue}' : ''}'),
                  Text('Channel ID: ${setting.channelId}'),
                  Text('Channel Remark: ${setting.channelName}'),
                  const Text('Token: encrypted token'),
                  Text('Token Remark: ${setting.tokenRemark}'),
                  Text('Token Status: ${setting.statusText}'),
                ],
              ),
              trailing: Column(
                children: [
                  if (setting.isActive || setting.isDisabled)
                    ElevatedButton(
                      onPressed: () async {
                        if (setting.isDisabled) {
                          await _settingsController.activateTelegramSetting(setting);
                        }
                        if (setting.isActive) {
                          await _settingsController.disableTelegramSetting(setting);
                        }
                        _loadSyncSettings();
                      },
                      child: Text(setting.isActive ? 'Disable' : 'Activate'),
                    ),
                  if (!setting.isTested)
                    ElevatedButton(
                      onPressed: () async {
                        final scaffoldContext = ScaffoldMessenger.of(context);
                        if (await _settingsController.testTelegramSetting(setting)) {
                          Util.showInfo(scaffoldContext, "A test message have been successfully sent to your telegram.");
                        } else {
                          Util.showError(scaffoldContext, "Test failed, please check your token or try again later");
                        }
                        _loadSyncSettings();
                      },
                      child: const Text('Test'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _settingsController.deleteTelegramSetting(setting);
                      _loadSyncSettings();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSyncTypeDescription(int syncType) {
    switch (syncType) {
      case 1:
        return 'Public';
      case 2:
        return 'Private';
      case 3:
        return 'All';
      case 4:
        return 'Tag';
      default:
        return 'Unknown';
    }
  }
}
