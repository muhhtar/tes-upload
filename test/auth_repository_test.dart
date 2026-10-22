import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lore/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockGoogleSignIn googleSignIn;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(GoogleAuthProvider());
  });

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    googleSignIn = _MockGoogleSignIn();
    repository = AuthRepository(
      firebaseAuth: firebaseAuth,
      googleSignIn: googleSignIn,
      isWeb: true,
    );
  });

  test('web Google sign-in starts a Firebase redirect', () async {
    when(
      () => firebaseAuth.signInWithRedirect(any()),
    ).thenAnswer((_) async {});

    await repository.signInWithGoogle();

    verify(
      () => firebaseAuth.signInWithRedirect(any()),
    ).called(1);
    verifyNever(() => firebaseAuth.signInWithPopup(any()));
  });

  test('web auth state handles redirect result before auth state', () async {
    final credential = _MockUserCredential();
    final user = _MockUser();
    when(
      () => firebaseAuth.getRedirectResult(),
    ).thenAnswer((_) async => credential);
    when(
      () => firebaseAuth.authStateChanges(),
    ).thenAnswer((_) => Stream.value(user));

    expect(await repository.authStateChanges.toList(), [user]);

    verifyInOrder([
      () => firebaseAuth.getRedirectResult(),
      () => firebaseAuth.authStateChanges(),
    ]);
  });

  test('sign in trims the email before sending it to Firebase', () async {
    final credential = _MockUserCredential();
    when(
      () => firebaseAuth.signInWithEmailAndPassword(
        email: 'rani@example.com',
        password: 'lore123',
      ),
    ).thenAnswer((_) async => credential);

    final result = await repository.signIn(
      email: ' rani@example.com ',
      password: 'lore123',
    );

    expect(result, same(credential));
    verify(
      () => firebaseAuth.signInWithEmailAndPassword(
        email: 'rani@example.com',
        password: 'lore123',
      ),
    ).called(1);
  });

  test(
    'registration creates the Firebase account and sets its display name',
    () async {
      final credential = _MockUserCredential();
      final user = _MockUser();
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: 'rani@example.com',
          password: 'lore123',
        ),
      ).thenAnswer((_) async => credential);
      when(() => credential.user).thenReturn(user);
      when(() => user.updateDisplayName('Rani')).thenAnswer((_) async {});

      final result = await repository.register(
        name: ' Rani ',
        email: ' rani@example.com ',
        password: 'lore123',
      );

      expect(result, same(credential));
      verify(() => user.updateDisplayName('Rani')).called(1);
    },
  );
}
