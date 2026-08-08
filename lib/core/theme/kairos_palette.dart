import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The handful of colors the product needs that Material's [ColorScheme] has
/// no role for: the brand hero surface, an up/down semantic pair, the note
/// tints, and the one shadow tone.
///
/// It ships as a [ThemeExtension] so these follow `Theme.of(context)` exactly
/// like scheme roles do — switch to dark or high contrast and they switch with
/// it. Nothing in the app should hold a `Color` constant of its own.
@immutable
class KairosPalette extends ThemeExtension<KairosPalette> {
  const KairosPalette({
    required this.heroGradient,
    required this.onHero,
    required this.onHeroVariant,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.noteTints,
    required this.onNote,
    required this.shadow,
    required this.glassFill,
    required this.glassStroke,
    required this.glassBlur,
  });

  /// The single saturated surface in the app: dashboard header, the featured
  /// timeline card, the weather tile, the add FAB. Always paired with
  /// [onHero] — never with `Colors.white`, which is unreadable the moment the
  /// scheme flips to a light-on-dark hero.
  final Gradient heroGradient;
  final Color onHero;

  /// De-emphasized content on the hero (sub-labels, captions).
  final Color onHeroVariant;

  /// "Up / good / online". The one semantic outside the exported palette,
  /// because a warm-red scheme has no green and a rising stock must not read
  /// as the brand color.
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Six tints a note can be tagged with, index-stable across brightness so a
  /// note keeps its identity when the theme flips.
  final List<Color> noteTints;
  final Color onNote;

  /// One elevation tone. Two shadow tiers on a light theme read as dirt.
  final Color shadow;

  /// The frosted-glass triplet. Japandi's "liquid glass" is *washi over wood* —
  /// a translucent veil that lets the page tint through, not a white slab. Fill
  /// and stroke are both scheme-derived and semi-transparent so a card floating
  /// over the mesh background picks up whatever is behind it.
  ///
  /// Only surfaces with something actually moving behind them should pay for
  /// [glassBlur] — it costs a save layer per frame.
  final Color glassFill;
  final Color glassStroke;
  final double glassBlur;

  /// Falls back to deriving the extension from the ambient scheme when the
  /// surrounding theme was not built by [AppTheme] — a widget test that pumps
  /// a bare `MaterialApp`, a `Theme` override in a preview. Better a derived
  /// palette than a null check that crashes the tree.
  static KairosPalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<KairosPalette>() ??
        KairosPalette.fromScheme(theme.colorScheme);
  }

  /// Derives the extension from [scheme] so it stays correct for all six
  /// exported variants (light/dark × standard/medium/high contrast).
  ///
  /// The hero is `primary` + `onPrimary` in **both** brightnesses — that pair
  /// is the whole identity: sage-on-cream flips to cream-on-charcoal when the
  /// theme does, and taking a role together with its own `on` color is what
  /// guarantees contrast without hand-checking each variant.
  ///
  /// The gradient is deliberately almost flat (a 12% shift toward the warm clay
  /// tertiary). Quiet luxury is a *material*, not a light show: the hero should
  /// read as one stone with the sun on one corner, never as a two-color ramp.
  factory KairosPalette.fromScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    final heroStart = scheme.primary;
    final heroEnd = Color.lerp(heroStart, scheme.tertiary, 0.12)!;
    final onHero = scheme.onPrimary;

    return KairosPalette(
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [heroStart, heroEnd],
      ),
      onHero: onHero,
      onHeroVariant: onHero.withValues(alpha: 0.72),
      // Matcha rather than a generic green — a saturated "success green" is the
      // single fastest way to break a muted palette.
      success: isDark ? const Color(0xFFB9D3A2) : const Color(0xFF4F6B41),
      onSuccess: isDark ? const Color(0xFF22331A) : const Color(0xFFFFFFFF),
      successContainer:
          isDark ? const Color(0xFF3B4F2E) : const Color(0xFFD6E7C4),
      onSuccessContainer:
          isDark ? const Color(0xFFD6E7C4) : const Color(0xFF23331A),
      noteTints: _noteTints,
      onNote: _onNote,
      shadow: scheme.shadow.withValues(alpha: isDark ? 0.40 : 0.07),
      // Cream veil on light, smoked charcoal on dark — both let the page tint
      // through instead of stamping a white/black rectangle over it.
      glassFill: isDark
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.58),
      glassStroke: isDark
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.65),
      glassBlur: 18,
    );
  }

  // The bento tints are *fixed pigments*, not tonal derivations, and they are
  // identical in light and dark — a note keeps its exact identity when the
  // theme flips. Deriving them from the scheme instead would collapse them
  // toward one hue in every variant.
  //
  // They are Japandi pastels: high value, low chroma, warm-biased. Anything
  // more saturated fights the sage/oat page instead of sitting in it.
  //
  // Every tint clears 4.5:1 against [_onNote]; `test/theme_test.dart` holds
  // that line, so a new pigment must be checked there before it ships.
  static const List<Color> _noteTints = [
    Color(0xFFC9D9B7), // soft matcha
    Color(0xFFE7D3BC), // milk tea
    Color(0xFFF2D0CC), // muted blush
    Color(0xFFEFE6D2), // oat
    Color(0xFFC3D6DE), // hinoki blue
    Color(0xFFE8DCB8), // champagne
  ];

  /// One ink for all six tints, both brightnesses: muted charcoal, never pure
  /// black — the brief's "dark gray text" rule applies inside cards too.
  static const Color _onNote = Color(0xFF2A2823);

  Color noteTint(int index) => noteTints[index % noteTints.length];

  @override
  KairosPalette copyWith({
    Gradient? heroGradient,
    Color? onHero,
    Color? onHeroVariant,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    List<Color>? noteTints,
    Color? onNote,
    Color? shadow,
    Color? glassFill,
    Color? glassStroke,
    double? glassBlur,
  }) {
    return KairosPalette(
      heroGradient: heroGradient ?? this.heroGradient,
      onHero: onHero ?? this.onHero,
      onHeroVariant: onHeroVariant ?? this.onHeroVariant,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      noteTints: noteTints ?? this.noteTints,
      onNote: onNote ?? this.onNote,
      shadow: shadow ?? this.shadow,
      glassFill: glassFill ?? this.glassFill,
      glassStroke: glassStroke ?? this.glassStroke,
      glassBlur: glassBlur ?? this.glassBlur,
    );
  }

  @override
  KairosPalette lerp(ThemeExtension<KairosPalette>? other, double t) {
    if (other is! KairosPalette) return this;
    return KairosPalette(
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroVariant: Color.lerp(onHeroVariant, other.onHeroVariant, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      noteTints: [
        for (var i = 0; i < noteTints.length; i++)
          Color.lerp(noteTints[i], other.noteTints[i], t)!,
      ],
      onNote: Color.lerp(onNote, other.onNote, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t)!,
    );
  }
}
