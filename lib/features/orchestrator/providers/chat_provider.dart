import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/prefs.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../models/chat_message.dart';
import 'orchestrator_provider.dart';

@immutable
class ChatState {
  const ChatState({this.messages = const [], this.sending = false});

  final List<ChatMessage> messages;

  /// True while a reply is in flight — drives the typing indicator and
  /// disables the send button so one tap cannot queue three requests.
  final bool sending;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({List<ChatMessage>? messages, bool? sending}) =>
      ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref, this._prefs) : super(const ChatState()) {
    _restore();
  }

  final Ref _ref;
  final SharedPreferences _prefs;

  int _seq = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// How many prior turns to send back to the model.
  ///
  /// The free-tier context window is small and an unbounded transcript starts
  /// failing once it overflows — which looks like the assistant randomly
  /// going stupid rather than like a limit being hit. Twelve turns is roughly
  /// the last six exchanges, which is what a follow-up actually needs.
  static const _historyTurns = 12;

  void _restore() {
    final raw = _prefs.getString(PrefKeys.chat);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = state.copyWith(
        messages: [
          for (final item in decoded)
            ChatMessage.fromStorageJson(item as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      _prefs.remove(PrefKeys.chat);
    }
  }

  void _persist() {
    _prefs.setString(
      PrefKeys.chat,
      jsonEncode([for (final m in state.messages) m.toStorageJson()]),
    );
  }

  void _append(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
    _persist();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    _append(ChatMessage(
      id: _newId(),
      role: ChatRole.user,
      text: trimmed,
      at: DateTime.now(),
    ));
    state = state.copyWith(sending: true);

    try {
      final intent = await _ref
          .read(aiServiceProvider)
          .parseConversation(_turnsForModel());

      String? taskId;
      String? taskName;
      DateTime? taskDue;

      if (intent.action == 'create_task' && intent.taskName != null) {
        final result = await _ref.read(taskActionsProvider).createTask(
              name: intent.taskName!,
              dueDate: intent.dueDate,
            );
        taskId = result.task.id;
        taskName = result.task.name;
        taskDue = result.task.dueDate;
      }

      _append(ChatMessage(
        id: _newId(),
        role: ChatRole.assistant,
        // The model is told reply_text is mandatory, but a free-tier model
        // omits it often enough that a silent empty bubble is a real outcome.
        text: (intent.replyText?.trim().isNotEmpty ?? false)
            ? intent.replyText!.trim()
            : (taskName != null ? 'เพิ่ม "$taskName" ให้แล้ว' : 'รับทราบ'),
        at: DateTime.now(),
        createdTaskId: taskId,
        createdTaskName: taskName,
        createdTaskDue: taskDue,
      ));
    } catch (_) {
      // The failure stays in the transcript. Dropping it would leave the
      // user's message sitting there with no reply and no explanation.
      _append(ChatMessage(
        id: _newId(),
        role: ChatRole.assistant,
        text: 'ตอบกลับไม่สำเร็จ ลองใหม่อีกครั้ง',
        at: DateTime.now(),
        failed: true,
      ));
    } finally {
      state = state.copyWith(sending: false);
    }
  }

  /// The transcript in OpenRouter's shape, oldest-first, tail-trimmed.
  ///
  /// Failed turns are excluded — "ตอบกลับไม่สำเร็จ" is app chrome, not
  /// something the model said, and feeding it back teaches it to apologise.
  List<Map<String, String>> _turnsForModel() {
    final usable = state.messages.where((m) => !m.failed).toList();
    final tail = usable.length <= _historyTurns
        ? usable
        : usable.sublist(usable.length - _historyTurns);
    return [
      for (final m in tail)
        {
          'role': m.role == ChatRole.user ? 'user' : 'assistant',
          'content': m.text,
        },
    ];
  }

  /// Puts back a task the user undid from a chat card, and clears the card so
  /// the same undo cannot fire twice.
  void undoTaskFromMessage(String messageId) {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;
    final message = state.messages[index];
    if (!message.createdTask) return;

    _ref.read(localTasksProvider.notifier).delete(message.createdTaskId!);

    final updated = [...state.messages];
    updated[index] = ChatMessage(
      id: message.id,
      role: message.role,
      text: message.text,
      at: message.at,
      // Card removed; the reply text stays so the transcript still reads.
      failed: message.failed,
    );
    state = state.copyWith(messages: updated);
    _persist();
  }

  void clear() {
    state = const ChatState();
    _prefs.remove(PrefKeys.chat);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref, ref.watch(sharedPreferencesProvider)),
);
