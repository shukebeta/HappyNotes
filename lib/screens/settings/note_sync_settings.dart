import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/note_sync_settings_controller.dart';
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
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTelegramSetting()),
              ).then((_) {
                _loadSyncSettings();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add setting'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _settingsController.telegramSettings.length,
        itemBuilder: (context, index) {
          final setting = _settingsController.telegramSettings[index];
          return Column(
            children: [
              Card(
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Note Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                              text: '${_getSyncTypeDescription(setting.syncType)}'
                                  '${setting.syncType == 4 ? ' - ${setting.syncValue}' : ''}',
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Channel: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '${setting.channelName}'),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Token: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '${setting.tokenRemark}'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          setting.statusText ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: setting.isActive
                                ? Colors.green
                                : setting.isDisabled
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (setting.isActive || setting.isDisabled)
                        TextButton.icon(
                          onPressed: () async {
                            if (setting.isDisabled) {
                              await _settingsController.activateTelegramSetting(setting);
                            }
                            if (setting.isActive) {
                              await _settingsController.disableTelegramSetting(setting);
                            }
                            _loadSyncSettings();
                          },
                          icon: Icon(
                            setting.isActive ? Icons.pause : Icons.play_arrow,
                            color: setting.isActive ? Colors.orange : Colors.green,
                          ),
                          label: Text(setting.isActive ? 'Disable' : 'Activate'),
                        ),
                      if (!setting.isTested)
                        TextButton.icon(
                          onPressed: () async {
                            final scaffoldContext = ScaffoldMessenger.of(context);
                            if (await _settingsController.testTelegramSetting(setting)) {
                              Util.showInfo(
                                  scaffoldContext, "A test message has been successfully sent to your Telegram.");
                            } else {
                              Util.showError(
                                  scaffoldContext, "Test failed, please check your token or try again later.");
                            }
                            _loadSyncSettings();
                          },
                          icon: const Icon(Icons.send, color: Colors.blue),
                          label: const Text('Test'),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          await _settingsController.deleteTelegramSetting(setting);
                          _loadSyncSettings();
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(''),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
        return 'All (Public + Private)';
      case 4:
        return 'Tag';
      default:
        return 'Unknown';
    }
  }
}
