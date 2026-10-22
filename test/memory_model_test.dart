import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore/data/models/memory_model.dart';

void main() {
  group('MemoryDate', () {
    test('calculates a sort key from an exact date', () {
      const date = MemoryDate(year: 2024, month: 3, day: 9, precision: 'day');

      expect(date.sortKey, 20240309);
      expect(date.toMap(), {
        'year': 2024,
        'month': 3,
        'day': 9,
        'precision': 'day',
        'sort_key': 20240309,
      });
    });

    test('omits unspecified month and day from year-precision dates', () {
      const date = MemoryDate(year: 1998, precision: 'year');

      expect(date.sortKey, 19980000);
      expect(date.toMap(), {
        'year': 1998,
        'precision': 'year',
        'sort_key': 19980000,
      });
    });
  });

  test('reads stored fields and Firestore timestamps', () {
    final createdAt = DateTime.utc(2025, 1, 2);
    final memory = MemoryModel.fromMap('memory-id', {
      'user_id': 'user-id',
      'title': 'Hari di pantai',
      'memory_date': {
        'year': 2024,
        'month': 3,
        'day': 9,
        'precision': 'day',
        'sort_key': 20240309,
      },
      'category': 'Liburan',
      'mood': 'hangat',
      'created_at': Timestamp.fromDate(createdAt),
    });

    expect(memory.id, 'memory-id');
    expect(memory.userId, 'user-id');
    expect(memory.story, isEmpty);
    expect(memory.createdAt?.toUtc(), createdAt);
    expect(memory.isFavorite, isFalse);
    expect(memory.memoryDate.sortKey, 20240309);
  });

  test('serializes the fields required when creating a memory', () {
    final memory = MemoryModel(
      id: 'unused-for-new-document',
      userId: 'user-id',
      title: 'Hari di pantai',
      story: 'Cerita kecil',
      memoryDate: const MemoryDate(year: 2024, precision: 'year'),
      category: 'Liburan',
      mood: 'hangat',
      isFavorite: false,
      createdAt: null,
    );

    final data = memory.toMap();
    expect(data['user_id'], 'user-id');
    expect(data['title'], 'Hari di pantai');
    expect(data['story'], 'Cerita kecil');
    expect(data['memory_date']['sort_key'], 20240000);
    expect(data['category'], 'Liburan');
    expect(data['mood'], 'hangat');
    expect(data['media'], isEmpty);
    expect(data['is_favorite'], isFalse);
    expect(data['created_at'], isA<FieldValue>());
    expect(data['updated_at'], isA<FieldValue>());
  });
}
