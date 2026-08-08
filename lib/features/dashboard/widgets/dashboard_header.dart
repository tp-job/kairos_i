import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';

/// The hero header: a rounded-bottom brand panel that bleeds under the status
/// bar, carrying a greeting, a two-line headline and a tappable avatar.
///
/// Every color comes from [KairosPalette.heroGradient] / `onHero`, so the
/// panel stays legible in dark and high-contrast modes — it used to paint
/// white text on whatever the gradient happened to be, which inverted to
/// white-on-pink the moment the scheme flipped.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.headline,
    this.onAvatar,
  });

  final String greeting;
  final String headline;
  final VoidCallback? onAvatar;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: CustomPaint(
        painter: _WavePainter(palette.onHero.withValues(alpha: 0.06)),
        child: Container(
          decoration: BoxDecoration(gradient: palette.heroGradient),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.screenPadding,
            56,
            DesignTokens.screenPadding,
            56,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: context.text.bodyMedium
                          ?.copyWith(color: palette.onHeroVariant),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      headline,
                      style: context.text.headlineMedium?.copyWith(
                        color: palette.onHero,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              _Avatar(onTap: onAvatar),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'ตั้งค่าธีม',
      child: Material(
        color: palette.onHero.withValues(alpha: 0.14),
        shape: CircleBorder(
          side: BorderSide(
            color: palette.onHero.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: DesignTokens.minTouchTarget,
            height: DesignTokens.minTouchTarget,
            child: Icon(Icons.person_rounded, color: palette.onHero, size: 24),
          ),
        ),
      ),
    );
  }
}

/// A faint decorative wave across the header fill.
class _WavePainter extends CustomPainter {
  const _WavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.28)
      ..cubicTo(w * 0.35, h * 0.75, w * 0.6, 0, w, h * 0.5)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}
