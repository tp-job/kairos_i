import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
/// Deliberately in-memory and dependency-free, mirroring `NotesNotifier`:
/// adding a task must work on a fresh install with no API keys, no network
/// and no AI orchestrator configured. ClickUp is an optional mirror on top
/// (see [TaskActions.createTask]), never a prerequisite.
///
/// Not persisted across restarts yet — see the TODO at the bottom.
class LocalTasksNotifier extends StateNotifier<List<TaskModel>> {
  LocalTasksNotifier() : super(_seed);

  /// Seeded with the four items the calendar used to hard-code, so a fresh
  /// install still shows a populated timeline instead of an empty screen.
  static List<TaskModel> get _seed {
    final now = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);
    return [
      TaskModel(
        id: 'seed-1',
        name: 'Meeting',
        status: 'to do',
        description: 'Discuss team task for the day',
        dueDate: at(9, 0),
        attendees: 3,
      ),
      TaskModel(
        id: 'seed-2',
        name: 'Icon set',
        status: 'to do',
        description: 'Edit icons for team task for next week',
        dueDate: at(11, 0),
      ),
      TaskModel(
        id: 'seed-3',
        name: 'Prototype',
        status: 'to do',
        description: 'Make and send prototype to the client',
        dueDate: at(13, 30),
      ),
      TaskModel(
        id: 'seed-4',
        name: 'Check asset',
        status: 'to do',
        description: 'Start checking asset',
        dueDate: at(15, 0),
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

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
  }

  void toggleDone(String id) {
    state = [
      for (final t in state)
        if (t.id == id)
          t.copyWith(done: !t.done, status: t.done ? 'to do' : 'complete')
        else
          t,
    ];
  }

  void delete(String id) {
    state = state.where((t) => t.id != id).toList();
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
  (ref) => LocalTasksNotifier(),
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

/// Imperative action layer, called by the add-task sheet and by the AI
/// orchestrator. Creating a task is an explicit call, not a rebuild.
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  /// Adds the task locally — this always succeeds — then mirrors it to
  /// ClickUp as a best effort.
  ///
  /// A ClickUp failure (no token, offline, API error) is swallowed on
  /// purpose: the task is already saved locally, so surfacing a network
  /// error would misrepresent what happened. Returns the created task.
  Future<TaskModel> createTask({
    required String name,
    String description = '',
    DateTime? dueDate,
  }) async {
    final task = _ref.read(localTasksProvider.notifier).add(
          name: name,
          description: description,
          dueDate: dueDate,
        );

    try {
      await _ref
          .read(clickUpServiceProvider)
          .createTask(name: name, dueDate: dueDate);
      _ref.invalidate(tasksProvider);
    } catch (_) {
      // Local-only. Expected whenever ClickUp isn't configured.
    }

    return task;
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));

// TODO(persistence): the local store is in-memory, so tasks vanish on
// restart. Swap LocalTasksNotifier's backing store for shared_preferences
// or a small sqlite table once the shape of TaskModel has settled.
