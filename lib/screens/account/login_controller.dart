import 'package:flutter/material.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/providers/auth_provider.dart';
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
      try {
        // Use AuthProvider for login following new_words pattern
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.login(username, password);

        if (success) {
          // Login successful - AuthProvider will notify UI automatically
          // No manual navigation needed, InitialPage will respond to state change
        } else {
          // Show error message if login fails
          final errorMessage = authProvider.error ?? 'Login failed';
          Util.showError(scaffoldContext, errorMessage);
        }
      } catch (e) {
        Util.showError(scaffoldContext, 'An unexpected error occurred: ${e.toString()}');
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
