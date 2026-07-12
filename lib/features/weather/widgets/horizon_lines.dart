import 'package:flutter/material.dart';

/// The horizontal strips that fade out under the sun/moon in the
/// reference. Not part of the SVG on purpose — this way the same lines
/// re-color for day vs night by just changing [color].
class HorizonLines extends StatelessWidget {
  const HorizonLines({
    super.key,
    required this.color,
    this.lineCount = 6,
    this.spacing = 6,
  });

  final Color color;
  final int lineCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HorizonPainter(
        color: color,
        lineCount: lineCount,
        spacing: spacing,
      ),
      size: Size.infinite,
    );
  }
}

class _HorizonPainter extends CustomPainter {
  _HorizonPainter({
    required this.color,
    required this.lineCount,
    required this.spacing,
  });

  final Color color;
  final int lineCount;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Each line shrinks a bit and fades a lot compared to the one above.
    for (var i = 0; i < lineCount; i++) {
      final t = i / (lineCount - 1); // 0.0 (top) -> 1.0 (bottom)
      final opacity = (1.0 - t) * 0.8;
      final halfWidth = (size.width * 0.35) * (1.0 - t * 0.6);
      final y = i * spacing;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = 2 - t; // top strip is bolder

      canvas.drawLine(
        Offset(centerX - halfWidth, y),
        Offset(centerX + halfWidth, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorizonPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.lineCount != lineCount ||
      oldDelegate.spacing != spacing;
}
