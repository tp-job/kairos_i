import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/prefs.dart';
import '../data/clickup_service.dart';
import '../models/task_model.dart';

final clickUpServiceProvider = Provider<ClickUpService>((ref) {
  return ClickUpService(ref.watch(dioProvider));
});

/// Remote tasks from ClickUp. Errors when .env has no credentials — which
/// is the normal state for a fresh checkout, so nothing in the UI may
/// depend on this succeeding.
final tasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final service = ref.watch(clickUpServiceProvider);
  return service.getUpcomingTasks();
});

/// The local task store — the app's source of truth for tasks.
///
/// Dependency-free by design, mirroring `NotesNotifier`: adding a task must
/// work on a fresh install with no API keys, no network and no AI
/// orchestrator configured. ClickUp is an optional mirror on top (see
/// [TaskActions.createTask]), never a prerequisite.
///
/// Backed by `shared_preferences`, so a task survives the app being killed.
/// It previously lived only in memory, which meant every task a user typed
/// was thrown away on the next launch.
///
/// There is **no seed data**. It used to ship four fake tasks (*Meeting*,
/// *Icon set*, *Prototype*, *Check asset*) so the timeline looked populated
/// in screenshots; the cost was that a real user's first launch showed four
/// items they never created and could not meaningfully complete. An honest
/// empty state is better than a fake full one.
class LocalTasksNotifier extends StateNotifier<List<TaskModel>> {
  LocalTasksNotifier(this._prefs) : super(const []) {
    _restore();
  }

  final SharedPreferences _prefs;

  void _restore() {
    final raw = _prefs.getString(PrefKeys.tasks);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      state = [
        for (final item in decoded)
          TaskModel.fromStorageJson(item as Map<String, dynamic>),
      ]..sort(_byDueDate);
    } catch (_) {
      // A corrupt or older-shaped payload must not brick launch. Drop it and
      // start clean rather than throwing on every cold start forever.
      _prefs.remove(PrefKeys.tasks);
    }
  }

  /// Called after every mutation. Fire-and-forget: the in-memory state is
  /// already correct, and blocking a tap on a disk write would make the UI
  /// feel slower than it is.
  void _persist() {
    _prefs.setString(
      PrefKeys.tasks,
      jsonEncode([for (final t in state) t.toStorageJson()]),
    );
  }

  int _seq = 0;

  /// Timestamp plus a per-session counter.
  ///
  /// The counter is not decoration: two `add()` calls inside the same
  /// microsecond — an import, a double-tap, two AI-parsed tasks from one
  /// command — produced *identical* ids, and since `delete` and `toggleDone`
  /// match on id, deleting one silently deleted both.
  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// Creates a task and returns it. [name] is assumed non-empty — the form
  /// is responsible for rejecting blanks before calling.
  TaskModel add({
    required String name,
    String description = '',
    DateTime? dueDate,
    int attendees = 0,
  }) {
    final task = TaskModel(
      id: _newId(),
      name: name,
      status: 'to do',
      description: description,
      dueDate: dueDate,
      attendees: attendees,
    );
    state = [...state, task]..sort(_byDueDate);
    _persist();
    return task;
  }

  void update(
    String id, {
    String? name,
    String? description,
    DateTime? dueDate,
  }) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(name: name, description: description, dueDate: dueDate)
        else
          t,
    ]..sort(_byDueDate);
    _persist();
  }

  void toggleDone(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(done: !t.done, status: t.done ? 'to do' : 'complete')
        else
          t,
    ];
    _persist();
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  /// Undated tasks sort last; otherwise chronological.
  static int _byDueDate(TaskModel a, TaskModel b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  }
}

final localTasksProvider =
    StateNotifierProvider<LocalTasksNotifier, List<TaskModel>>(
  (ref) => LocalTasksNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Tasks due on a given calendar day, chronological. Backs the timeline.
final tasksForDayProvider =
    Provider.family<List<TaskModel>, DateTime>((ref, day) {
  return ref.watch(localTasksProvider).where((t) => t.isOn(day)).toList();
});

/// Tasks worth surfacing on the dashboard: not done, due today or tomorrow.
final upcomingLocalTasksProvider = Provider<List<TaskModel>>((ref) {
  return ref
      .watch(localTasksProvider)
      .where((t) => !t.done && t.isDueTodayOrTomorrow)
      .toList();
});

/// What happened to the optional ClickUp mirror after a task was saved.
///
/// The local save always succeeds, so this is never an error the user must
/// act on — but "saved everywhere" and "saved on this phone only" are
/// genuinely different outcomes, and the UI previously reported both as an
/// unqualified success.
enum SyncOutcome {
  /// ClickUp isn't configured. The normal state for a fresh checkout, and
  /// not worth mentioning — the user never asked for ClickUp.
  notConfigured,

  /// Mirrored to ClickUp.
  synced,

  /// ClickUp is configured but the call failed — offline, bad token, API
  /// error. This is the one worth telling the user about.
  failed,
}

/// The result of creating a task: the task itself, plus what became of the
/// remote mirror. Returning both is what lets the sheet show one message for
/// "saved" and a different one for "saved locally, ClickUp didn't take it".
class CreateTaskResult {
  const CreateTaskResult(this.task, this.sync);

  final TaskModel task;
  final SyncOutcome sync;
}

/// Imperative action layer, called by the add-task sheet and by the AI
/// orchestrator. Creating a task is an explicit call, not a rebuild.
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  /// Adds the task locally — this always succeeds — then mirrors it to
  /// ClickUp as a best effort.
  ///
  /// A ClickUp failure never rolls back the local write and never throws:
  /// the task *is* saved. It is reported through [CreateTaskResult.sync] so
  /// the caller can say so, instead of the failure vanishing silently.
  Future<CreateTaskResult> createTask({
    required String name,
    String description = '',
    DateTime? dueDate,
  }) async {
    final task = _ref.read(localTasksProvider.notifier).add(
          name: name,
          description: description,
          dueDate: dueDate,
        );

    final service = _ref.read(clickUpServiceProvider);
    if (!service.isConfigured) {
      return CreateTaskResult(task, SyncOutcome.notConfigured);
    }

    try {
      await service.createTask(name: name, dueDate: dueDate);
      _ref.invalidate(tasksProvider);
      return CreateTaskResult(task, SyncOutcome.synced);
    } catch (_) {
      return CreateTaskResult(task, SyncOutcome.failed);
    }
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));
