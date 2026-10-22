abstract final class Validators {
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tulis nama panggilanmu dulu ya.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email belum diisi.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Format email-nya belum pas.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password belum diisi.';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter ya.';
    }
    return null;
  }

  static String? memoryTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) {
      return 'Judul kenangannya belum diisi.';
    }
    if (title.length > 100) {
      return 'Judul maksimal 100 karakter ya.';
    }
    return null;
  }

  static String? memoryStory(String? value) {
    if ((value?.length ?? 0) > 5000) {
      return 'Cerita maksimal 5000 karakter ya.';
    }
    return null;
  }
}
