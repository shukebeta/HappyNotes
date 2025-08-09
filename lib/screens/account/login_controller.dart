import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/providers/auth_provider.dart';
import '../../utils/util.dart';

class LoginController {
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
        // Use AuthProvider for login instead of AccountService directly
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.login(username, password);

        if (success) {
          // SUCCESS: Don't reset loading state - widget will be disposed during auto-navigation
          // The user will be redirected to MainMenu automatically when auth state changes
        } else {
          // FAILURE: Reset loading state so user can retry
          _isSubmitting = false;
          onSubmittingStateChanged?.call(false);
          
          final errorMessage = authProvider.error ?? 'Login failed';
          Util.showError(scaffoldContext, errorMessage);
        }

      } catch (e) {
        // ERROR: Reset loading state so user can retry
        _isSubmitting = false;
        onSubmittingStateChanged?.call(false);
        
        Util.showError(scaffoldContext, e.toString());
      }
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
