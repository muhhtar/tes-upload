import 'package:flutter/material.dart';

import 'auth_form_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormScreen(isRegistration: true);
  }
}
