import 'package:flutter/material.dart';
import 'package:happy_notes/screens/main_menu.dart';
import '../dependency_injection.dart';
import '../services/account_service.dart';
import 'home_page/home_page.dart';
import 'account/login.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  InitialPageState createState() => InitialPageState();
}

class InitialPageState extends State<InitialPage> {
  final accountService = locator<AccountService>();

  @override
  void initState() {
    super.initState();
    _navigateBasedOnToken();
  }

  Future<void> _navigateBasedOnToken() async {
    var navigator = Navigator.of(context);
    if (await accountService.isValidToken()) {
      accountService.setUserSession();
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenu()),
      );
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const Login(title: 'Login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
