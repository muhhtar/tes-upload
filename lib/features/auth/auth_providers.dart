import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn.instance,
    isWeb: kIsWeb,
    googleClientId: const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
    googleServerClientId: const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final firebaseInitializationErrorProvider = Provider<String?>((ref) => null);
