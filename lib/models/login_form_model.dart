
import 'package:flutter/material.dart';

class LoginFormModel {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  bool submitForm(BuildContext context) {
    if (formKey.currentState!.validate()) {
      // Perform form submission logic
      return true; // Form is valid
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill input')),
      );
      return false; // Form is invalid
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
