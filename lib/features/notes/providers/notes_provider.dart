import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';

/// Owns the note list entirely in memory — no API, no persistence layer.
/// The [NoteFormScreen] is the single place notes are created *and*
/// updated: it calls [add] when it opens with no note, [update] when it
/// opens editing an existing one.
class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super(_seed);

  static List<Note> get _seed {
    final now = DateTime.now();
    return [
      Note(
        id: 'seed-1',
        title: 'ยินดีต้อนรับ 👋',
        body: 'แตะ + เพื่อสร้างโน้ตใหม่ หรือแตะโน้ตนี้เพื่อแก้ไข',
        colorIndex: 0,
        pinned: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Creates a new note and returns it.
  Note add({
    required String title,
    required String body,
    int colorIndex = 0,
  }) {
    final now = DateTime.now();
    final note = Note(
      id: _newId(),
      title: title,
      body: body,
      colorIndex: colorIndex,
      createdAt: now,
      updatedAt: now,
    );
    state = [note, ...state];
    return note;
  }

  /// Updates an existing note in place (title/body/color) — the "not API,
  /// just local update" path used when editing from [NoteFormScreen].
  void update(
    String id, {
    required String title,
    required String body,
    required int colorIndex,
  }) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            title: title,
            body: body,
            colorIndex: colorIndex,
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
  }

  void togglePin(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(pinned: !n.pinned) else n,
    ];
  }

  void delete(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>(
  (ref) => NotesNotifier(),
);
