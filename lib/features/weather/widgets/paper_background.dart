import 'package:flutter/material.dart';

/// Fills the whole screen with the palette's [background] color, then
/// overlays a very subtle noise texture drawn procedurally by a
/// CustomPainter — that's what gives the editorial "paper" feel from
/// the reference without shipping a texture PNG asset.
class PaperBackground extends StatelessWidget {
  const PaperBackground({
    super.key,
    required this.color,
    required this.grainTint,
    required this.child,
    this.grainOpacity = 0.05,
  });

  final Color color;

  /// The speckle color — pass the sky's `ink`, which is the opposite value to
  /// [color] by construction. Grain has to contrast with the paper or it does
  /// nothing: black speckle on a night sky is invisible, which is what
  /// shipped. Taking it from the palette also keeps the tooth *warm* on warm
  /// paper instead of stamping neutral black over a cream page.
  final Color grainTint;

  final Widget child;

  /// Higher = more visible grain. 0.04-0.06 reads as "paper";
  /// >0.10 starts looking dirty on screens.
  final double grainOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color),
        // The grain layer sits BELOW child so text/illustrations stay crisp.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GrainPainter(
                opacity: grainOpacity,
                tint: grainTint,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Deterministic pseudo-noise: uses a fixed seed so the pattern doesn't
/// re-randomize on every rebuild, which would look like a broken TV.
class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity, required this.tint});

  final double opacity;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = tint.withValues(alpha: opacity);
    // Simple hash-based pseudo-random: enough for grain, no dart:math.
    for (var y = 0; y < size.height; y += 3) {
      for (var x = 0; x < size.width; x += 3) {
        final h = ((x * 374761393) ^ (y * 668265263)) & 0xFF;
        if (h < 40) {
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.tint != tint;
}
