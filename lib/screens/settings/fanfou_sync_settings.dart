import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/fanfou_sync_settings_controller.dart';
import '../../dependency_injection.dart';
import '../../services/dialog_services.dart';
import '../../utils/util.dart';
import 'add_fanfou_user_account.dart';

class FanfouSyncSettings extends StatefulWidget {
  const FanfouSyncSettings({super.key});

  @override
  FanfouSyncSettingsState createState() => FanfouSyncSettingsState();
}

class FanfouSyncSettingsState extends State<FanfouSyncSettings> {
  final FanfouSyncSettingsController _settingsController = locator<FanfouSyncSettingsController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    await _settingsController.getFanfouSettings(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fanfou Sync'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFanfouUserAccount(),
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
        itemCount: _settingsController.fanfouSettings.length,
        itemBuilder: (context, index) {
          final setting = _settingsController.fanfouSettings[index];
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
                            const TextSpan(text: 'Sync Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                              text: setting.syncTypeText,
                              style: const TextStyle(color: Colors.blue, fontSize: 16),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  await _settingsController.nextSyncType(context);
                                  _loadSyncSettings();
                                },
                            ),
                          ],
                        ),
                      ),
                      SelectableText.rich(
                        TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(text: 'Account: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: setting.fanfouUserId ?? ''),
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
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            try {
                              if (setting.isDisabled) {
                                await _settingsController.activateFanfouSetting();
                              }
                              if (setting.isActive) {
                                await _settingsController.disableFanfouSetting();
                              }
                            } catch (e) {
                              if (!mounted) return;
                              Util.showError(scaffoldMessenger, e.toString());
                            }
                            _loadSyncSettings();
                          },
                          icon: Icon(
                            setting.isActive ? Icons.pause : Icons.play_arrow,
                            color: setting.isActive ? Colors.orange : Colors.green,
                          ),
                          label: Text(setting.isActive ? 'Disable' : 'Activate'),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          if (true == await DialogService.showConfirmDialog(context)) {
                            await _settingsController.deleteFanfouSetting();
                            _loadSyncSettings();
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete'),
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
}
