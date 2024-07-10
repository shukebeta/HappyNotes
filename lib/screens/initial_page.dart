import 'package:flutter/material.dart';
import 'package:happy_notes/screens/main_menu.dart';
import '../dependency_injection.dart';
import '../services/account_service.dart';
import 'account/login.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  InitialPageState createState() => InitialPageState();
}

class InitialPageState extends State<InitialPage> {
  final AccountService accountService = locator<AccountService>();

  Future<bool> _checkToken() async {
    try {
      if (await accountService.isValidToken()) {
        await accountService.setUserSession();
        return true;
      }
    } catch (e) {
      // Handle the error appropriately
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _checkToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('An error occurred: ${snapshot.error}'),
            );
          } else if (snapshot.hasData && snapshot.data!) {
            return const MainMenu();
          } else {
            return const Login(title: 'Login');
          }
        },
      ),
    );
  }
}