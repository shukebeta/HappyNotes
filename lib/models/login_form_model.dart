
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import '../screens/home-page.dart';
import '../services/auth-service.dart';

class LoginFormModel {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or username';
    }
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
  }
  // Function to make API call
  Future<void> verifyCredentials(String username, String password, Function(bool, String) callback) async {
    final url = Uri.parse('http://localhost:5012/account/login');
    final response = await http.post(
      url,
      body: jsonEncode({'username': username, 'password': password}),
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

  Future<void> submitForm(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final username = emailController.text;
      final password = passwordController.text;

      // Call AuthService for login
      final token = await AuthService.login(username, password);

      if (token != null) {
        // Save the access token
        await AuthService.saveToken(token);

        // Navigate to the home page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Show error message if login fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
