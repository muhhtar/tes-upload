import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/memory_model.dart';
import '../../data/repositories/illustration_repository.dart';
import '../../data/repositories/memory_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../auth/auth_providers.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(firebaseStorage: FirebaseStorage.instance);
});

final illustrationRepositoryProvider = Provider<IllustrationRepository>((ref) {
  return IllustrationRepository(functions: FirebaseFunctions.instance);
});

final recentMemoriesProvider =
    StreamProvider.autoDispose<List<MemoryModel>>((ref) {
      final user = ref.watch(authStateProvider).asData?.value;
      if (user == null) {
        return Stream.value(const []);
      }
      return ref.watch(memoryRepositoryProvider).watchRecentMemories();
    });

class TimelineCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Semua';

  void setCategory(String category) {
    state = category;
  }
}

final timelineCategoryProvider =
    NotifierProvider<TimelineCategoryNotifier, String>(
      () => TimelineCategoryNotifier(),
    );

final timelineMemoriesProvider =
    StreamProvider.autoDispose<List<MemoryModel>>((ref) {
      final user = ref.watch(authStateProvider).asData?.value;
      if (user == null) {
        return Stream.value(const []);
      }
      final category = ref.watch(timelineCategoryProvider);
      return ref.watch(memoryRepositoryProvider).watchMemories(category: category);
    });

final memoryDetailProvider =
    StreamProvider.autoDispose.family<MemoryModel?, String>((ref, id) {
      final user = ref.watch(authStateProvider).asData?.value;
      if (user == null) {
        return Stream.value(null);
      }
      return ref.watch(memoryRepositoryProvider).watchMemory(id);
    });
