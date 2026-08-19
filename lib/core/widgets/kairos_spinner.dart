import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// The app's loading indicator: a gradient arc that sweeps, with a rounded
/// cap at each end.
///
/// Replaces the flat Material [CircularProgressIndicator], which drew one
/// solid `primary` stroke — sage on cream, so faint it read as a rendering
/// glitch rather than as "working". The gradient gives the arc a leading
/// edge, which is what makes rotation legible at 20px.
///
/// The sweep runs through the app's own hues (sage → clay → matcha) rather
/// than the multicolor ramp this was modelled on. A saturated rainbow would
/// be the loudest thing in a Japandi palette by a wide margin; keeping the
/// *motion* and dropping the *chroma* is what makes it read as branded
/// instead of borrowed.
class KairosSpinner extends StatefulWidget {
  const KairosSpinner({
    super.key,
    this.size = 28,
    this.strokeWidth = 3,
    this.color,
  });

  final double size;
  final double strokeWidth;

  /// Overrides the gradient with a single flat color. Use on a saturated
  /// ground (a filled button, the hero header) where the gradient's darker
  /// stops would disappear into the fill.
  final Color? color;

  @override
  State<KairosSpinner> createState() => _KairosSpinnerState();
}

class _KairosSpinnerState extends State<KairosSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    // Reduced motion still needs *something* on screen, so the arc is drawn
    // static rather than removed — an invisible loader is worse than a still
    // one for anyone who cannot tell whether the app is working.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AppMotion.reduced(context)) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final palette = context.palette;

    // Three stops plus a repeat of the first, so the sweep closes on itself
    // with no seam where 360° meets 0°.
    final colors = widget.color != null
        ? <Color>[widget.color!, widget.color!]
        : <Color>[
            scheme.primary,
            scheme.tertiary,
            palette.success,
            scheme.primary,
          ];

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ArcPainter(
              turns: _c.value,
              colors: colors,
              strokeWidth: widget.strokeWidth,
              track: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.turns,
    required this.colors,
    required this.strokeWidth,
    required this.track,
  });

  final double turns;
  final List<Color> colors;
  final double strokeWidth;
  final Color track;

  /// Three-quarters of the circle. A full ring has no visible leading edge
  /// and stops reading as motion the moment it is small.
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final rotation = turns * 2 * math.pi;

    // A faint full ring behind the arc keeps the indicator from looking like
    // a broken fragment while the gap rotates past.
    canvas.drawCircle(
      inset.center,
      inset.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = track,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        // Anchor the gradient to the arc's own start so the leading edge
        // keeps its color as the whole thing rotates.
        transform: GradientRotation(rotation),
      ).createShader(inset);

    canvas.drawArc(inset, rotation, _sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.turns != turns ||
      old.strokeWidth != strokeWidth ||
      old.track != track ||
      !listEquals(old.colors, colors);
}
