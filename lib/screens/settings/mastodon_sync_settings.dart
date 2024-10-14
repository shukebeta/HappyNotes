import 'package:flutter/material.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/screens/settings/mastodon_sync_settings_controller.dart';
import '../../dependency_injection.dart';
import '../../services/dialog_services.dart';
import 'add_mastodon_user_account.dart';

class MastodonSyncSettings extends StatefulWidget {
  const MastodonSyncSettings({super.key});

  @override
  MastodonSyncSettingsState createState() => MastodonSyncSettingsState();
}

class MastodonSyncSettingsState extends State<MastodonSyncSettings> {
  final MastodonSyncSettingsController _settingsController = locator<MastodonSyncSettingsController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    await _settingsController.getMastodonSettings(context);
    setState(() {
      // syncSettings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mastodon Sync'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMastodonUserAccount(
                    setting: _settingsController.mastodonSettings?.lastOrNull,
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
        itemCount: _settingsController.mastodonSettings?.length ?? 0,
        itemBuilder: (context, index) {
          final setting = _settingsController.mastodonSettings?[index];
          if (setting == null) return const SizedBox.shrink();
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
                              text: '${_getSyncTypeDescription(setting.applicationId)}'
                                  '${setting.applicationId == 4 ? ' - ${setting.instanceUrl}' : ''}',
                            ),
                          ],
                        ),
                      ),
                      SelectableText.rich(
                        TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Channel: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: AppConfig.debugging ? '${setting.tokenType}/${setting.scope}' : setting.tokenType),
                          ],
                        ),
                      ),
                      SelectableText.rich(
                        TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Token Remark: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '${setting.refreshToken}'),
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
                              await _settingsController.activateMastodonSetting(setting);
                            }
                            if (setting.isActive) {
                              await _settingsController.disableMastodonSetting(setting);
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
                            if (await _settingsController.testMastodonSetting(context, setting)) {
                              _loadSyncSettings();
                            }
                          },
                          icon: const Icon(Icons.send, color: Colors.blue),
                          label: const Text('Test'),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          if (true == await DialogService.showConfirmDialog(context)) {
                            await _settingsController.deleteMastodonSetting(setting);
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
