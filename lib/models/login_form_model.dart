
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import '../screens/home-page.dart';

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
  // Function to make API call
  Future<void> _verifyCredentials(String username, String password, Function(bool, String) callback) async {
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
      var success = await _verifyCredentials(emailController.text, passwordController.text, (bool result, String tokenOrErrorMessage) {
        if (result) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HomePage(
                  email: emailController.text,
                )),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tokenOrErrorMessage)),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill input')),
      );
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
