import 'package:flutter/material.dart';
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/utils/token_utils.dart';
import '../../dependency_injection.dart';
import '../../services/account_service.dart';
import '../../utils/util.dart';

class LoginController {
  final tokenManager = locator<TokenUtils>();
  final accountService = locator<AccountService>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  void Function(bool)? onSubmittingStateChanged;
  bool _isSubmitting = false;

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
    if (_isSubmitting) return;
    if (formKey.currentState!.validate()) {
      _isSubmitting = true;
      onSubmittingStateChanged?.call(true);
      final username = emailController.text;
      final password = passwordController.text;

      // capture the context before entering await
      final scaffoldContext = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        // Call AuthService for login
        final apiResponse = await accountService.login(username, password);

        if (apiResponse['successful']) {
          // Navigate to the home page
          navigator.pushReplacement(
            MaterialPageRoute(builder: (context) => const InitialPage()));
        } else {
          // Show error message if login fails
          Util.showError(scaffoldContext, 'Login failed: ${apiResponse['message']}'); // Replaced showSnackBar
        }

      } catch (e) {
        Util.showError(scaffoldContext, e.toString());
      } finally {
        _isSubmitting = false;
        onSubmittingStateChanged?.call(false);
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
