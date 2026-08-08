import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// The floating bottom navigation: a frosted bar with an active pill that
/// crossfades beneath the selected tab, plus a raised brand FAB.
///
/// Purely presentational — callbacks come from the shell.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onAdd,
  });

  /// 0..3 mapping to dashboard / calendar / news / chat (the FAB is separate).
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onAdd;

  static const _labels = ['หน้าแรก', 'ปฏิทิน', 'ข่าว', 'แชท'];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final palette = context.palette;

    return SizedBox(
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radius2xl),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  // Translucent so the frost has something to do, but built
                  // from the scheme's own container tone rather than a fixed
                  // white/near-black pair.
                  color: scheme.surfaceContainer.withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(color: scheme.outlineVariant),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavIcon(
                      icon: Icons.home_rounded,
                      label: _labels[0],
                      active: currentIndex == 0,
                      onTap: () => onTap?.call(0),
                    ),
                    _NavIcon(
                      icon: Icons.calendar_today_rounded,
                      label: _labels[1],
                      active: currentIndex == 1,
                      onTap: () => onTap?.call(1),
                    ),
                    const SizedBox(width: 56), // gap under the FAB
                    _NavIcon(
                      icon: Icons.article_outlined,
                      label: _labels[2],
                      active: currentIndex == 2,
                      onTap: () => onTap?.call(2),
                    ),
                    _NavIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: _labels[3],
                      active: currentIndex == 3,
                      onTap: () => onTap?.call(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Raised center FAB.
          Positioned(
            bottom: 44,
            child: Semantics(
              button: true,
              label: 'เพิ่มงานใหม่',
              child: PressableScale(
                onTap: onAdd,
                pressedScale: 0.9,
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: palette.heroGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: palette.onHero, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          // 48px tall keeps the tap target accessible even though the pill
          // reads smaller.
          height: DesignTokens.minTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? scheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
          child: AnimatedScale(
            scale: active ? 1.1 : 1,
            duration: AppMotion.medium,
            curve: AppMotion.spring,
            child: Icon(
              icon,
              size: 24,
              color: active
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
