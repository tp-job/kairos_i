import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../data/openrouter_service.dart';
import '../models/orchestrator_models.dart';

final aiServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService(ref.watch(dioProvider));
});

/// Feature 1.3 Cross-API Synthesis: watches two already-loaded
/// providers (weather + tasks) and, once both resolve, asks the AI to
/// produce one advisory sentence. Because this is itself a
/// FutureProvider that `ref.watch`es other providers, it automatically
/// re-runs whenever weather or tasks refresh — no manual wiring needed.
final dailyAdviceProvider = FutureProvider<String>((ref) async {
  final weather = await ref.watch(weatherProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  final ai = ref.watch(aiServiceProvider);

  final weatherSummary =
      '${weather.condition}, ${weather.temperatureC.round()}°C, '
      'ฝน ${weather.rainChancePercent}%';
  final scheduleSummary = tasks.isEmpty
      ? 'ไม่มีนัดหมายวันนี้/พรุ่งนี้'
      : tasks.map((t) => t.name).join(', ');

  return ai.synthesizeAdvice(
    weatherSummary: weatherSummary,
    scheduleSummary: scheduleSummary,
  );
});

/// Backs the AI command bar: holds the last parsed intent + a busy
/// flag so the input field can show a spinner while the round trip to
/// OpenRouter (and, if applicable, ClickUp) is in flight.
class OrchestratorController extends AsyncNotifier<ParsedIntent?> {
  @override
  Future<ParsedIntent?> build() async => null;

  Future<void> submit(String message) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final ai = ref.read(aiServiceProvider);
      final intent = await ai.parseIntent(message);

      if (intent.action == 'create_task' && intent.taskName != null) {
        await ref.read(taskActionsProvider).createTask(
              name: intent.taskName!,
              dueDate: intent.dueDate,
            );
      }

      return intent;
    });
  }
}

final orchestratorControllerProvider =
    AsyncNotifierProvider<OrchestratorController, ParsedIntent?>(
  OrchestratorController.new,
);
