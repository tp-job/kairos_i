import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'glass_container.dart';

/// A Bento box, styled as a "Glass Card" per the design system's
/// Components section: signature glass vessel with a title row, built
/// on top of GlassContainer. Individual feature cards (WeatherCard,
/// TasksCard, ...) only ever provide `child` — the glass shell, title
/// row, and tap target live here so every box looks identical.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(DesignTokens.spacingUnit * 2.5), // 20px
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three states every AsyncValue can be in, rendered consistently
/// so no card has to hand-roll its own loading spinner / error text.
/// Pass this the AsyncValue from `ref.watch(someFutureProvider)`.
class AsyncCardBody<T> extends StatelessWidget {
  const AsyncCardBody({
    super.key,
    required this.value,
    required this.builder,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => builder(context, data),
      loading: () => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.textMuted,
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'โหลดข้อมูลไม่สำเร็จ\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: DesignTokens.errorContainer,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
