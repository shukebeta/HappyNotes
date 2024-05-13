import 'package:flutter/material.dart';

import '../screens/home-page.dart';
import '../services/account_service.dart';

class LoginFormModel {
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
      // Call AuthService for login
      final apiResponse = await AccountService.login(username, password);

      if (apiResponse['successful']) {
        // Save the access token
        await AccountService.saveToken(apiResponse['data']['token']);

        // Navigate to the home page
        navigator.push(
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Show error message if login fails
        scaffoldContext.showSnackBar(
          SnackBar(content: Text('Login failed: ${apiResponse.message}')),
        );
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
