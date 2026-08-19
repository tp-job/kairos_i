// Smoke test: the app boots and the splash screen's word-mark renders.
// Feature cards need real API keys to fetch data, so this intentionally
// stops at "does it build" rather than asserting on network-backed content.
//
// The SplashScreen holds for 2200 ms before handing off; we pump fake time
// through so the test completes synchronously without leaving pending timers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/main.dart';

import 'support/prefs_harness.dart';

void main() {
  setUp(() => initPrefs());

  testWidgets('KairosApp boots and shows the Kairos word-mark',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: prefsOverrides, child: const KairosApp()),
    );

    // Pump a single frame so the widget tree settles.
    await tester.pump();

    // The word-mark is visible on the splash screen immediately.
    expect(find.text('Kairos'), findsOneWidget);

    // Drain all pending timers (the 2200 ms splash hold) so the test
    // framework doesn't complain about timers left pending on teardown.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
