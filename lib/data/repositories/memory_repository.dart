import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/media_item.dart';
import '../models/memory_model.dart';

class MemoryRepository {
  MemoryRepository({required this.firestore, required this.firebaseAuth});

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  static const _categories = {
    'Nasihat',
    'Liburan',
    'Lucu',
    'Keluarga',
    'Teman',
    'Lainnya',
  };
  static const _moods = {'hangat', 'haru', 'lucu', 'rindu', 'bangga'};

  CollectionReference<Map<String, dynamic>> get _memories =>
      firestore.collection('memories');

  Future<String> createMemory({
    required String title,
    required String story,
    required MemoryDate memoryDate,
    required String category,
    required String mood,
    List<MediaItem> media = const [],
  }) async {
    final normalizedTitle = title.trim();
    final normalizedStory = story.trim();
    _validateInputs(
      title: normalizedTitle,
      story: normalizedStory,
      category: category,
      mood: mood,
      memoryDate: memoryDate,
    );

    final userId = _currentUserId;
    final memory = MemoryModel(
      id: '',
      userId: userId,
      title: normalizedTitle,
      story: normalizedStory,
      memoryDate: memoryDate,
      category: category,
      mood: mood,
      isFavorite: false,
      createdAt: null,
      media: media,
    );
    try {
      final document = await _memories
          .add(memory.toMap())
          .timeout(const Duration(seconds: 5));
      return document.id;
    } on TimeoutException {
      throw TimeoutException('Koneksi waktu habis saat menyimpan kenangan. Periksa koneksi internetmu.');
    }
  }

  Future<void> updateMemory({
    required String id,
    required String title,
    required String story,
    required MemoryDate memoryDate,
    required String category,
    required String mood,
    List<MediaItem>? media,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedStory = story.trim();
    _validateInputs(
      title: normalizedTitle,
      story: normalizedStory,
      category: category,
      mood: mood,
      memoryDate: memoryDate,
    );

    final data = <String, dynamic>{
      'title': normalizedTitle,
      'story': normalizedStory,
      'memory_date': memoryDate.toMap(),
      'category': category,
      'mood': mood,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (media != null) {
      data['media'] = media.map((m) => m.toMap()).toList();
    }

    try {
      await _memories
          .doc(id)
          .update(data)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw TimeoutException('Koneksi waktu habis saat memperbarui kenangan.');
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await _memories
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw TimeoutException('Koneksi waktu habis saat menghapus kenangan.');
    }
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await _memories.doc(id).update({
        'is_favorite': isFavorite,
        'updated_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> removeIllustration(String id) async {
    try {
      await _memories.doc(id).update({
        'ai_illustration': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Stream<MemoryModel?> watchMemory(String id) {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return Stream.error(StateError('Harus login untuk membuka kenangan.'));
    }

    return _memories
        .doc(id)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          final data = doc.data()!;
          if (data['user_id'] != userId) return null;
          return MemoryModel.fromMap(doc.id, data);
        });
  }

  Stream<List<MemoryModel>> watchMemories({String? category, int limit = 100}) {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return Stream.value(const []);
    }

    return _memories
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => MemoryModel.fromMap(doc.id, doc.data()))
              .where((m) => category == null || category == 'Semua' || m.category == category)
              .toList(growable: false);

          final sorted = List<MemoryModel>.from(items)
            ..sort(
              (a, b) => b.memoryDate.sortKey.compareTo(a.memoryDate.sortKey),
            );

          if (sorted.length > limit) {
            return sorted.sublist(0, limit);
          }
          return sorted;
        });
  }

  Stream<List<MemoryModel>> watchRecentMemories({int limit = 20}) {
    return watchMemories(limit: limit);
  }

  String get _currentUserId {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('Harus login untuk membuka kenangan.');
    }
    return userId;
  }

  void _validateInputs({
    required String title,
    required String story,
    required String category,
    required String mood,
    required MemoryDate memoryDate,
  }) {
    if (title.isEmpty || title.length > 100) {
      throw ArgumentError.value(title, 'title', 'Must be 1 to 100 characters.');
    }
    if (story.length > 5000) {
      throw ArgumentError.value(
        story,
        'story',
        'Must be at most 5000 characters.',
      );
    }
    if (!_categories.contains(category)) {
      throw ArgumentError.value(
        category,
        'category',
        'Unknown memory category.',
      );
    }
    if (!_moods.contains(mood)) {
      throw ArgumentError.value(mood, 'mood', 'Unknown memory mood.');
    }
    if (!_isValidMemoryDate(memoryDate)) {
      throw ArgumentError.value(
        memoryDate,
        'memoryDate',
        'Memory date does not match its precision.',
      );
    }
  }

  bool _isValidMemoryDate(MemoryDate date) {
    if (date.year < 1 || date.year > 9999) return false;
    return switch (date.precision) {
      'year' => date.month == null && date.day == null,
      'month' =>
        date.month != null &&
            date.month! >= 1 &&
            date.month! <= 12 &&
            date.day == null,
      'day' =>
        date.month != null &&
            date.month! >= 1 &&
            date.month! <= 12 &&
            date.day != null &&
            date.day! >= 1 &&
            date.day! <= DateTime(date.year, date.month! + 1, 0).day,
      _ => false,
    };
  }
}
