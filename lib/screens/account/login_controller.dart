import 'package:flutter/material.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/providers/auth_provider.dart';
import '../../dependency_injection.dart';
import '../../services/account_service.dart';
import '../../services/google_auth_service.dart';
import '../../utils/util.dart';

class LoginController {
  final tokenManager = locator<TokenUtils>();
  final accountService = locator<AccountService>();
  final googleAuthService = locator<GoogleAuthService>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  void Function(bool)? onSubmittingStateChanged;
  bool _isSubmitting = false;

  bool get googleSignInAvailable => googleAuthService.isAvailable;

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

  // Android/iOS: launches the native account picker, then completes sign-in.
  Future<void> submitGoogleSignIn(BuildContext context) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    onSubmittingStateChanged?.call(true);
    try {
      final idToken = await googleAuthService.signInWithButton();
      if (idToken == null) return; // user canceled
      if (!context.mounted) return;
      await _completeGoogleSignIn(context, idToken);
    } catch (e) {
      if (context.mounted) {
        Util.showError(ScaffoldMessenger.of(context), 'An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      _isSubmitting = false;
      onSubmittingStateChanged?.call(false);
    }
  }

  // Web: the GIS-rendered button drives sign-in itself; it hands us the
  // resulting idToken via this callback once the user completes the flow.
  Future<void> handleGoogleIdToken(BuildContext context, String idToken) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    onSubmittingStateChanged?.call(true);
    try {
      await _completeGoogleSignIn(context, idToken);
    } finally {
      _isSubmitting = false;
      onSubmittingStateChanged?.call(false);
    }
  }

  Future<void> _completeGoogleSignIn(BuildContext context, String idToken) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle(idToken);
    if (!success) {
      Util.showError(scaffoldContext, authProvider.error ?? 'Google sign-in failed');
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
