import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/main_menu.dart';
import 'package:happy_notes/providers/auth_provider.dart';
import 'account/login.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  InitialPageState createState() => InitialPageState();
}

class InitialPageState extends State<InitialPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Show loading while AuthProvider is initializing
          if (!authProvider.isInitialized || authProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Following new_words AuthWrapper pattern: simple state-based navigation
          if (authProvider.isAuthenticated) {
            return const MainMenu();
          } else {
            return const Login(title: 'Login');
          }
        },
      ),
    );
  }
}
