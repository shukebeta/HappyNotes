// common_input_dialog.dart
import 'package:flutter/material.dart';

class CommonInputDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final String confirmButtonText;
  final String cancelButtonText;
  final List<String? Function(String?)> validators;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffixIcon;
  final VoidCallback? onCancel;

  const CommonInputDialog({
    Key? key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.confirmButtonText = 'OK',
    this.cancelButtonText = 'Cancel',
    this.validators = const [],
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.maxLength,
    this.obscureText = false,
    this.suffixIcon,
    this.onCancel,
  }) : super(key: key);

  @override
  State<CommonInputDialog> createState() => _CommonInputDialogState();

  /// Convenience method to show the dialog and return the result
  /// Returns the entered text if confirmed, null if cancelled or dismissed
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? hintText,
    String? initialValue,
    String confirmButtonText = 'OK',
    String cancelButtonText = 'Cancel',
    List<String? Function(String?)> validators = const [],
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => CommonInputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        validators: validators,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLength: maxLength,
        obscureText: obscureText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _CommonInputDialogState extends State<CommonInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validateInput(String? value) {
    for (final validator in widget.validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  void _submitForm() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Small delay to show loading state
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop(_controller.text.trim());
      }
    });
  }

  void _cancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          validator: _validateInput,
          onFieldSubmitted: (_) {
            if (!_isSubmitting) {
              _submitForm();
            }
          },
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          enabled: !_isSubmitting,
          maxLength: widget.maxLength,
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: widget.suffixIcon,
            counterText: widget.maxLength != null ? null : '',
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _cancel,
          child: Text(widget.cancelButtonText),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.confirmButtonText),
        ),
      ],
    );
  }
}

// Validator utilities
class InputValidators {
  /// Validates that the input is not null or empty
  /// Returns null if valid, error message if invalid
  static String? Function(String?) required([String? message]) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message ?? 'This field is required.';
      }
      return null; // Valid input
    };
  }

  /// Validates that the input doesn't exceed maximum length
  /// Returns null if valid, error message if invalid
  static String? Function(String?) maxLength(int max, [String? message]) {
    return (value) {
      if (value != null && value.trim().length > max) {
        return message ?? 'Cannot exceed $max characters.';
      }
      return null; // Valid input
    };
  }

  /// Validates that the input meets minimum length requirement
  /// Returns null if valid, error message if invalid
  static String? Function(String?) minLength(int min, [String? message]) {
    return (value) {
      if (value != null && value.trim().length < min) {
        return message ?? 'Must be at least $min characters.';
      }
      return null; // Valid input
    };
  }

  /// Validates that the input contains at least one letter
  /// Returns null if valid, error message if invalid
  static String? Function(String?) containsLetter([String? message]) {
    return (value) {
      if (value != null && !value.trim().contains(RegExp(r'[a-zA-Z\p{L}]', unicode: true))) {
        return message ?? 'Must contain at least one letter.';
      }
      return null; // Valid input
    };
  }

  /// Validates that the input matches a specific pattern
  /// Returns null if valid, error message if invalid
  static String? Function(String?) pattern(RegExp regex, [String? message]) {
    return (value) {
      if (value != null && !regex.hasMatch(value)) {
        return message ?? 'Invalid format.';
      }
      return null; // Valid input
    };
  }

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? Function(String?) email([String? message]) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    return pattern(emailRegex, message ?? 'Please enter a valid email address.');
  }

  /// Combines multiple validators - returns first error found or null if all pass
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null; // All validators passed
    };
  }
}
