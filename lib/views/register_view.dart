// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:learningfirebase/constants/routes.dart';
import 'package:learningfirebase/services/auth/auth_exceptions.dart';
import 'package:learningfirebase/services/auth/auth_service.dart';
import 'package:learningfirebase/views/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: "Enter your email"),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(hintText: "Enter your password"),
          ),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                await AuthService
                    .firebase()
                    .createUser(
                      email: email,
                      password: password,
                    );
                // The reason we use pushNamed because the user might give invalid email and want to go back
                AuthService.firebase().sendEmailVerification();
                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on WeakPasswordAuthException {
                await showErrorDialoge(context, "Weak password");
              } on EmailAlreadyInUseAuthException {
                await showErrorDialoge(context, "Email already in use");
              } on InvalidEmailAuthException {
                await showErrorDialoge(context, "Invalid email");
              } on GenericAuthException {
                await showErrorDialoge(context, "Failed to register");
              }
            },
            child: const Text("Register"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(loginRoute, (_) => false);
            },
            child: const Text("Already registered? Login here"),
          ),
        ],
      ),
    );
  }
}
