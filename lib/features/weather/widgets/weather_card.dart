import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bento_card.dart';
import '../models/weather_model.dart';
import '../providers/weather_provider.dart';
import 'weather_detail_screen.dart';

/// ConsumerWidget = StatelessWidget that can `ref.watch` a provider,
/// the Riverpod equivalent of a component calling useQuery(). Rebuilds
/// only this card when weatherProvider changes — the other Bento boxes
/// don't re-render.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);

    return BentoCard(
      title: 'สภาพอากาศ',
      icon: Icons.wb_sunny_outlined,
      elevated: true,
      // Tapping the Bento box opens the full editorial detail view.
      // (Refresh is handled inside the detail screen or via a future
      // pull-to-refresh gesture on the dashboard itself.)
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
      ),
      child: AsyncCardBody<WeatherModel>(
        value: weather,
        builder: (context, data) => _WeatherContent(data: data),
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.data});

  final WeatherModel data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${data.temperatureC.round()}°',
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300),
        ),
        Text(data.description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text('${data.cityName} · รู้สึกเหมือน ${data.feelsLikeC.round()}°'),
        if (data.isRiskyForOutdoorPlans) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppTheme.danger),
              const SizedBox(width: 4),
              Text(
                'มีโอกาสฝนตก เตรียมร่มไว้',
                style: const TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
