import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../weather/providers/weather_provider.dart';
import '../data/openrouter_service.dart';

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

// `OrchestratorController` used to live here: it held the single most recent
// ParsedIntent and nothing else. That shape is what made the assistant a
// command box rather than a conversation — there was no transcript to show
// the user and no history to send back to the model, so a follow-up like
// "แล้วเลื่อนเป็นบ่ายสอง" could never resolve what "it" meant.
//
// `ChatNotifier` (providers/chat_provider.dart) replaces it and owns the
// same job plus the history.
