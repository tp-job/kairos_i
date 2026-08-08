import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/glass_container.dart';

/// The app's loading screen. It renders over the app-wide animated mesh
/// (wrapped in main.dart), so when it fades out into the dashboard the
/// backdrop stays continuous — the glass mark lifts away and the shell
/// settles in behind the same drifting light.
///
/// Shows a spinning gradient ring around a glass brand mark for a minimum
/// brand moment, then calls [onFinished]. Honors reduced-motion (the ring
/// holds still and the wait is shortened).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  /// Called once the minimum splash duration has elapsed.
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Continuously spins the accent arc around the mark.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // One-shot entrance: the mark scales + fades up.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = AppMotion.reduced(context);
      if (reduced) {
        _enter.value = 1;
      } else {
        _enter.forward();
        _spin.repeat();
      }
      // Minimum time the brand mark stays up before handing off.
      final hold = reduced
          ? const Duration(milliseconds: 600)
          : const Duration(milliseconds: 2200);
      Future<void>.delayed(hold, () {
        if (mounted && !_finished) {
          _finished = true;
          widget.onFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(parent: _enter, curve: AppMotion.spring);

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: entrance,
          builder: (context, child) => Opacity(
            opacity: entrance.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.82 + 0.18 * entrance.value,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The spinning ring wrapped around the glass mark.
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _spin,
                      builder: (context, _) => Transform.rotate(
                        angle: _spin.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size.square(132),
                          painter: _RingPainter(
                            track: context.colors.primary
                                .withValues(alpha: 0.12),
                            head: context.colors.primary,
                            tail: context.colors.tertiary,
                          ),
                        ),
                      ),
                    ),
                    const _GlassMark(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Wordmark.
              Text('Kairos', style: context.text.displayMedium),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'กำลังเตรียมพื้นที่ทำงานของคุณ',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centered brand mark: a small liquid-glass tile holding the
/// brand-gradient app glyph, so it belongs to the same material family as
/// the cards it's about to reveal.
class _GlassMark extends StatelessWidget {
  const _GlassMark();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassContainer(
      borderRadius: DesignTokens.radiusXl,
      padding: const EdgeInsets.all(14),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: palette.heroGradient,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.access_time_filled_rounded,
          color: palette.onHero,
          size: 30,
        ),
      ),
    );
  }
}

/// A faint full track plus one bright arc — the arc is what reads as motion
/// once the parent rotates it.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.track,
    required this.head,
    required this.tail,
  });

  final Color track;
  final Color head;
  final Color tail;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = track,
    );

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 1.4,
        colors: [tail.withValues(alpha: 0), tail, head],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.4, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.head != head ||
      oldDelegate.tail != tail;
}
