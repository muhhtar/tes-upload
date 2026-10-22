import 'package:cloud_firestore/cloud_firestore.dart';

class MediaItem {
  const MediaItem({
    required this.type,
    required this.url,
    required this.path,
    required this.size,
    this.duration,
  });

  final String type; // 'photo' or 'audio'
  final String url;
  final String path;
  final int size;
  final int? duration; // duration in seconds for audio

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'url': url,
      'path': path,
      'size': size,
      if (duration != null) 'duration': duration,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      type: map['type'] as String? ?? 'photo',
      url: map['url'] as String? ?? '',
      path: map['path'] as String? ?? '',
      size: map['size'] as int? ?? 0,
      duration: map['duration'] as int?,
    );
  }
}

class AiIllustration {
  const AiIllustration({
    required this.url,
    required this.path,
    required this.style,
    required this.status,
    this.generatedAt,
  });

  final String url;
  final String path;
  final String style;
  final String status; // 'pending' | 'done' | 'failed'
  final DateTime? generatedAt;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'path': path,
      'style': style,
      'status': status,
      'generated_at': generatedAt != null
          ? Timestamp.fromDate(generatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory AiIllustration.fromMap(Map<String, dynamic> map) {
    final gen = map['generated_at'];
    return AiIllustration(
      url: map['url'] as String? ?? '',
      path: map['path'] as String? ?? '',
      style: map['style'] as String? ?? 'watercolor',
      status: map['status'] as String? ?? 'done',
      generatedAt: switch (gen) {
        Timestamp ts => ts.toDate(),
        DateTime dt => dt,
        _ => null,
      },
    );
  }
}
