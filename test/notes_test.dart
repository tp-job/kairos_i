// Smoke tests for the local (no-API) notes feature: the list renders the
// seeded note, the form creates a new note, and editing an existing note
// updates it in place — all through notesProvider's in-memory state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/features/notes/note_form_screen.dart';
import 'package:kairos_i/features/notes/notes_screen.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('NotesScreen shows the seeded note', (tester) async {
    await tester.pumpWidget(_wrap(const NotesScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('ยินดีต้อนรับ'), findsOneWidget);
  });

  testWidgets('creating a note via the form adds it to the list', (tester) async {
    await tester.pumpWidget(_wrap(const NotesScreen()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(_wrap(const NotesScreen()));
    await tester.pumpAndSettle();

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
}
