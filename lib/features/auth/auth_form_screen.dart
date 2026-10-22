import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/utils/validators.dart';
import 'auth_error_message.dart';
import 'auth_providers.dart';

class AuthFormScreen extends ConsumerStatefulWidget {
  const AuthFormScreen({required this.isRegistration, super.key});

  final bool isRegistration;

  @override
  ConsumerState<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends ConsumerState<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      if (widget.isRegistration) {
        await repository.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await repository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (error) {
      _showError(error);
    } on GoogleSignInException catch (error) {
      _showError(error);
    } on PlatformException catch (error) {
      _showError(error);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!kIsWeb && mounted) context.go('/home');
    } on FirebaseAuthException catch (error) {
      _showError(error);
    } on GoogleSignInException catch (error) {
      _showError(error);
    } on PlatformException catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = authErrorMessage(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRegistration = widget.isRegistration;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Lore',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      isRegistration ? 'Bikin akun Lore' : 'Welcome back!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isRegistration
                          ? 'Mulai simpan cerita yang berarti buat kamu.'
                          : 'Masuk lagi, kenanganmu sudah menunggu.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Cerita kamu privat dan cuma kamu yang bisa akses.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_errorMessage case final message?) ...[
                      _ErrorNotice(message: message),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (isRegistration) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama panggilan',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: Validators.name,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        isRegistration
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (!isRegistration) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: const Text('Lupa password?'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: AppSpacing.lg,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isRegistration ? 'Buat akun' : 'Masuk'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Lanjutkan dengan Google'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isRegistration
                              ? 'Sudah punya akun? '
                              : 'Belum punya akun? ',
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.go(
                                  isRegistration ? '/' : '/register',
                                ),
                          child: Text(isRegistration ? 'Masuk' : 'Daftar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Text(
          message,
          style: TextStyle(color: colors.onErrorContainer),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
