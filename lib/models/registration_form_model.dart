import 'dart:convert';

import 'package:flutter/material.dart';

import '../apis/auth_api.dart';
import '../screens/home-page.dart';
import '../services/account_service.dart';

class RegistrationFormModel {
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
        await AccountService.register(username, email, password);
        if (apiResponse['successful']) {
          await AccountService.saveToken(apiResponse['data']['token']);
          scaffoldContext.showSnackBar(
              const SnackBar(content: Text('Registration successful')));
          navigator.push(
            MaterialPageRoute(builder: (context) => HomePage()),
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
