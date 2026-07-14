import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/design_tokens.dart';

/// The floating bottom navigation from the reference: a translucent white
/// rounded-top bar with four icons and a raised charcoal "+" FAB centered
/// above it. Purely presentational — callbacks are supplied by the screen.
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

  @override
  Widget build(BuildContext context) {
    // Height covers the raised FAB (which sits ~28px above the bar).
    return SizedBox(
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The bar itself.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 40,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _NavIcon(
                      icon: Icons.home_rounded,
                      active: currentIndex == 0,
                      onTap: () => onTap?.call(0),
                    ),
                    _NavIcon(
                      icon: Icons.calendar_today_rounded,
                      active: currentIndex == 1,
                      onTap: () => onTap?.call(1),
                    ),
                    const SizedBox(width: 56), // gap under the FAB
                    _NavIcon(
                      icon: Icons.article_outlined,
                      active: currentIndex == 2,
                      onTap: () => onTap?.call(2),
                    ),
                    _NavIcon(
                      icon: Icons.chat_bubble_outline_rounded,
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
            child: Material(
              color: DesignTokens.brand,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              child: InkWell(
                onTap: onAdd,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignTokens.pageBackdrop,
                      width: 4,
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
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
  const _NavIcon({required this.icon, required this.active, this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? DesignTokens.brand : DesignTokens.textFaint,
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? DesignTokens.brand : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
