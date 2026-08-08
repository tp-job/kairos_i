// Smoke test for the Liquid Glass core: verifies the glass surface, animated
// mesh backdrop, motion primitives and the glass nav bar all build, paint and
// advance animation frames without throwing (catches paint/assertion errors
// that static analysis can't see).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/core/motion/motion.dart';
import 'package:kairos_i/core/widgets/glass_container.dart';
import 'package:kairos_i/core/widgets/mesh_background.dart';
import 'package:kairos_i/features/dashboard/widgets/bottom_nav_bar.dart';
import 'package:kairos_i/features/splash/splash_screen.dart';

void main() {
  testWidgets('glass, mesh, motion and nav render and animate', (tester) async {
    var tapped = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MeshBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: const Center(
              child: FadeSlideIn(
                child: GlassContainer(
                  child: SizedBox(width: 120, height: 80),
                ),
              ),
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (i) => tapped = i,
            ),
          ),
        ),
      ),
    );

    // Advance the ambient mesh + entrance animations through several frames.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.byType(BottomNavBar), findsOneWidget);

    // The nav pill animates on selection without error.
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped, 1);

    // No exception was thrown while building/painting/animating.
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash renders, spins and hands off via onFinished',
      (tester) async {
    var done = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MeshBackground(
          child: SplashScreen(onFinished: () => done = true),
        ),
      ),
    );

    expect(find.text('Kairos'), findsOneWidget);

    // Advance the entrance + spinning ring.
    await tester.pump(const Duration(milliseconds: 700));
    expect(done, isFalse); // still holding the brand moment

    // Past the minimum hold, the hand-off fires.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(done, isTrue);
    expect(tester.takeException(), isNull);
  });
}
