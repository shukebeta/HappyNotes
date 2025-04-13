import 'package:flutter/material.dart';
import 'registration_controller.dart';

class Registration extends StatefulWidget {
  const Registration({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formModel = RegistrationController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _formModel.onSubmittingStateChanged = (isSubmitting) {
      setState(() {
        _isSubmitting = isSubmitting;
      });
    };
  }

  @override
  void dispose() {
    _formModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Form(
        key: _formModel.formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: _formModel.usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Username",
                  ),
                  validator: _formModel.validateUsername,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: _formModel.emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                  ),
                  validator: _formModel.validateEmail,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: _formModel.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                  ),
                  validator: _formModel.validatePassword,
                  onFieldSubmitted: (_) => _formModel.registerUser(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            _formModel.registerUser(context);
                          },
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Register'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
