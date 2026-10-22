import 'package:cloud_firestore/cloud_firestore.dart';

class TimeCapsuleModel {
  const TimeCapsuleModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.note,
    required this.unlockAt,
    this.createdAt,
    this.isOpened = false,
    this.mood = 'hangat',
  });

  final String id;
  final String userId;
  final String title;
  final String note;
  final DateTime unlockAt;
  final DateTime? createdAt;
  final bool isOpened;
  final String mood;

  bool get isLocked => DateTime.now().isBefore(unlockAt);

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'note': note,
      'unlock_at': Timestamp.fromDate(unlockAt),
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'is_opened': isOpened,
      'mood': mood,
    };
  }

  factory TimeCapsuleModel.fromMap(String id, Map<String, dynamic> map) {
    final unlock = map['unlock_at'];
    final created = map['created_at'];

    return TimeCapsuleModel(
      id: id,
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      note: map['note'] as String? ?? '',
      unlockAt: switch (unlock) {
        Timestamp ts => ts.toDate(),
        DateTime dt => dt,
        _ => DateTime.now().add(const Duration(days: 30)),
      },
      createdAt: switch (created) {
        Timestamp ts => ts.toDate(),
        DateTime dt => dt,
        _ => null,
      },
      isOpened: map['is_opened'] as bool? ?? false,
      mood: map['mood'] as String? ?? 'hangat',
    );
  }
}
