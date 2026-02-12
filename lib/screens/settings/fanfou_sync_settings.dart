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
    await _settingsController.getFanfouAccounts(context);
    setState(() {
      // Refresh UI
    });
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
      body: _settingsController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settingsController.fanfouAccounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_sync, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No Fanfou accounts configured',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _settingsController.fanfouAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _settingsController.fanfouAccounts[index];
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
                                      const TextSpan(text: 'Username: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: account.username),
                                    ],
                                  ),
                                ),
                                SelectableText.rich(
                                  TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      const TextSpan(text: 'Sync: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(
                                        text: account.syncTypeText,
                                        style: const TextStyle(color: Colors.blue, fontSize: 16),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () async {
                                            await _settingsController.nextSyncType(context, account);
                                            _loadSyncSettings();
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    account.statusText,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: account.isActive
                                          ? Colors.green
                                          : account.isDisabled
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
                                if (account.isActive || account.isDisabled)
                                  TextButton.icon(
                                    onPressed: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      try {
                                        if (account.isDisabled) {
                                          await _settingsController.activateFanfouAccount(account);
                                        }
                                        if (account.isActive) {
                                          await _settingsController.disableFanfouAccount(account);
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        Util.showError(scaffoldMessenger, e.toString());
                                      }
                                      _loadSyncSettings();
                                    },
                                    icon: Icon(
                                      account.isActive ? Icons.pause : Icons.play_arrow,
                                      color: account.isActive ? Colors.orange : Colors.green,
                                    ),
                                    label: Text(account.isActive ? 'Disable' : 'Activate'),
                                  ),
                                TextButton.icon(
                                  onPressed: () async {
                                    if (true == await DialogService.showConfirmDialog(context)) {
                                      await _settingsController.deleteFanfouAccount(account);
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
