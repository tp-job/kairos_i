// Smoke tests for the local (no-API) notes feature: the list renders the
// seeded note, the form creates a new note, and editing an existing note
// updates it in place — all through notesProvider's in-memory state.
//
// These now pump the *real* router rather than a bare MaterialApp, because
// the list navigates by address (`/notes/new`, `/notes/<id>`) rather than by
// pushing a widget. A harness that stubbed navigation would no longer be
// testing the thing that can break.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/core/navigation/routes.dart';
import 'package:kairos_i/features/notes/note_form_screen.dart';
import 'package:kairos_i/features/notes/providers/notes_provider.dart';

import 'support/router_harness.dart';

void main() {
  testWidgets('NotesScreen shows the seeded note', (tester) async {
    await pumpAppAt(tester, Routes.notes);

    expect(find.textContaining('ยินดีต้อนรับ'), findsOneWidget);
  });

  testWidgets('creating a note via the form adds it to the list', (tester) async {
    await pumpAppAt(tester, Routes.notes);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(NoteFormScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ซื้อของ');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(NoteFormScreen), findsNothing);
    expect(find.text('ซื้อของ'), findsOneWidget);
  });

  testWidgets('editing an existing note updates it in place', (tester) async {
    await pumpAppAt(tester, Routes.notes);

    await tester.tap(find.textContaining('ยินดีต้อนรับ'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteFormScreen), findsOneWidget);

    final titleField = find.byType(TextField).first;
    await tester.enterText(titleField, 'แก้ไขแล้ว');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขแล้ว'), findsOneWidget);
    expect(find.textContaining('ยินดีต้อนรับ'), findsNothing);
  });

  testWidgets('a note is reachable by address', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final id = container.read(notesProvider).first.id;

    await pumpAppAt(tester, Routes.noteEdit(id));

    expect(find.byType(NoteFormScreen), findsOneWidget);
  });

  testWidgets('a stale note id falls back to the list instead of throwing',
      (tester) async {
    await pumpAppAt(tester, Routes.noteEdit('does-not-exist'));

    expect(find.byType(NoteFormScreen), findsNothing);
    expect(find.textContaining('ยินดีต้อนรับ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
