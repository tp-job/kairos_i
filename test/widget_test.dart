// Smoke test: the app boots and the dashboard's title renders. Feature
// cards need real API keys to fetch data, so this intentionally stops
// at "does it build" rather than asserting on network-backed content.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/main.dart';

void main() {
  testWidgets('KairosApp boots and shows the dashboard title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KairosApp()),
    );

    expect(find.text('Kairos'), findsOneWidget);
  });
}
