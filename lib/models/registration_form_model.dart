import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../screens/home-page.dart';

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

  Future<void> register(String username, String email, String password, Function(bool, String) callback) async {
    final url = Uri.parse('http://localhost:5012/account/register');
    final response = await http.post(
      url,
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    final jsonResponse = json.decode(response.body);
    final successful = jsonResponse['successful'];

    if (jsonResponse['successful']) {
      callback(true, jsonResponse['data']['token']);
    } else {
      // Unsuccessful response
      callback(false, jsonResponse['message']);
    }
  }

  Future<void> registerUser(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final username = usernameController.text;
      final email = emailController.text;
      final password = passwordController.text;

      // Make API call to register user
      try {
        await register(username, email, password, (successful, tokenOrErrorMessage) {
          if (successful) {
            // Registration successful, navigate to home page or display success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage()),
            );
          } else {
            // Registration unsuccessful, display error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tokenOrErrorMessage)),
            );
          }
        });
      } catch (e) {
        // Error occurred during API call
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error registering user')),
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
