import 'package:dio/dio.dart';
import '../../../core/env/env.dart';
import '../models/task_model.dart';

/// Wraps ClickUp API v2. Auth is a plain header (Personal Token), no
/// OAuth dance needed for a single-user app like this.
class ClickUpService {
  ClickUpService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://api.clickup.com/api/v2';

  /// Whether ClickUp is set up at all.
  ///
  /// Lets a caller tell "the user never configured ClickUp" apart from "the
  /// sync genuinely failed". Without it every fresh checkout looks like a
  /// broken integration, so the only safe thing to do with a failure was to
  /// hide it — which then hid the real ones too.
  bool get isConfigured =>
      Env.optional('CLICKUP_API_TOKEN').isNotEmpty &&
      Env.optional('CLICKUP_LIST_ID').isNotEmpty;

  Options get _authOptions => Options(headers: {
        'Authorization': Env.clickUpApiToken,
        'Content-Type': 'application/json',
      });

  /// Feature 3.1 Smart Query List: fetch only uncompleted tasks, then
  /// filter client-side to "due today or tomorrow" — ClickUp's date
  /// range filter works in epoch millis, easier to reason about here.
  Future<List<TaskModel>> getUpcomingTasks() async {
    final response = await _dio.get(
      '$_baseUrl/list/${Env.clickUpListId}/task',
      queryParameters: {'archived': false, 'include_closed': false},
      options: _authOptions,
    );

    final tasks = (response.data['tasks'] as List<dynamic>)
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .where((task) => task.isDueTodayOrTomorrow)
        .toList();

    tasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return tasks;
  }

  /// Feature 3.2 Hands-free Task Creation: called by the Orchestrator
  /// after it parses a natural-language command into name + due date.
  Future<void> createTask({required String name, DateTime? dueDate}) async {
    await _dio.post(
      '$_baseUrl/list/${Env.clickUpListId}/task',
      data: {
        'name': name,
        if (dueDate != null)
          'due_date': dueDate.millisecondsSinceEpoch,
        'due_date_time': dueDate != null,
      },
      options: _authOptions,
    );
  }
}
