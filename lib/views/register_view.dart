// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learningfirebase/constants/routes.dart';
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
                await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                // The reason we use pushNamed because the user might give invalid email and want to go back
                Navigator.of(context).pushNamed(verifyEmailRoute);
                final user = FirebaseAuth.instance.currentUser;
                user?.sendEmailVerification();
              } on FirebaseAuthException catch (e) {
                if (e.code == "weak-password") {
                  await showErrorDialoge(context, "Weak password");
                } else if (e.code == "email-already-in-use") {
                  await showErrorDialoge(context, "Email already in use");
                } else if (e.code == "invalid-email") {
                  await showErrorDialoge(context, "Invalid email");
                }else{
                  await showErrorDialoge(context, "Error: ${e.code}");
                }
              }catch (e){
                await showErrorDialoge(context, e.toString());
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
