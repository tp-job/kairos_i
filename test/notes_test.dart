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

import 'support/prefs_harness.dart';
import 'support/router_harness.dart';

/// Writes a note straight to the store, standing in for one saved on a
/// previous launch. Notes no longer ship a seeded "welcome" entry — a new
/// user gets the real empty state instead of content they did not write.
Future<String> _givenSavedNote({String title = 'บันทึกเก่า'}) async {
  final container = ProviderContainer(overrides: prefsOverrides);
  addTearDown(container.dispose);
  return container.read(notesProvider.notifier).add(title: title, body: '').id;
}

void main() {
  setUp(() => initPrefs());

  testWidgets('NotesScreen starts empty on a first launch', (tester) async {
    await pumpAppAt(tester, Routes.notes);

    expect(find.textContaining('ยินดีต้อนรับ'), findsNothing);
  });

  testWidgets('a saved note survives a restart and renders', (tester) async {
    await _givenSavedNote(title: 'โน้ตที่บันทึกไว้');

    await pumpAppAt(tester, Routes.notes);

    expect(find.text('โน้ตที่บันทึกไว้'), findsOneWidget);
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
    await _givenSavedNote(title: 'ก่อนแก้');

    await pumpAppAt(tester, Routes.notes);

    await tester.tap(find.text('ก่อนแก้'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteFormScreen), findsOneWidget);

    final titleField = find.byType(TextField).first;
    await tester.enterText(titleField, 'แก้ไขแล้ว');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขแล้ว'), findsOneWidget);
    expect(find.text('ก่อนแก้'), findsNothing);
  });

  testWidgets('a note is reachable by address', (tester) async {
    final id = await _givenSavedNote();

    await pumpAppAt(tester, Routes.noteEdit(id));

    expect(find.byType(NoteFormScreen), findsOneWidget);
  });

  testWidgets('a stale note id falls back to the list instead of throwing',
      (tester) async {
    await _givenSavedNote();

    await pumpAppAt(tester, Routes.noteEdit('does-not-exist'));

    expect(find.byType(NoteFormScreen), findsNothing);
    expect(find.text('บันทึกเก่า'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
