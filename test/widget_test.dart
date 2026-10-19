import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lore/app.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders the Lore starter screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LoreApp()));

    expect(find.text('Lore'), findsOneWidget);
    expect(
      find.text('Save your lore. Biar kenangan gak ilang.'),
      findsOneWidget,
    );
  });
}
