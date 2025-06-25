import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/mastodon_sync_settings.dart';
import 'package:happy_notes/screens/settings/settings_controller.dart';
import 'package:happy_notes/screens/settings/telegram_sync_settings.dart';
import 'package:happy_notes/screens/settings/profile_page.dart';
import 'package:happy_notes/entities/user.dart';
import 'package:happy_notes/apis/account_api.dart';

import '../../app_config.dart';
import '../../app_constants.dart';
import '../../dependency_injection.dart';
import '../../utils/timezone_helper.dart';
import '../components/timezone-dropdown-item.dart';
import '../trash_bin/trash_bin_page.dart';

class Settings extends StatefulWidget {
  final VoidCallback? onLogout;

  const Settings({super.key, required this.onLogout});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool markdownIsEnabled = AppConfig.markdownIsEnabled;
  bool privateNoteOnlyIsEnabled = AppConfig.privateNoteOnlyIsEnabled;
  int pageSize = AppConfig.pageSize;
  String? selectedTimezone = AppConfig.timezone;
  final SettingsController _settingsController = locator<SettingsController>();
  User? _currentUser;
  bool _isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfoForAvatar();
  }

  Future<void> _fetchUserInfoForAvatar() async {
    setState(() {
      _isLoadingAvatar = true;
    });
    try {
      final user = await AccountApi.getMyInformation();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user info for avatar: $e");
      if (mounted) {
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          _isLoadingAvatar
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundImage: (_currentUser?.gravatar != null && _currentUser!.gravatar.isNotEmpty)
                  ? NetworkImage(_currentUser!.gravatar)
                  : null,
              onBackgroundImageError: (_, __) {},
              backgroundColor: Colors.grey[300],
              child: (_currentUser?.gravatar == null || _currentUser!.gravatar.isEmpty)
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Page Size'),
              subtitle: const Text('Select the number of notes to display per page.'),
              trailing: DropdownButton<int>(
                value: pageSize,
                onChanged: (int? newValue) async {
                  await _settingsController.save(context, AppConstants.pageSize, newValue.toString());
                  setState(() {
                    if (newValue != null) pageSize = newValue;
                  });
                },
                items: <int>[10, 20, 30, 40, 50, 60].map<DropdownMenuItem<int>>(
                      (int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  },
                ).toList(),
              ),
            ),
            ListTile(
              title: const Text('Timezone'),
              trailing: SizedBox(
                width: 250,
                child: TimezoneDropdownItem(
                  items: TimezoneHelper.timezones,
                  value: selectedTimezone,
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      final result = await _settingsController.save(context, AppConstants.timezone, newValue);
                      if (result) {
                        setState(() {
                          selectedTimezone = newValue;
                        });
                      }
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Markdown'),
              subtitle: const Text('Enable or disable markdown support.'),
              trailing: Switch(
                value: markdownIsEnabled,
                onChanged: (bool newValue) async {
                  final result = await _settingsController.save(context, AppConstants.markdownIsEnabled, newValue ? "1" : "0");
                  if (result) {
                    setState(() {
                      markdownIsEnabled = newValue;
                    });
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Private Note Only'),
              subtitle: const Text('Enable to create all new notes as private by default.'),
              trailing: Switch(
                value: privateNoteOnlyIsEnabled,
                onChanged: (bool newValue) async {
                  final result = await _settingsController.save(
                      context, AppConstants.privateNoteOnlyIsEnabled, newValue ? "1" : "0");
                  if (result) {
                    setState(() {
                      privateNoteOnlyIsEnabled = newValue;
                    });
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Notes Sync - Telegram'),
              subtitle: const Text('Configure synchronization settings for Telegram.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelegramSyncSettings()),
                );
              },
            ),
            ListTile(
              title: const Text('Notes Sync - Mastodon'),
              subtitle: const Text('Configure synchronization settings for Mastodon.'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MastodonSyncSettings()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash Bin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrashBinPage()),
                );
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Version: ${AppConfig.version}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _settingsController.logout();
                  widget.onLogout!();
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
