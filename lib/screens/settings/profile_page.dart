import 'package:flutter/material.dart';
import 'package:happy_notes/screens/settings/profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/screens/settings/change_password_page.dart';
import 'package:happy_notes/utils/util.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Consumer<ProfileController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

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

            if (controller.currentUser != null) {
              final user = controller.currentUser!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                child: ListView(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(user.gravatar),
                        onBackgroundImageError: (_, __) {},
                        backgroundColor: Colors.grey[300],
                      ),
                      title: Text(user.username, style: Theme.of(context).textTheme.titleLarge),
                      subtitle: Text(user.email),
                    ),
                    const Divider(),

                    ListTile(
                      leading: const Icon(Icons.password),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChangePasswordPage(controller: controller)),
                        );

                        if (result == true && context.mounted) {
                           Util.showInfo(
                             ScaffoldMessenger.of(context),
                             'Password changed successfully!',
                           );
                        }
                      },
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }
}
