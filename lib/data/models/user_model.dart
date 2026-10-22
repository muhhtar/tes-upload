import 'package:cloud_firestore/cloud_firestore.dart';

class AiQuota {
  const AiQuota({
    required this.usedToday,
    this.resetAt,
  });

  final int usedToday;
  final DateTime? resetAt;

  Map<String, dynamic> toMap() {
    return {
      'used_today': usedToday,
      if (resetAt != null) 'reset_at': Timestamp.fromDate(resetAt!),
    };
  }

  factory AiQuota.fromMap(Map<String, dynamic> map) {
    final reset = map['reset_at'];
    return AiQuota(
      usedToday: map['used_today'] as int? ?? 0,
      resetAt: switch (reset) {
        Timestamp ts => ts.toDate(),
        DateTime dt => dt,
        _ => null,
      },
    );
  }
}

class UserSettings {
  const UserSettings({
    this.theme = 'system',
    this.biometricLock = false,
    this.defaultStyle = 'watercolor',
  });

  final String theme; // 'system' | 'light' | 'dark'
  final bool biometricLock;
  final String defaultStyle;

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'biometric_lock': biometricLock,
      'default_style': defaultStyle,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      theme: map['theme'] as String? ?? 'system',
      biometricLock: map['biometric_lock'] as bool? ?? false,
      defaultStyle: map['default_style'] as String? ?? 'watercolor',
    );
  }

  UserSettings copyWith({
    String? theme,
    bool? biometricLock,
    String? defaultStyle,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      biometricLock: biometricLock ?? this.biometricLock,
      defaultStyle: defaultStyle ?? this.defaultStyle,
    );
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
    this.settings = const UserSettings(),
    this.aiQuota = const AiQuota(usedToday: 0),
  });

  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;
  final UserSettings settings;
  final AiQuota aiQuota;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'settings': settings.toMap(),
      'ai_quota': aiQuota.toMap(),
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final created = map['created_at'];
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: switch (created) {
        Timestamp ts => ts.toDate(),
        DateTime dt => dt,
        _ => null,
      },
      settings: map['settings'] is Map
          ? UserSettings.fromMap(Map<String, dynamic>.from(map['settings'] as Map))
          : const UserSettings(),
      aiQuota: map['ai_quota'] is Map
          ? AiQuota.fromMap(Map<String, dynamic>.from(map['ai_quota'] as Map))
          : const AiQuota(usedToday: 0),
    );
  }
}
