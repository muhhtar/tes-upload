import 'package:firebase_core/firebase_core.dart';

abstract final class FirebaseConfiguration {
  static const _apiKey = String.fromEnvironment('apiKey');
  static const _appId = String.fromEnvironment('appId');
  static const _messagingSenderId = String.fromEnvironment('messagingSenderId');
  static const _projectId = String.fromEnvironment('projectId');
  static const _authDomain = String.fromEnvironment('authDomain');
  static const _storageBucket = String.fromEnvironment('storageBucket');
  static const _measurementId = String.fromEnvironment('measurementId');

  static FirebaseOptions? get options {
    if ([
      _apiKey,
      _appId,
      _messagingSenderId,
      _projectId,
      _authDomain,
    ].any((value) => value.isEmpty)) {
      return null;
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
    );
  }
}
