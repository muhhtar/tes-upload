import 'package:cloud_firestore/cloud_firestore.dart';

import 'media_item.dart';

class MemoryDate {
  const MemoryDate({
    required this.year,
    required this.precision,
    this.month,
    this.day,
  });

  final int year;
  final int? month;
  final int? day;
  final String precision;

  int get sortKey => year * 10000 + (month ?? 0) * 100 + (day ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      if (precision != 'year' && month != null) 'month': month,
      if (precision == 'day' && day != null) 'day': day,
      'precision': precision,
      'sort_key': sortKey,
    };
  }

  factory MemoryDate.fromMap(Map<String, dynamic> map) {
    return MemoryDate(
      year: map['year'] as int,
      month: map['month'] as int?,
      day: map['day'] as int?,
      precision: map['precision'] as String,
    );
  }
}

class MemoryModel {
  const MemoryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.story,
    required this.memoryDate,
    required this.category,
    required this.mood,
    required this.isFavorite,
    required this.createdAt,
    this.media = const [],
    this.aiIllustration,
  });

  final String id;
  final String userId;
  final String title;
  final String story;
  final MemoryDate memoryDate;
  final String category;
  final String mood;
  final bool isFavorite;
  final DateTime? createdAt;
  final List<MediaItem> media;
  final AiIllustration? aiIllustration;

  MemoryModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? story,
    MemoryDate? memoryDate,
    String? category,
    String? mood,
    bool? isFavorite,
    DateTime? createdAt,
    List<MediaItem>? media,
    AiIllustration? aiIllustration,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      story: story ?? this.story,
      memoryDate: memoryDate ?? this.memoryDate,
      category: category ?? this.category,
      mood: mood ?? this.mood,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      media: media ?? this.media,
      aiIllustration: aiIllustration ?? this.aiIllustration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'story': story,
      'memory_date': memoryDate.toMap(),
      'category': category,
      'mood': mood,
      'media': media.map((m) => m.toMap()).toList(),
      if (aiIllustration != null) 'ai_illustration': aiIllustration!.toMap(),
      'is_favorite': isFavorite,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory MemoryModel.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['created_at'];
    final rawMedia = map['media'];
    final rawAi = map['ai_illustration'];

    return MemoryModel(
      id: id,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      story: map['story'] as String? ?? '',
      memoryDate: MemoryDate.fromMap(
        Map<String, dynamic>.from(map['memory_date'] as Map),
      ),
      category: map['category'] as String,
      mood: map['mood'] as String,
      isFavorite: map['is_favorite'] as bool? ?? false,
      createdAt: switch (createdAt) {
        Timestamp timestamp => timestamp.toDate(),
        DateTime dateTime => dateTime,
        _ => null,
      },
      media: rawMedia is List
          ? rawMedia
              .whereType<Map>()
              .map((item) => MediaItem.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      aiIllustration: rawAi is Map
          ? AiIllustration.fromMap(Map<String, dynamic>.from(rawAi))
          : null,
    );
  }
}
