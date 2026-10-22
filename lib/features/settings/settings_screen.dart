import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/theme/app_dimensions.dart';
import '../auth/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _canCheckBiometrics = canCheck);
      }
    } catch (_) {}
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Konfirmasi biometrik untuk mengaktifkan kunci aplikasi',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated && mounted) {
          setState(() => _biometricEnabled = true);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autentikasi biometrik gagal.')),
          );
        }
      }
    } else {
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal keluar dari akun.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // User profile card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  user?.displayName ?? 'Pengguna Lore',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(user?.email ?? ''),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Keamanan & Privasi', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),

            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Kunci Biometrik'),
                subtitle: Text(
                  _canCheckBiometrics
                      ? 'Minta sidik jari/Face ID saat membuka aplikasi'
                      : 'Perangkat tidak mendukung atau belum mengatur biometrik',
                ),
                value: _biometricEnabled,
                onChanged: _canCheckBiometrics ? _toggleBiometrics : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Tentang Privasi', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Data Kamu Aman & Privat',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Semua kenangan, foto, dan audio disimpan secara privat. Hanya kamu yang punya akses ke kenangan milikmu.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Keluar dari Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
