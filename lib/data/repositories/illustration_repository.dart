import 'package:cloud_functions/cloud_functions.dart';

class IllustrationRepository {
  IllustrationRepository({required this.functions});

  final FirebaseFunctions functions;

  Future<Map<String, dynamic>> generateIllustration({
    required String memoryId,
    required String style,
  }) async {
    try {
      final callable = functions.httpsCallable('generateIllustration');
      final result = await callable.call<Map<String, dynamic>>({
        'memoryId': memoryId,
        'style': style,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      final message = switch (e.code) {
        'unauthenticated' => 'Silakan masuk ke akunmu terlebih dahulu.',
        'resource-exhausted' =>
          'Kuota ilustrasi harianmu sudah habis (maksimal 5 kali sehari). Coba lagi besok ya.',
        'invalid-argument' => 'Permintaan tidak valid. Periksa lagi kenanganmu.',
        'permission-denied' => 'Kamu tidak memiliki akses ke kenangan ini.',
        _ => 'Gagal membuat ilustrasi. Coba lagi beberapa saat lagi.',
      };
      throw Exception(message);
    } catch (e) {
      throw Exception('Gagal menghubungi layanan AI: $e');
    }
  }
}
