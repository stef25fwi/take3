import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:take30/main.dart';

void main() {
  testWidgets('l application affiche Take30', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Take30App()));

    expect(find.text('Take30'), findsOneWidget);
    expect(find.text('Entrer dans l’app'), findsOneWidget);
  });
}
