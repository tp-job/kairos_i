import 'package:flutter/foundation.dart';

enum ChatRole { user, assistant }

/// One turn in the conversation.
///
/// The assistant used to keep no history at all — `OrchestratorController`
/// held the single most recent `ParsedIntent`, and the reply was one grey
/// line that vanished the moment you typed again. Nothing was ever sent back
/// to the model either, so "แล้วเลื่อนเป็นบ่ายสองได้ไหม" had no idea what
/// "it" referred to. A message list is what makes a follow-up possible.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.at,
    this.createdTaskId,
    this.createdTaskName,
    this.createdTaskDue,
    this.failed = false,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime at;

  /// Set when this turn actually created a task. Drives the inline card, and
  /// carries what undo needs to put the task back.
  final String? createdTaskId;
  final String? createdTaskName;
  final DateTime? createdTaskDue;

  /// The request failed (no key, offline, unparseable model output). Kept in
  /// the transcript rather than thrown away so the user can see *which* of
  /// their messages did not land and retry that one.
  final bool failed;

  bool get createdTask => createdTaskId != null;

  ChatMessage copyWith({String? createdTaskId}) => ChatMessage(
        id: id,
        role: role,
        text: text,
        at: at,
        createdTaskId: createdTaskId ?? this.createdTaskId,
        createdTaskName: createdTaskName,
        createdTaskDue: createdTaskDue,
        failed: failed,
      );

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'at': at.toIso8601String(),
        'taskId': createdTaskId,
        'taskName': createdTaskName,
        'taskDue': createdTaskDue?.toIso8601String(),
        'failed': failed,
      };

  factory ChatMessage.fromStorageJson(Map<String, dynamic> json) {
    final due = json['taskDue'] as String?;
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatRole.assistant,
      ),
      text: json['text'] as String? ?? '',
      at: DateTime.parse(json['at'] as String),
      createdTaskId: json['taskId'] as String?,
      createdTaskName: json['taskName'] as String?,
      createdTaskDue: due == null ? null : DateTime.parse(due),
      failed: json['failed'] as bool? ?? false,
    );
  }
}
