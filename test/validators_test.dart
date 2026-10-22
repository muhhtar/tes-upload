import 'package:flutter_test/flutter_test.dart';
import 'package:lore/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a valid email address', () {
      expect(Validators.email('rani@example.com'), isNull);
    });

    test('rejects an invalid email address', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accepts a password with at least six characters', () {
      expect(Validators.password('lore123'), isNull);
    });

    test('rejects a password shorter than six characters', () {
      expect(Validators.password('12345'), isNotNull);
    });
  });
}
