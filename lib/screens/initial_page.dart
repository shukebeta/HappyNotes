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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Validating session...'),
                ],
              ),
            );
          }

          // Show error if there's an authentication error
          if (authProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.error!,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry authentication
                      authProvider.retryAuth();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
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
