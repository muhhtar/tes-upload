import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/firebase_configuration.dart';
import 'features/auth/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress Flutter Web Engine MouseTracker assertions in debug mode
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('mouse_tracker.dart') ||
        details.exceptionAsString().contains('_debugDuringDeviceUpdate')) {
      return;
    }
    FlutterError.presentError(details);
  };

  final options = FirebaseConfiguration.options;
  if (options == null) {
    runApp(
      ProviderScope(
        overrides: [
          firebaseInitializationErrorProvider.overrideWithValue(
            'Lengkapi Firebase options lewat dart-define saat menjalankan aplikasi. '
            'Lihat langkah setup Firebase di panduan proyek.',
          ),
        ],
        child: const LoreApp(),
      ),
    );
    return;
  }

  try {
    await Firebase.initializeApp(options: options);
  } on FirebaseException catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Firebase bootstrap',
        context: ErrorDescription('while initializing Firebase'),
      ),
    );
    runApp(
      ProviderScope(
        overrides: [
          firebaseInitializationErrorProvider.overrideWithValue(
            'Firebase belum bisa dimulai. Periksa project ID dan pengaturan Firebase, lalu coba lagi.',
          ),
        ],
        child: const LoreApp(),
      ),
    );
    return;
  }

  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (_) {
    // Standard settings fallback.
  }

  runApp(const ProviderScope(child: LoreApp()));
}
