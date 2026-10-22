import 'package:flutter/material.dart';

import 'auth_form_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormScreen(isRegistration: false);
  }
}
