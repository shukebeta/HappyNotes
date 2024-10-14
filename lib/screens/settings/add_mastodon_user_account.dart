import 'package:flutter/material.dart';
import 'package:happy_notes/entities/mastodon_user_account.dart';
import '../../dependency_injection.dart';
import 'mastodon_sync_settings_controller.dart';

class AddMastodonUserAccount extends StatefulWidget {
  final MastodonUserAccount? setting;
  const AddMastodonUserAccount({super.key, this.setting});

  @override
  AddMastodonUserAccountState createState() => AddMastodonUserAccountState();
}

class AddMastodonUserAccountState extends State<AddMastodonUserAccount> {
  final TextEditingController _channelIdController = TextEditingController();
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  int _syncType = 3;
  final MastodonSyncSettingsController _settingsController = locator<MastodonSyncSettingsController>();

  @override
  void initState() {
    super.initState();
    if (widget.setting != null) {
      _tokenController.text = 'the same token as the last setting';
      _remarkController.text = widget.setting!.refreshToken!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sync Setting - Mastodon'),
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
              decoration: const InputDecoration(labelText: 'Mastodon Bot Token'),
            ),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(labelText: 'Token Remark'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _settingsController.addMastodonSetting(MastodonUserAccount(
                    applicationId: _syncType,
                    instanceUrl: _syncType == 4 ? _tagController.text : '',
                    scope: _channelIdController.text,
                    tokenType: _channelNameController.text,
                    refreshToken: _remarkController.text,
                    accessToken: _tokenController.text)).then(Navigator.of(context).pop);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
