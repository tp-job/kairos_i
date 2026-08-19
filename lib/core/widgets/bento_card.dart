import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'glass_container.dart';
import 'kairos_spinner.dart';

/// A Bento box: the standard titled card every feature panel is built on
/// (WeatherCard, TasksCard, ...). Feature widgets supply only `child` — the
/// shell, title row and tap target live here so every box is identical.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
    this.elevated = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  /// When true the card reads as the raised "hero" surface — a tinted
  /// container, not a second shadow tier.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final fill = elevated
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
    final border = elevated ? scheme.primary.withValues(alpha: 0.35) : null;

    return GlassContainer(
      padding: EdgeInsets.zero,
      fillColor: fill,
      borderColor: border,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radius2xl),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: DesignTokens.space2),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The three states every AsyncValue can be in, rendered consistently so no
/// card hand-rolls its own spinner or error text.
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
      loading: () => const Center(
        child: KairosSpinner(size: 22, strokeWidth: 2.5),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 20, color: context.colors.onSurfaceVariant),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'โหลดข้อมูลไม่สำเร็จ',
              textAlign: TextAlign.center,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
