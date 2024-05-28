import 'package:flutter/material.dart';
import 'package:happy_notes/utils/token_utils.dart';

import '../dependency_injection.dart';
import 'home_page.dart';
import '../services/account_service.dart';
import '../utils/util.dart';

class LoginController {
  final tokenManager = locator<TokenUtils>();
  final accountService = locator<AccountService>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or username';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
  // Function to make API call
  Future<void> submitForm(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final username = emailController.text;
      final password = passwordController.text;

      // capture the context before entering await
      final scaffoldContext = ScaffoldMessenger.of(context); // Capture the context
      final navigator = Navigator.of(context);
      try {
        // Call AuthService for login
        final apiResponse = await accountService.login(username, password);

        if (apiResponse['successful']) {
          // Navigate to the home page
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
          );
        } else {
          // Show error message if login fails
          scaffoldContext.showSnackBar(
            SnackBar(content: Text('Login failed: ${apiResponse['message']}')),
          );
        }

      } catch (e) {
        Util.showError(scaffoldContext, e.toString());
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
