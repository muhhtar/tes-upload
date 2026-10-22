import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore/data/models/memory_model.dart';
import 'package:lore/data/repositories/memory_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

// Mocktail dipakai untuk memeriksa payload saat menulis ke Firestore.
// ignore: subtype_of_sealed_class
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// Mocktail memudahkan verifikasi payload dokumen tanpa Firebase Emulator.
// ignore: subtype_of_sealed_class
class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late _MockFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late MemoryRepository repository;

  setUp(() {
    firestore = _MockFirestore();
    firebaseAuth = _MockFirebaseAuth();
    repository = MemoryRepository(
      firestore: firestore,
      firebaseAuth: firebaseAuth,
    );
  });

  test('refuses to write when there is no signed-in user', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    await expectLater(
      repository.createMemory(
        title: 'Kenangan',
        story: '',
        memoryDate: const MemoryDate(year: 2024, precision: 'year'),
        category: 'Lainnya',
        mood: 'hangat',
      ),
      throwsA(isA<StateError>()),
    );
    verifyNever(() => firestore.collection('memories'));
  });

  test('writes a memory owned by the current Firebase user', () async {
    final user = _MockUser();
    final collection = _MockCollection();
    final document = _MockDocumentReference();
    Map<String, dynamic>? capturedData;
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('current-user-id');
    when(() => firestore.collection('memories')).thenReturn(collection);
    when(() => collection.add(any<Map<String, dynamic>>()))
        .thenAnswer((invocation) async {
          capturedData =
              invocation.positionalArguments.single as Map<String, dynamic>;
          return document;
        });
    when(() => document.id).thenReturn('new-memory-id');

    final id = await repository.createMemory(
      title: '  Hari di pantai ',
      story: ' Cerita kecil ',
      memoryDate: const MemoryDate(
        year: 2024,
        month: 3,
        day: 9,
        precision: 'day',
      ),
      category: 'Liburan',
      mood: 'hangat',
    );

    expect(id, 'new-memory-id');
    expect(capturedData?['user_id'], 'current-user-id');
    expect(capturedData?['title'], 'Hari di pantai');
    expect(capturedData?['story'], 'Cerita kecil');
    expect(capturedData?['memory_date']['sort_key'], 20240309);
    verify(() => firestore.collection('memories')).called(1);
  });

  test('rejects invalid memory title before writing', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    await expectLater(
      repository.createMemory(
        title: '   ',
        story: '',
        memoryDate: const MemoryDate(year: 2024, precision: 'year'),
        category: 'Lainnya',
        mood: 'hangat',
      ),
      throwsA(isA<ArgumentError>()),
    );
    verifyNever(() => firestore.collection('memories'));
  });

  test('rejects a date that does not match its precision', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    await expectLater(
      repository.createMemory(
        title: 'Kenangan',
        story: '',
        memoryDate: const MemoryDate(
          year: 2024,
          month: 2,
          day: 30,
          precision: 'day',
        ),
        category: 'Lainnya',
        mood: 'hangat',
      ),
      throwsA(isA<ArgumentError>()),
    );
    verifyNever(() => firestore.collection('memories'));
  });

  test('returns empty stream when user is not signed in', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    final stream = repository.watchRecentMemories();

    expect(await stream.first, isEmpty);
    verifyNever(() => firestore.collection('memories'));
  });
}
