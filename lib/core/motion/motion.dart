import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// The app's motion language. One vocabulary of durations and curves so
/// every animated surface — glass entrances, nav indicator, tab changes,
/// press feedback — moves with the same physics and reads as one system.
///
/// Curves follow Material 3 "emphasized" easing (a slow, confident settle)
/// with a gentle spring for tactile elements. Keep timing decisions here,
/// not scattered across widgets.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 640);

  /// Enters fast, settles slow — the default for content appearing/moving.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Symmetric standard easing for reversible states (fades, toggles).
  static const Curve standard = Cubic(0.4, 0.0, 0.2, 1.0);

  /// A restrained overshoot for tactile affordances driven by a curve+duration
  /// (implicit animations that cannot take a simulation).
  static const Curve spring = Cubic(0.34, 1.35, 0.64, 1.0);

  /// The real thing: a critically-under-damped spring for anything the finger
  /// is touching. A curve is time-based and always takes its full duration, so
  /// a fast double-tap looks laggy; a simulation carries the current velocity
  /// into the next gesture, which is what makes a control feel *squishy*
  /// rather than merely animated.
  ///
  /// ratio 0.62 gives roughly one visible bounce and settles in ~300ms. Going
  /// below ~0.5 reads as a toy; above ~0.8 the bounce disappears entirely.
  static const SpringDescription squish = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 28.3, // 2 * ratio(0.62) * sqrt(stiffness * mass)
  );

  /// True when the platform requests reduced motion — honor it so entrances
  /// snap into place instead of animating.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// A one-shot entrance: content fades up a few pixels with emphasized
/// easing. Give siblings an increasing [delay] (index * ~70ms) for the
/// staggered "cascade" that makes a screen feel composed rather than dumped.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
    this.duration = AppMotion.slow,
  });

  final Widget child;
  final Duration delay;

  /// Vertical travel in logical pixels the child rises through.
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AppMotion.emphasized);

  @override
  void initState() {
    super.initState();
    // Kick off after the first frame so [delay] is honored and reduced-motion
    // preferences (only known once we have a context) can be respected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _c.value = 1;
        return;
      }
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Wraps a tappable surface so it dips on press and springs back on release.
/// Handles the tap itself; do not also wrap the child in an InkWell.
///
/// The release runs on [AppMotion.squish] — a real spring simulation seeded
/// with the controller's current velocity, so tapping again mid-bounce picks
/// up where the last gesture left off instead of restarting a fixed-length
/// curve. That continuity is the whole difference between "animated" and
/// "physical".
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  // Unbounded: a spring overshoots past 1.0 on release, and a clamped
  // controller would silently flatten exactly the bounce we are here for.
  late final AnimationController _c =
      AnimationController.unbounded(vsync: this, value: 1);

  void _springTo(double target) {
    if (widget.onTap == null) return;
    if (AppMotion.reduced(context)) {
      _c.value = target;
      return;
    }
    _c.animateWith(
      SpringSimulation(AppMotion.squish, _c.value, target, _c.velocity),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _springTo(widget.pressedScale),
      onTapUp: (_) => _springTo(1),
      onTapCancel: () => _springTo(1),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        // Clamped at paint time only: the spring is free to overshoot, but a
        // runaway value can never blow the layout up.
        builder: (context, child) => Transform.scale(
          scale: _c.value.clamp(0.85, 1.08),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
