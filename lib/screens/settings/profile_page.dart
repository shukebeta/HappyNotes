import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/account_settings_page.dart';
import 'package:happy_notes/screens/settings/profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/settings/change_password_page.dart';

class ProfilePage extends StatelessWidget { // Changed to StatelessWidget
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the ProfileController
    return ChangeNotifierProvider(
      create: (_) => ProfileController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        // Use Consumer to rebuild UI based on controller changes
        body: Consumer<ProfileController>(
          builder: (context, controller, child) {
            // Loading State
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error State
            if (controller.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    controller.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // Data State (User Info)
            if (controller.currentUser != null) {
              final user = controller.currentUser!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                child: ListView(
                  children: [
                    // --- Account Info Section ---
                    ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(user.gravatar),
                        onBackgroundImageError: (_, __) {
                          // Optional: Display fallback icon on error
                        },
                        // Optional: Add a fallback background color or icon
                        backgroundColor: Colors.grey[300],
                      ),
                      title: Text(user.username, style: Theme.of(context).textTheme.titleLarge),
                      subtitle: Text(user.email),
                    ),
                    const Divider(),

                    // --- Actions Section ---
                    ListTile(
                      leading: const Icon(Icons.password),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          // Pass the controller instance from the Consumer builder
                          MaterialPageRoute(builder: (context) => ChangePasswordPage(controller: controller)),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings), // Added icon
                      title: const Text('Account settings'),
                      trailing: const Icon(Icons.chevron_right), // Added chevron
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
                        );
                      },
                    ),
                    // Add other settings/actions here if needed
                  ],
                ),
              );
            }

            // Fallback (should ideally not be reached if logic is correct)
            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }
}
