import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bento_card.dart';
import '../models/market_model.dart';
import '../providers/market_provider.dart';

class MarketCard extends ConsumerWidget {
  const MarketCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);

    return BentoCard(
      title: 'พอร์ตการลงทุน',
      icon: Icons.show_chart_rounded,
      onTap: () => ref.invalidate(marketProvider),
      child: AsyncCardBody<List<MarketQuote>>(
        value: market,
        builder: (context, data) => ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, i) => _QuoteRow(quote: data[i]),
        ),
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote});

  final MarketQuote quote;

  @override
  Widget build(BuildContext context) {
    final color = quote.isUp ? const Color(0xFF3E8E5A) : AppTheme.danger;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            quote.symbol,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        SizedBox(
          height: 28,
          width: 70,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < quote.closePrices.length; i++)
                      FlSpot(i.toDouble(), quote.closePrices[i]),
                  ],
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          '${quote.isUp ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
