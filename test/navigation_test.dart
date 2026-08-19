// The user-flow contract, as tests.
//
// These map one-to-one onto the acceptance criteria in docs/user-flow.md §5.
// The point of them is that the two failures this navigation system exists to
// prevent — a tab losing its stack, and back exiting the app from tab 3 — are
// both invisible in a screenshot and obvious here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kairos_i/core/navigation/routes.dart';
import 'package:kairos_i/features/dashboard/dashboard_screen.dart';
import 'package:kairos_i/features/dashboard/widgets/bottom_nav_bar.dart';
import 'package:kairos_i/features/notes/note_form_screen.dart';
import 'package:kairos_i/features/notes/notes_screen.dart';

import 'support/prefs_harness.dart';
import 'support/router_harness.dart';

/// Sends a system back press through the same path Android uses.
Future<void> pressSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => initPrefs());

  testWidgets('A1 — a branch keeps its own stack when left and re-entered',
      (tester) async {
    await pumpAppAt(tester, Routes.notes);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ค้างไว้');
    await tester.pumpAndSettle();
    expect(find.byType(NoteFormScreen), findsOneWidget);

    // Leaving the branch by address rather than by tapping the nav bar: while
    // a focused mode is open the bar is retracted by design, so this is the
    // path a deep link or an in-app jump actually takes.
    final router = GoRouter.of(tester.element(find.byType(BottomNavBar)));
    router.go(Routes.dashboard);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(NoteFormScreen), findsNothing);

    await tester.tap(find.descendant(
      of: find.byType(BottomNavBar),
      matching: find.byIcon(Icons.edit_note_rounded),
    ));
    await tester.pumpAndSettle();

    // The editor is still there, and so is the typed text.
    expect(find.byType(NoteFormScreen), findsOneWidget);
    expect(find.text('ค้างไว้'), findsOneWidget);
  });

  testWidgets('A3 — back from a non-dashboard branch root goes home, not out',
      (tester) async {
    await pumpAppAt(tester, Routes.notes);
    expect(find.byType(NotesScreen), findsOneWidget);

    await pressSystemBack(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('A3 — back inside a branch pops the pushed page first',
      (tester) async {
    await pumpAppAt(tester, Routes.notes);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(NoteFormScreen), findsOneWidget);

    await pressSystemBack(tester);

    // Popped the editor — did not jump to the dashboard.
    expect(find.byType(NoteFormScreen), findsNothing);
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  testWidgets('A2 — a tab keeps its scroll offset across a round trip',
      (tester) async {
    await pumpAppAt(tester, Routes.dashboard);

    final scrollable = find.descendant(
      of: find.byType(DashboardScreen),
      matching: find.byType(Scrollable),
    );
    await tester.drag(scrollable.first, const Offset(0, -240));
    await tester.pumpAndSettle();
    final offset = tester.widget<Scrollable>(scrollable.first).controller!.offset;
    expect(offset, greaterThan(0));

    await tester.tap(find.descendant(
      of: find.byType(BottomNavBar),
      matching: find.byIcon(Icons.edit_note_rounded),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(BottomNavBar),
      matching: find.byIcon(Icons.home_rounded),
    ));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Scrollable>(scrollable.first).controller!.offset,
      offset,
    );
  });

  testWidgets('A6 — reduced motion makes a route change instantaneous',
      (tester) async {
    await pumpAppAt(tester, Routes.notes, reducedMotion: true);

    await tester.tap(find.byIcon(Icons.add_rounded));
    // A single frame, with none of the transition's 380ms pumped through: with
    // motion reduced the destination must already be fully in place.
    await tester.pump();

    expect(find.byType(NoteFormScreen), findsOneWidget);
    // Ancestors only: the page's *transition* wrapper, not the per-widget
    // entrance animations inside the screen, which have their own reduced-
    // motion handling and settle a frame later.
    final opacity = tester
        .widgetList<Opacity>(find.ancestor(
          of: find.byType(NoteFormScreen),
          matching: find.byType(Opacity),
        ))
        .map((o) => o.opacity);
    expect(opacity.every((o) => o == 1), isTrue,
        reason: 'no partial fade should be applied under reduced motion');
  });

  testWidgets('A8 — the fourth nav slot is Notes, and Chat is gone',
      (tester) async {
    await pumpAppAt(tester, Routes.dashboard);

    expect(
      find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.byIcon(Icons.edit_note_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BottomNavBar),
        matching: find.byIcon(Icons.chat_bubble_outline_rounded),
      ),
      findsNothing,
    );

    await tester.tap(find.descendant(
      of: find.byType(BottomNavBar),
      matching: find.byIcon(Icons.edit_note_rounded),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NotesScreen), findsOneWidget);
  });

  testWidgets('the nav bar retracts for a pushed page and returns after',
      (tester) async {
    await pumpAppAt(tester, Routes.notes);

    double barOffset() => tester
        .widget<AnimatedSlide>(find.ancestor(
          of: find.byType(BottomNavBar),
          matching: find.byType(AnimatedSlide),
        ))
        .offset
        .dy;

    expect(barOffset(), 0);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(barOffset(), 1);

    await pressSystemBack(tester);
    expect(barOffset(), 0);
  });
}
