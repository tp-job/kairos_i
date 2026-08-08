import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../motion/motion.dart';

/// The app canvas: a living **ambient mesh**. Four soft, low-saturation
/// blobs drift slowly across a near-white field on independent orbits, so
/// the glass surfaces layered above always have shifting light to refract.
/// The motion is deliberately slow (a full cycle is ~30s) — ambient, never
/// distracting. Honors reduced-motion by painting a single static frame.
///
/// Wrapped once around the whole app in main.dart, so every screen's
/// transparent Scaffold reveals it.
class MeshBackground extends StatefulWidget {
  const MeshBackground({super.key, required this.child});

  final Widget child;

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = !AppMotion.reduced(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _MeshPainter(animate ? _c.value : 0, colorScheme),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.t, this.colorScheme);

  /// 0..1 progress through one full ambient cycle.
  final double t;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Draw canvas base color from theme surface
    canvas.drawRect(rect, Paint()..color = colorScheme.surface);

    final tau = 2 * math.pi;
    final radius = size.longestSide * 0.55;

    // Dynamically map blobs to primary, secondary, tertiary, and error/accent colors
    final blobs = [
      (color: colorScheme.primary, phase: 0.0, ax: 0.26, ay: 0.20),
      (color: colorScheme.secondary, phase: 1.7, ax: 0.22, ay: 0.24),
      (color: colorScheme.tertiary, phase: 3.1, ax: 0.28, ay: 0.18),
      (color: colorScheme.error, phase: 4.6, ax: 0.20, ay: 0.26),
    ];

    for (var i = 0; i < blobs.length; i++) {
      final b = blobs[i];
      // Each blob traces a slow Lissajous orbit around a home anchor.
      final anchorX = 0.5 + math.cos(b.phase) * 0.28;
      final anchorY = 0.5 + math.sin(b.phase) * 0.28;
      final dx = math.sin(tau * t + b.phase) * b.ax;
      final dy = math.cos(tau * t + b.phase * 1.3) * b.ay;
      final center = Offset(
        (anchorX + dx) * size.width,
        (anchorY + dy) * size.height,
      );

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.color.withValues(alpha: colorScheme.brightness == Brightness.dark ? 0.35 : 0.55),
            b.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = colorScheme.brightness == Brightness.dark 
            ? BlendMode.screen 
            : BlendMode.plus; // screen is softer on dark, plus is bright on light
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.colorScheme != colorScheme;
}
