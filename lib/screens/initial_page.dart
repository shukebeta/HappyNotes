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
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigateBasedOnToken();
  }

  Future<void> _navigateBasedOnToken() async {
    var navigator = Navigator.of(context);
    try {
      if (await accountService.isValidToken()) {
        await accountService.setUserSession();
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } finally {
      _isLoading = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _isLoggedIn
              ? const MainMenu()
              : const Login(title: 'Login'),
    );
  }
}
