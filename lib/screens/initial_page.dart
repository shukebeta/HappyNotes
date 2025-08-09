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
          
          // Show error if authentication initialization failed
          if (authProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry authentication
                      authProvider.initAuth();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Navigate based on authentication state
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