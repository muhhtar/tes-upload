import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/media_item.dart';

class StorageRepository {
  StorageRepository({required this.firebaseStorage});

  final FirebaseStorage firebaseStorage;

  Future<MediaItem> uploadPhotoData({
    required String userId,
    required String memoryId,
    required int index,
    required Uint8List bytes,
  }) async {
    final path = 'users/$userId/memories/$memoryId/photo_$index.jpg';
    final ref = firebaseStorage.ref().child(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await task.ref.getDownloadURL();
    return MediaItem(
      type: 'photo',
      url: url,
      path: path,
      size: bytes.length,
    );
  }

  Future<MediaItem> uploadAudioData({
    required String userId,
    required String memoryId,
    required Uint8List bytes,
    int? duration,
  }) async {
    final path = 'users/$userId/memories/$memoryId/audio.m4a';
    final ref = firebaseStorage.ref().child(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'audio/mp4'),
    );
    final url = await task.ref.getDownloadURL();
    return MediaItem(
      type: 'audio',
      url: url,
      path: path,
      size: bytes.length,
      duration: duration,
    );
  }

  Future<void> deleteFile(String path) async {
    if (path.isEmpty) return;
    try {
      await firebaseStorage.ref().child(path).delete();
    } catch (_) {
      // Ignore if file was already deleted or doesn't exist
    }
  }
}
