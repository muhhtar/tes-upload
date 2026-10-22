import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore/app.dart';
import 'package:lore/data/models/memory_model.dart';
import 'package:lore/data/repositories/auth_repository.dart';
import 'package:lore/data/repositories/memory_repository.dart';
import 'package:lore/features/auth/auth_providers.dart';
import 'package:lore/features/memories/memory_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockMemoryRepository extends Mock implements MemoryRepository {}

class _MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MemoryDate(year: 2024, precision: 'year'));
  });

  testWidgets('renders the Lore starter screen', (tester) async {
    final authRepository = _MockAuthRepository();
    when(() => authRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const LoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Masuk lagi, kenanganmu sudah menunggu.'), findsOneWidget);
  });

  testWidgets('opens the registration form from login', (tester) async {
    final authRepository = _MockAuthRepository();
    when(() => authRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const LoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Daftar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Bikin akun Lore'), findsOneWidget);
    expect(find.text('Nama panggilan'), findsOneWidget);
  });

  testWidgets('opens the new memory form from the home screen', (tester) async {
    final authRepository = _MockAuthRepository();
    final memoryRepository = _MockMemoryRepository();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-id');
    when(() => user.displayName).thenReturn('Rani');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          recentMemoriesProvider.overrideWith(
            (ref) => Stream.value(const <MemoryModel>[]),
          ),
        ],
        child: const LoreApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lore'), findsOneWidget);
    await tester.tap(find.text('Kenangan baru'));
    await tester.pumpAndSettle();

    expect(find.text('Tulis ceritanya, biar tetap ada.'), findsOneWidget);
    expect(find.text('Judul kenangan'), findsOneWidget);
    expect(find.text('Simpan kenangan'), findsOneWidget);
  });

  testWidgets('bottom navigation moves between main app screens', (
    tester,
  ) async {
    final authRepository = _MockAuthRepository();
    final memoryRepository = _MockMemoryRepository();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-id');
    when(() => user.displayName).thenReturn('Rani');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          recentMemoriesProvider.overrideWith(
            (ref) => Stream.value(const <MemoryModel>[]),
          ),
          timelineMemoriesProvider.overrideWith(
            (ref) => Stream.value(const <MemoryModel>[]),
          ),
        ],
        child: const LoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lore'), findsOneWidget);

    await tester.tap(find.text('Linimasa').last);
    await tester.pumpAndSettle();
    expect(find.text('Linimasa Kenangan'), findsOneWidget);

    await tester.tap(find.text('Pengaturan').last);
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsNWidgets(2));
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Terang'), findsOneWidget);
    expect(find.text('Gelap'), findsOneWidget);
  });

  testWidgets('validates the required memory title', (tester) async {
    final authRepository = _MockAuthRepository();
    final memoryRepository = _MockMemoryRepository();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-id');
    when(() => user.displayName).thenReturn('Rani');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          recentMemoriesProvider.overrideWith(
            (ref) => Stream.value(const <MemoryModel>[]),
          ),
        ],
        child: const LoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kenangan baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan kenangan'));
    await tester.pumpAndSettle();

    expect(find.text('Judul kenangannya belum diisi.'), findsOneWidget);
    verifyNever(
      () => memoryRepository.createMemory(
        title: any(named: 'title'),
        story: any(named: 'story'),
        memoryDate: any(named: 'memoryDate'),
        category: any(named: 'category'),
        mood: any(named: 'mood'),
      ),
    );
  });

  testWidgets('saves a valid memory from the create form', (tester) async {
    final authRepository = _MockAuthRepository();
    final memoryRepository = _MockMemoryRepository();
    final user = _MockUser();
    when(() => user.uid).thenReturn('user-id');
    when(() => user.displayName).thenReturn('Rani');
    when(
      () => memoryRepository.createMemory(
        title: any(named: 'title'),
        story: any(named: 'story'),
        memoryDate: any(named: 'memoryDate'),
        category: any(named: 'category'),
        mood: any(named: 'mood'),
      ),
    ).thenAnswer((_) async => 'new-memory-id');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          recentMemoriesProvider.overrideWith(
            (ref) => Stream.value(const <MemoryModel>[]),
          ),
        ],
        child: const LoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kenangan baru'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Hari di pantai');
    await tester.enterText(find.byType(TextFormField).at(1), 'Cerita kecil');
    await tester.tap(find.text('Simpan kenangan'));
    await tester.pumpAndSettle();

    expect(find.text('Kenanganmu berhasil disimpan!'), findsOneWidget);
    verify(
      () => memoryRepository.createMemory(
        title: 'Hari di pantai',
        story: 'Cerita kecil',
        memoryDate: any(named: 'memoryDate'),
        category: 'Nasihat',
        mood: 'hangat',
      ),
    ).called(1);
  });
}
