import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/time_capsule_model.dart';

class TimeCapsuleRepository {
  TimeCapsuleRepository({required this.firestore, required this.firebaseAuth});

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _capsules =>
      firestore.collection('time_capsules');

  Future<String> createCapsule({
    required String title,
    required String note,
    required DateTime unlockAt,
    String mood = 'hangat',
  }) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('Harus login untuk membuat kapsul waktu.');
    }

    final capsule = TimeCapsuleModel(
      id: '',
      userId: userId,
      title: title.trim(),
      note: note.trim(),
      unlockAt: unlockAt,
      isOpened: false,
      mood: mood,
    );

    try {
      final doc = await _capsules
          .add(capsule.toMap())
          .timeout(const Duration(seconds: 5));
      return doc.id;
    } on TimeoutException {
      throw TimeoutException('Koneksi waktu habis saat membuat kapsul waktu.');
    }
  }

  Future<void> openCapsule(String id) async {
    try {
      await _capsules.doc(id).update({
        'is_opened': true,
        'opened_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw TimeoutException('Koneksi waktu habis.');
    }
  }

  Future<void> deleteCapsule(String id) async {
    try {
      await _capsules
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw TimeoutException('Koneksi waktu habis.');
    }
  }

  Stream<List<TimeCapsuleModel>> watchCapsules() {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return Stream.value(const []);
    }

    return _capsules
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .handleError((_) {})
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) {
                try {
                  return TimeCapsuleModel.fromMap(doc.id, doc.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<TimeCapsuleModel>()
              .toList();

          items.sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
          return items;
        });
  }
}
