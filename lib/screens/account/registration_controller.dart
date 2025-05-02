import 'package:flutter/material.dart';
import '../../dependency_injection.dart';
import '../../utils/token_utils.dart';
import '../../services/account_service.dart';
import '../main_menu.dart';
import '../../utils/util.dart'; // Import Util

class RegistrationController {
  final tokenManager = locator<TokenUtils>();
  final accountService = locator<AccountService>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  void Function(bool)? onSubmittingStateChanged;
  bool _isSubmitting = false;

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
    if (_isSubmitting) return;
    if (formKey.currentState!.validate()) {
      _isSubmitting = true;
      onSubmittingStateChanged?.call(true);
      final username = usernameController.text;
      final email = emailController.text;
      final password = passwordController.text;

      // Make API call to register user
      final scaffoldContext = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        final apiResponse = await accountService.register(username, email, password);
        if (apiResponse['successful']) {
          Util.showInfo(scaffoldContext, 'Registration successful'); // Replaced showSnackBar
          navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainMenu()), (route) => false);
        } else {
          Util.showError(scaffoldContext, apiResponse['message']); // Replaced showSnackBar
        }
      } catch (e) {
        Util.showError(scaffoldContext, e.toString()); // Replaced showSnackBar
      } finally {
        _isSubmitting = false;
        onSubmittingStateChanged?.call(false);
      }
    }
  }

  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}
