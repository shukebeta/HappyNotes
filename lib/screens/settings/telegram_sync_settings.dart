import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/settings/telegram_sync_settings_controller.dart';
import '../../dependency_injection.dart';
import '../../services/dialog_services.dart';
import 'add_telegram_setting.dart';

class TelegramSyncSettings extends StatefulWidget {
  const TelegramSyncSettings({super.key});

  @override
  TelegramSyncSettingsState createState() => TelegramSyncSettingsState();
}

class TelegramSyncSettingsState extends State<TelegramSyncSettings> {
  final TelegramSyncSettingsController _settingsController = locator<TelegramSyncSettingsController>();

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
        title: const Text('Telegram Sync'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTelegramSetting(
                    setting: _settingsController.telegramSettings.lastOrNull,
                  ),
                ),
              ).then((_) {
                _loadSyncSettings();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
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
                      SelectableText.rich(
                        TextSpan(
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
                      SelectableText.rich(
                        TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Channel: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: AppConfig.debugging ? '${setting.channelName}/${setting.channelId}' : setting.channelName),
                          ],
                        ),
                      ),
                      SelectableText.rich(
                        TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Token Remark: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            if (await _settingsController.testTelegramSetting(context, setting)) {
                              _loadSyncSettings();
                            }
                          },
                          icon: const Icon(Icons.send, color: Colors.blue),
                          label: const Text('Test'),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          if (true == await DialogService.showConfirmDialog(context)) {
                            await _settingsController.deleteTelegramSetting(setting);
                            _loadSyncSettings();
                          }
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
