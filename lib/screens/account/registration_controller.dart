import 'package:flutter/material.dart';
import '../../dependency_injection.dart';
import '../../utils/token_utils.dart';
import '../../services/account_service.dart';
import '../main_menu.dart';

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
          scaffoldContext.showSnackBar(const SnackBar(content: Text('Registration successful')));
          navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainMenu()), (route) => false);
        } else {
          scaffoldContext.showSnackBar(SnackBar(content: Text(apiResponse.message)));
        }
      } catch (e) {
        scaffoldContext.showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
