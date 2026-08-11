import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../motion/motion.dart';

/// The app's page transitions — the route-level half of [AppMotion].
///
/// Cards spring under the finger; the pages they open must arrive in the same
/// physics, or the app reads as two systems bolted together. Every timing and
/// curve below therefore resolves from [AppMotion]; no literal `Duration` and
/// no bare `Curves.*` appears in this file, and none should appear in a route.
///
/// The three constructors map to the three Material 3 motion patterns the flow
/// map uses. Which one an edge gets is a design decision, documented per-edge
/// in `docs/user-flow.md` §3 — not a matter of taste at the call site:
///
/// * [KairosPage.fadeThrough] — peers with no hierarchy, and boot.
/// * [KairosPage.sharedAxisX] — alternate presentations of the same thing.
/// * [KairosPage.sharedAxisZ] — drilling into the thing that was tapped.
///
/// Reduced motion is handled once, here: every builder short-circuits to the
/// bare child when [AppMotion.reduced] is set, so honouring the platform flag
/// is not something each screen has to remember (NFR-A4).
class KairosPage<T> extends CustomTransitionPage<T> {
  /// Cross-fade with a whisper of scale. No direction, because there isn't
  /// one — the destination is a peer, not a child.
  const KairosPage.fadeThrough({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
          transitionDuration: AppMotion.medium,
          reverseTransitionDuration: AppMotion.fast,
          transitionsBuilder: _fadeThrough,
        );

  /// Lateral movement: the incoming page slides in from the trailing edge
  /// while the outgoing one leaves toward the leading edge. Says "sideways,
  /// same level".
  const KairosPage.sharedAxisX({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
          transitionDuration: AppMotion.medium,
          reverseTransitionDuration: AppMotion.fast,
          transitionsBuilder: _sharedAxisX,
        );

  /// Depth: the incoming page grows in from behind while the outgoing one
  /// pushes past the viewer. Says "deeper into what you just touched".
  const KairosPage.sharedAxisZ({
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
          transitionDuration: AppMotion.medium,
          reverseTransitionDuration: AppMotion.fast,
          transitionsBuilder: _sharedAxisZ,
        );

  // --- Builders ------------------------------------------------------------
  //
  // Each receives both animations. `animation` drives this page arriving and
  // leaving; `secondaryAnimation` drives it being covered by, and uncovered
  // from, the page pushed on top of it. Handling both is what makes the pair
  // of pages move as one gesture rather than two independent fades.

  static Widget _fadeThrough(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
    final exit = CurvedAnimation(parent: secondary, curve: AppMotion.standard);
    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      builder: (context, inner) => Opacity(
        // Fades out as the next page fades in — the "through" in fade-through.
        opacity: enter.value * (1 - exit.value),
        child: Transform.scale(
          scale: 0.985 + 0.015 * enter.value,
          child: inner,
        ),
      ),
      child: child,
    );
  }

  /// ±30% of width. Enough travel to read as movement, short enough that the
  /// eye never loses the content mid-flight.
  static const _axisTravel = 0.30;

  static Widget _sharedAxisX(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
    final exit = CurvedAnimation(parent: secondary, curve: AppMotion.emphasized);
    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      builder: (context, inner) => FractionalTranslation(
        translation: Offset(
          (1 - enter.value) * _axisTravel - exit.value * _axisTravel,
          0,
        ),
        child: Opacity(
          opacity: enter.value * (1 - exit.value),
          child: inner,
        ),
      ),
      child: child,
    );
  }

  static Widget _sharedAxisZ(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
    final exit = CurvedAnimation(parent: secondary, curve: AppMotion.emphasized);
    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      builder: (context, inner) => Transform.scale(
        // Arrives from 0.80 (behind the plane); departs to 1.10 (past the
        // viewer) when something is pushed on top of it.
        scale: (0.80 + 0.20 * enter.value) + 0.10 * exit.value,
        child: Opacity(
          opacity: enter.value * (1 - exit.value),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}
