// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:learningfirebase/constants/routes.dart';
import 'package:learningfirebase/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Text("We've sent a verification email to:"),
          Text("\nIf you haven't received a verification email yet, press the button below"),
          TextButton(
            onPressed: () async {
              AuthService.firebase().sendEmailVerification();
            },
            child: const Text("Send Email Verification"),
          ),
          TextButton(onPressed: () async {
            await AuthService.firebase().logOut();
            Navigator.of(context).pushNamedAndRemoveUntil(
              registerRoute,
              (route) => false,
            );
          }, child: const Text("Restart")),
        ],
      ),
    );
  }
}
