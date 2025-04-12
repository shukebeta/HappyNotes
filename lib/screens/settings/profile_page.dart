import 'package:flutter/material.dart';
import 'package:happy_notes/screens/trash_bin_page.dart';
import 'package:happy_notes/screens/settings/account_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Account settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Trash bin'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrashBinPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
