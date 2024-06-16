import 'package:flutter/material.dart';
import '../dependency_injection.dart';
import '../utils/token_utils.dart';
import 'home_page/home_page.dart';
import '../services/account_service.dart';

class RegistrationController {
  final tokenManager = locator<TokenUtils>();
  final accountService = locator<AccountService>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or username';
    }
    // Simple email validation
    if (!value.contains('@')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // Password length validation
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Future<void> registerUser(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final username = usernameController.text;
      final email = emailController.text;
      final password = passwordController.text;

      // Make API call to register user
      final scaffoldContext =
          ScaffoldMessenger.of(context); // Capture the context
      final navigator = Navigator.of(context);
      // Call AuthService for login
      try {
        final apiResponse =
        await accountService.register(username, email, password);
        if (apiResponse['successful']) {
          scaffoldContext.showSnackBar(
              const SnackBar(content: Text('Registration successful')));
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
          );
        } else {
          scaffoldContext
              .showSnackBar(SnackBar(content: Text(apiResponse.message)));
        }
      } catch (e) {
        scaffoldContext.showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all input fields')),
      );
    }
  }

  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}
