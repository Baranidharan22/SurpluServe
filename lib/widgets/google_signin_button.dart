import 'package:flutter/material.dart';
import 'package:surpluserve/services/auth_services.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text("Sign in with Google"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      onPressed: () => AuthService().signInWithGoogle(context),
    );
  }
}
