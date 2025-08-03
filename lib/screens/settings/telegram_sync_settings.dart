import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/telegram_sync_settings_controller.dart';
import '../../dependency_injection.dart';
import '../../entities/telegram_settings.dart';
import '../../services/dialog_services.dart';
import 'add_telegram_setting.dart';

class TelegramSyncSettings extends StatefulWidget {
  const TelegramSyncSettings({super.key});

  @override
  TelegramSyncSettingsState createState() => TelegramSyncSettingsState();
}

class TelegramSyncSettingsState extends State<TelegramSyncSettings> {
  final TelegramSyncSettingsController _settingsController = locator<TelegramSyncSettingsController>();
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    setState(() => _isLoading = true);
    try {
      await _settingsController.getTelegramSettings(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
    bool compact = false,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: 20),
      label: Text(compact ? '' : label),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildSettingCard(TelegramSettings setting) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Note Type',
                  '${_getSyncTypeDescription(setting.syncType)}'
                      '${setting.syncType == 4 ? ' - ${setting.syncValue}' : ''}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Channel', '${setting.channelName}/${setting.channelId}'),
                const SizedBox(height: 8),
                _buildInfoRow('Token Remark', setting.tokenRemark ?? ''),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: setting.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : setting.isDisabled
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    setting.statusText ?? 'Unknown',
                    style: TextStyle(
                      color: setting.isActive
                          ? Colors.green
                          : setting.isDisabled
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  children: [
                    if (setting.isActive || setting.isDisabled)
                      _buildActionButton(
                        icon: setting.isActive ? Icons.pause : Icons.play_arrow,
                        label: setting.isActive ? 'Disable' : 'Activate',
                        iconColor: setting.isActive ? Colors.orange : Colors.green,
                        compact: isSmallScreen,
                        onPressed: () async {
                          if (setting.isDisabled) {
                            await _settingsController.activateTelegramSetting(setting);
                          }
                          if (setting.isActive) {
                            await _settingsController.disableTelegramSetting(setting);
                          }
                          _loadSyncSettings();
                        },
                      ),
                    if (!setting.isTested)
                      _buildActionButton(
                        icon: Icons.send,
                        label: 'Test',
                        iconColor: Colors.blue,
                        compact: isSmallScreen,
                        onPressed: () async {
                          if (await _settingsController.testTelegramSetting(context, setting)) {
                            _loadSyncSettings();
                          }
                        },
                      ),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      iconColor: Colors.red,
                      compact: isSmallScreen,
                      onPressed: () async {
                        if (true == await DialogService.showConfirmDialog(context)) {
                          await _settingsController.deleteTelegramSetting(setting);
                          _loadSyncSettings();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sync_disabled,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Telegram Sync Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new sync setting',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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
              ).then((_) => _loadSyncSettings());
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSyncSettings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SelectionArea(
                child: _settingsController.telegramSettings.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _settingsController.telegramSettings.length,
                        itemBuilder: (context, index) {
                          return _buildSettingCard(_settingsController.telegramSettings[index]);
                        },
                      ),
              ),
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
