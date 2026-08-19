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

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'title': title,
        'body': body,
        'colorIndex': colorIndex,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromStorageJson(Map<String, dynamic> json) {
    final created = DateTime.parse(json['createdAt'] as String);
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      // Clamped, not trusted: a stored index from a build that shipped more
      // tints would otherwise throw a RangeError on every note render.
      colorIndex: ((json['colorIndex'] as int?) ?? 0) % kNoteTintCount,
      pinned: json['pinned'] as bool? ?? false,
      createdAt: created,
      updatedAt: json['updatedAt'] == null
          ? created
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

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
