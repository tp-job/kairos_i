import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// The charcoal hero header from the project-management reference: a dark
/// rounded-bottom panel that bleeds under the status bar, carrying a small
/// greeting, a two-line headline, and a circular avatar. A faint wave is
/// painted over the fill for a touch of depth (matching the mockup's
/// low-opacity SVG wave).
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
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(40),
      ),
      child: CustomPaint(
        painter: _WavePainter(),
        child: Container(
          decoration: const BoxDecoration(gradient: DesignTokens.brandGradient),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      headline,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// Paints the reference's faint decorative wave across the header fill.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
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
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}
