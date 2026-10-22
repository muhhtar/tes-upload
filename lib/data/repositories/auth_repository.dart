import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.isWeb,
    this.googleClientId,
    this.googleServerClientId,
  });

  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final bool isWeb;
  final String? googleClientId;
  final String? googleServerClientId;
  bool _googleSignInInitialized = false;

  Stream<User?> get authStateChanges async* {
    if (isWeb) {
      await firebaseAuth.getRedirectResult();
    }
    yield* firebaseAuth.authStateChanges();
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  Future<void> signInWithGoogle() async {
    if (isWeb) {
      await firebaseAuth.signInWithRedirect(GoogleAuthProvider());
      return;
    }

    if (!_googleSignInInitialized) {
      await googleSignIn.initialize(
        clientId: googleClientId,
        serverClientId: googleServerClientId,
      );
      _googleSignInInitialized = true;
    }

    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google tidak mengembalikan token masuk.',
      );
    }

    await firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    if (!isWeb) {
      await googleSignIn.signOut();
    }
  }
}
