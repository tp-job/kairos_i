import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/clickup_service.dart';
import '../models/task_model.dart';

final clickUpServiceProvider = Provider<ClickUpService>((ref) {
  return ClickUpService(ref.watch(dioProvider));
});

final tasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final service = ref.watch(clickUpServiceProvider);
  return service.getUpcomingTasks();
});

/// Thin action layer the Orchestrator (Feature 1) and any "add task"
/// button call into. Kept separate from tasksProvider itself so
/// creating a task is an explicit imperative call, not a rebuild.
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  Future<void> createTask({required String name, DateTime? dueDate}) async {
    final service = _ref.read(clickUpServiceProvider);
    await service.createTask(name: name, dueDate: dueDate);
    // Force tasksProvider to refetch so the Bento card reflects the new task.
    _ref.invalidate(tasksProvider);
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));
