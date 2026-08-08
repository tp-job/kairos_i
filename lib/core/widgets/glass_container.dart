import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// The app's surface primitive: a rounded panel with one hairline edge and one
/// soft shadow, painted from the active [ColorScheme].
///
/// It used to hard-code a light "liquid glass" stack (white tints, a specular
/// sheen, a permanent [BackdropFilter]). Two problems: the tints were literal
/// colors, so the panel stayed pale-on-pale in dark mode, and every instance
/// paid for a backdrop blur even when [blurSigma] was 0 — a save-layer per
/// card, on every frame, for no visual effect.
///
/// The frost is still available (pass a [blurSigma] > 0, as the floating nav
/// bar does), it is just no longer the default.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = DesignTokens.radius2xl,
    this.padding = const EdgeInsets.all(DesignTokens.cardPadding),
    this.fillColor,
    this.borderColor,
    this.gradient,
    this.blurSigma = 0,
    this.elevated = true,
    this.frosted = false,
  });

  /// Opt into the washi-glass preset: the translucent fill, stroke and blur
  /// from [KairosPalette], so the page tints through instead of being covered.
  ///
  /// Costs a save layer per frame — only worth it over something that actually
  /// moves (the mesh background, a scrolling photo). An explicit [fillColor],
  /// [borderColor] or [blurSigma] still wins over the preset.
  final bool frosted;

  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  /// Flat fill, ignored when [gradient] is set. Defaults to the scheme's
  /// raised surface.
  final Color? fillColor;
  final Color? borderColor;

  /// Optional saturated fill (e.g. `context.palette.heroGradient`). Content
  /// on top must then use `onHero`, not the scheme's `onSurface`.
  final Gradient? gradient;

  /// Backdrop blur. Costs a save layer — only pass a value when something is
  /// actually moving behind the panel.
  final double blurSigma;

  /// Whether to cast the app's one shadow.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final palette = context.palette;
    final radius = BorderRadius.circular(borderRadius);

    final fill = fillColor ??
        (frosted ? palette.glassFill : scheme.surfaceContainerLowest);
    final stroke =
        borderColor ?? (frosted ? palette.glassStroke : scheme.outlineVariant);
    final sigma = blurSigma > 0
        ? blurSigma
        : (frosted ? palette.glassBlur : 0.0);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: stroke),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (sigma > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: surface,
      );
    }

    surface = ClipRRect(borderRadius: radius, child: surface);

    if (!elevated) return surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: context.palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: surface,
    );
  }
}
