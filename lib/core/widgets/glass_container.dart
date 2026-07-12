import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Implements the design system's "Elevation & Depth" section:
/// backdrop blur + translucent white fill + a bright top-left border to
/// fake a light-catching glass edge, plus a soft tinted shadow instead
/// of a black one. This is the one place BackdropFilter is used — every
/// "glass vessel" in the app (cards, the AI input, chips) wraps this.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = DesignTokens.radiusXl,
    this.padding = const EdgeInsets.all(DesignTokens.cardPadding),
    this.fillColor,
    this.borderColor,
    this.blurSigma = DesignTokens.backdropBlurSigma,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? fillColor;
  final Color? borderColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor ?? DesignTokens.glassFillLow,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? DesignTokens.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.glassShadowTint,
                blurRadius: 50,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
