import 'package:flutter/material.dart';

/// Which sky the weather screen is painting.
///
/// This lives in `core/theme` rather than in the weather feature on purpose:
/// the palette extension below is keyed by it, and core must not import a
/// feature. The feature owns the *API mapping* (`WeatherCondition.sky`) and
/// core owns the *pigments* — so the dependency only ever points inward.
enum WeatherSky { day, overcast, night, cool, snow }

/// The four colors that dress one full-screen weather poster.
///
/// [background] and [ink] are always defined as a pair, which is what makes
/// the contrast guarantee checkable: `test/theme_test.dart` asserts every
/// pair clears WCAG AA rather than trusting that they look fine.
@immutable
class WeatherPalette {
  const WeatherPalette({
    required this.background,
    required this.ink,
    required this.mutedInk,
    required this.accent,
  });

  /// Full-screen wash (paper cream by day, ink black at night).
  final Color background;

  /// Primary text and the horizon line. High contrast against [background].
  final Color ink;

  /// De-emphasized text — day labels, the "C" superscript, the English city
  /// name. Small type at 11px, so this is held to AA 4.5:1, not 3:1.
  final Color mutedInk;

  /// The one saturated note per sky: sun red, moon gold, slate teal.
  final Color accent;

  static WeatherPalette lerp(WeatherPalette a, WeatherPalette b, double t) {
    return WeatherPalette(
      background: Color.lerp(a.background, b.background, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      mutedInk: Color.lerp(a.mutedInk, b.mutedInk, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
    );
  }
}

/// The weather screen's five skies, as a [ThemeExtension].
///
/// Before this existed the weather feature held its own `Color(0x...)` table
/// and rendered a cream page underneath a dark app — the one screen in Kairos
/// that ignored `ThemeMode`. Moving the pigments here is what puts it back
/// under `Theme.of(context)` with everything else.
///
/// **The light values are byte-identical to the ones the feature shipped**,
/// with one exception: four `mutedInk` values were darkened because they
/// failed AA against their own background (day was 4.34:1, cool 2.98:1,
/// snow 3.13:1, overcast 4.07:1 — all carrying 11px text). Those are
/// corrections, not a restyle.
///
/// Unlike the rest of the system these are **fixed pigments, not tonal
/// derivations** — the same call `KairosPalette` makes for its note tints. A
/// sky derived from `scheme.primary` would collapse all five toward sage and
/// lose the thing that makes the screen readable at a glance. They vary by
/// brightness only; the three contrast tiers leave them alone, which is safe
/// because every pair already clears AA in the standard scheme.
@immutable
class WeatherPalettes extends ThemeExtension<WeatherPalettes> {
  const WeatherPalettes({required this.skies});

  final Map<WeatherSky, WeatherPalette> skies;

  /// Falls back to deriving from the ambient scheme when the surrounding
  /// theme was not built by `AppTheme` — a bare `MaterialApp` in a widget
  /// test, a `Theme` override in a preview. Better a derived palette than a
  /// null check that crashes the tree.
  static WeatherPalettes of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<WeatherPalettes>() ??
        WeatherPalettes.fromScheme(theme.colorScheme);
  }

  WeatherPalette forSky(WeatherSky sky) => skies[sky]!;

  factory WeatherPalettes.fromScheme(ColorScheme scheme) {
    return WeatherPalettes(
      skies: scheme.brightness == Brightness.dark ? _dark : _light,
    );
  }

  // ---------------------------------------------------------------------
  // Light: the shipped editorial look. Cream paper, ink type, one warm note.
  // ---------------------------------------------------------------------
  static const Map<WeatherSky, WeatherPalette> _light = {
    WeatherSky.day: WeatherPalette(
      background: Color(0xFFF4EFE7),
      ink: Color(0xFF1E1B18),
      mutedInk: Color(0xFF746859), // was #7A6E60 — 4.34:1, under AA
      accent: Color(0xFFC43A2E),
    ),
    WeatherSky.overcast: WeatherPalette(
      background: Color(0xFFEDE8DF),
      ink: Color(0xFF2A2622),
      mutedInk: Color(0xFF6F6456), // was #7A6E60 — 4.07:1, under AA
      accent: Color(0xFF3B342E),
    ),
    // Night is dark in *both* brightnesses. It depicts a night sky — that is
    // content, not chrome, and inverting it to cream would be a lie about the
    // weather. It is the one sky that does not flip.
    WeatherSky.night: WeatherPalette(
      background: Color(0xFF0F0F10),
      ink: Color(0xFFEDE6D2),
      mutedInk: Color(0xFF9A8E70),
      accent: Color(0xFFD4B15A),
    ),
    WeatherSky.cool: WeatherPalette(
      background: Color(0xFFEDE7DA),
      ink: Color(0xFF2E3B47),
      mutedInk: Color(0xFF58646F), // was #7A8794 — 2.98:1, well under AA
      accent: Color(0xFF4A6572),
    ),
    WeatherSky.snow: WeatherPalette(
      background: Color(0xFFF1F3F5),
      ink: Color(0xFF243447),
      mutedInk: Color(0xFF5A6775), // was #7E8B99 — 3.13:1, well under AA
      accent: Color(0xFF3E5B78),
    ),
  };

  // ---------------------------------------------------------------------
  // Dark: same hue identity, inverted ground. The accent is *lightened*
  // rather than reused — a #3B342E near-black accent on a dark page is
  // invisible, which is exactly the failure this table exists to prevent.
  // ---------------------------------------------------------------------
  static const Map<WeatherSky, WeatherPalette> _dark = {
    WeatherSky.day: WeatherPalette(
      background: Color(0xFF1C1A17), // warm charcoal, not neutral black
      ink: Color(0xFFF1EBE1),
      mutedInk: Color(0xFFA2968A),
      accent: Color(0xFFE8705F),
    ),
    WeatherSky.overcast: WeatherPalette(
      background: Color(0xFF1A1815),
      ink: Color(0xFFE9E3D9),
      mutedInk: Color(0xFF9C9184),
      accent: Color(0xFFC9BDAE),
    ),
    WeatherSky.night: WeatherPalette(
      background: Color(0xFF0F0F10),
      ink: Color(0xFFEDE6D2),
      mutedInk: Color(0xFF9A8E70),
      accent: Color(0xFFD4B15A),
    ),
    WeatherSky.cool: WeatherPalette(
      background: Color(0xFF14181C),
      ink: Color(0xFFDCE5EC),
      mutedInk: Color(0xFF8C9AA8),
      accent: Color(0xFF7FA3B5),
    ),
    WeatherSky.snow: WeatherPalette(
      background: Color(0xFF121820),
      ink: Color(0xFFE2EAF2),
      mutedInk: Color(0xFF8B99A8),
      accent: Color(0xFF7FA6CC),
    ),
  };

  @override
  WeatherPalettes copyWith({Map<WeatherSky, WeatherPalette>? skies}) =>
      WeatherPalettes(skies: skies ?? this.skies);

  @override
  WeatherPalettes lerp(ThemeExtension<WeatherPalettes>? other, double t) {
    if (other is! WeatherPalettes) return this;
    return WeatherPalettes(
      skies: {
        for (final sky in WeatherSky.values)
          sky: WeatherPalette.lerp(forSky(sky), other.forSky(sky), t),
      },
    );
  }
}
