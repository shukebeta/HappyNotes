import 'package:flutter/material.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  AccountSettingsPageState createState() => AccountSettingsPageState();
}

class AccountSettingsPageState extends State<AccountSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: const Center(
        child: Text('Account settings content will be displayed here'),
      ),
    );
  }
}
