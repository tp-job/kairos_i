import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// The app's surface primitive. Named "glass" for historical reasons, but
/// the premium restyle makes it a quiet, near-opaque dark card: a low-alpha
/// white fill over the near-black background (reads as ~#181819), a hairline
/// edge, and a soft black shadow for lift. No saturated color, no glow.
///
/// A backdrop blur is only applied when [blurSigma] > 0 — on the flat dark
/// background it buys nothing, so it defaults off (also cheaper to paint).
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = DesignTokens.radiusXl,
    this.padding = const EdgeInsets.all(DesignTokens.cardPadding),
    this.fillColor,
    this.borderColor,
    this.gradient,
    this.blurSigma = 0,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? fillColor;
  final Color? borderColor;

  /// Optional monochrome gradient for an "elevated" surface (e.g. the hero
  /// card). Kept luminance-only so it never introduces color.
  final Gradient? gradient;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (fillColor ?? DesignTokens.glassFillLow)
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? DesignTokens.glassBorder,
          width: 1,
        ),
      ),
      child: child,
    );

    if (blurSigma > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    // Shadow lives on an outer box so the ClipRRect (which clips the fill,
    // border and any ink splash) doesn't clip the shadow away.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: DesignTokens.glassShadowTint,
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: surface),
    );
  }
}
