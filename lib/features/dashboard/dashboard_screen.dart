import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../market/widgets/market_card.dart';
import '../news/widgets/news_card.dart';
import '../orchestrator/providers/orchestrator_provider.dart';
import '../orchestrator/widgets/ai_command_bar.dart';
import '../tasks/widgets/tasks_card.dart';
import '../weather/widgets/weather_card.dart';

/// Feature 2: Minimalist Bento Dashboard. Flutter has no CSS Grid, so
/// the "Bento" layout is hand-assembled from Row/Column/Expanded —
/// this is the piece most worth stepping through slowly if you're
/// coming from a flexbox/grid mental model.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kairos', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const _AdviceBanner(),
              const SizedBox(height: 16),
              const AiCommandBar(),
              const SizedBox(height: 16),
              Expanded(child: _BentoGrid()),
            ],
          ),
        ),
      ),
    );
  }
}

/// The grid itself: weather + tasks share the top row (equal width),
/// market gets a wide row, news gets the remaining height. Adjust the
/// `flex` values to change proportions — that's the "size by
/// importance" rule from the spec (Feature 2.1).
class _BentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const gap = AppTheme.gridGap;
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: const [
              Expanded(child: WeatherCard()),
              SizedBox(width: gap),
              Expanded(child: TasksCard()),
            ],
          ),
        ),
        const SizedBox(height: gap),
        Expanded(
          flex: 4,
          child: Row(
            children: const [
              Expanded(flex: 3, child: MarketCard()),
              SizedBox(width: gap),
              Expanded(flex: 4, child: NewsCard()),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdviceBanner extends ConsumerWidget {
  const _AdviceBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advice = ref.watch(dailyAdviceProvider);

    return advice.when(
      data: (text) => Text(
        text,
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
      ),
      loading: () => Text(
        'กำลังประมวลผลคำแนะนำวันนี้...',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
