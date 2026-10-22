import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_gate.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/auth/firebase_setup_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/capsule/time_capsule_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/illustration/lore_studio_screen.dart';
import '../../features/memories/memory_detail_screen.dart';
import '../../features/memories/memory_form_screen.dart';
import '../../features/memories/timeline_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseInitializationError = ref.watch(
    firebaseInitializationErrorProvider,
  );
  final router = GoRouter(
    redirect: (context, state) {
      final path = state.uri.path;
      if (firebaseInitializationError != null || path == '/') return null;

      final isPublicPath = {
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      }.contains(path);
      final authState = ref.read(authStateProvider);
      if (authState.isLoading || authState.hasError) {
        return isPublicPath ? null : '/';
      }

      final isSignedIn = authState.asData?.value != null;
      if (!isSignedIn && !isPublicPath) return '/login';
      if (isSignedIn && isPublicPath) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (firebaseInitializationError != null) {
            return FirebaseSetupScreen(message: firebaseInitializationError);
          }
          return const AuthGate();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/capsule',
        builder: (context, state) => const TimeCapsuleScreen(),
      ),
      GoRoute(
        path: '/memories/new',
        builder: (context, state) => const MemoryFormScreen(),
      ),
      GoRoute(
        path: '/memory/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return const _InvalidRouteScreen();
          }
          return MemoryDetailScreen(memoryId: id);
        },
      ),
      GoRoute(
        path: '/memory/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return const _InvalidRouteScreen();
          }
          return MemoryFormScreen(memoryId: id);
        },
      ),
      GoRoute(
        path: '/studio/:memoryId',
        builder: (context, state) {
          final memoryId = state.pathParameters['memoryId'];
          if (memoryId == null || memoryId.isEmpty) {
            return const _InvalidRouteScreen();
          }
          return LoreStudioScreen(memoryId: memoryId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.listen(authStateProvider, (previous, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

class _InvalidRouteScreen extends StatelessWidget {
  const _InvalidRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Halaman ini tidak tersedia.')),
    );
  }
}
