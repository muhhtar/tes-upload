import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/time_capsule_model.dart';
import '../../data/repositories/time_capsule_repository.dart';
import '../auth/auth_providers.dart';

final timeCapsuleRepositoryProvider = Provider<TimeCapsuleRepository>((ref) {
  return TimeCapsuleRepository(
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
});

final timeCapsulesProvider = StreamProvider.autoDispose<List<TimeCapsuleModel>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(timeCapsuleRepositoryProvider).watchCapsules();
});
