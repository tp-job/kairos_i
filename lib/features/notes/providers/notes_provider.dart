import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/prefs.dart';
import '../models/note_model.dart';

/// Owns the note list — no API, backed by `shared_preferences` on device.
/// The [NoteFormScreen] is the single place notes are created *and*
/// updated: it calls [add] when it opens with no note, [update] when it
/// opens editing an existing one.
///
/// Notes used to live only in memory, so anything the user wrote was gone
/// the next time they opened the app.
class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier(this._prefs) : super(const []) {
    _restore();
  }

  final SharedPreferences _prefs;

  void _restore() {
    final raw = _prefs.getString(PrefKeys.notes);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = [
        for (final item in decoded)
          Note.fromStorageJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // Never let a bad payload block launch — see LocalTasksNotifier.
      _prefs.remove(PrefKeys.notes);
    }
  }

  void _persist() {
    _prefs.setString(
      PrefKeys.notes,
      jsonEncode([for (final n in state) n.toStorageJson()]),
    );
  }

  int _seq = 0;

  /// Timestamp plus a per-session counter — two notes created in the same
  /// microsecond would otherwise share an id, and deleting one would take
  /// the other with it. See the matching note in `LocalTasksNotifier`.
  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

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
    _persist();
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
    _persist();
  }

  void togglePin(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(pinned: !n.pinned) else n,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((n) => n.id != id).toList();
    _persist();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>(
  (ref) => NotesNotifier(ref.watch(sharedPreferencesProvider)),
);
