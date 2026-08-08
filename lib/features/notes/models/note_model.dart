import 'package:flutter/material.dart';

/// A single note. Purely local — created, edited, and deleted entirely on
/// device through [NotesNotifier]; there is no backing API.
@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String body;

  /// Index into `KairosPalette.noteTints` — the note's tint.
  final int colorIndex;

  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? title,
    String? body,
    int? colorIndex,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorIndex: colorIndex ?? this.colorIndex,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// How many tints a note can be tagged with. The colors themselves live in
/// `KairosPalette.noteTints` and are resolved from the ambient theme, so a
/// model holds only this index — never a `Color`.
const int kNoteTintCount = 6;
