import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Format email-nya belum pas.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'Email atau password-nya belum cocok.',
      'email-already-in-use' => 'Email ini sudah punya akun. Coba masuk ya.',
      'weak-password' => 'Password-nya terlalu gampang ditebak.',
      'user-disabled' => 'Akun ini sedang nonaktif. Hubungi support ya.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi sebentar ya.',
      'network-request-failed' => 'Koneksi internet lagi bermasalah.',
      'operation-not-allowed' =>
        'Metode masuk ini belum diaktifkan di Firebase Console.',
      'popup-closed-by-user' || 'web-context-cancelled' =>
        'Proses masuk Google dibatalkan.',
      _ => 'Yah, proses autentikasi belum berhasil. Coba lagi ya.',
    };
  }

  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Proses masuk Google dibatalkan.';
    }
    return 'Google Sign-In lagi bermasalah. Coba lagi ya.';
  }

  return 'Yah, ada kendala. Coba lagi ya.';
}
