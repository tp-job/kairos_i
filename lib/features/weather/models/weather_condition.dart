import 'package:flutter/material.dart';

/// Kairos-side representation of "what kind of weather is this?".
///
/// We do NOT reuse the raw string from OpenWeatherMap (`"Rain"`, `"Clear"`,
/// `"Thunderstorm"`, ...) throughout the UI. Instead we map it into this
/// enum once, so:
/// - Illustrations, palettes, and copy live next to the enum, not scattered.
/// - If the API vocabulary changes, only [WeatherCondition.fromApi] is edited.
enum WeatherCondition {
  sunny,
  rainy,
  clearNight,
  cool,
  snow;

  /// The SVG file for this condition.
  /// Filenames are stable — designers can replace the files without
  /// touching Dart code.
  String get assetPath => switch (this) {
        WeatherCondition.sunny => 'assets/illustrations/weather/sunny.svg',
        WeatherCondition.rainy => 'assets/illustrations/weather/rainy.svg',
        WeatherCondition.clearNight =>
          'assets/illustrations/weather/clear-night.svg',
        WeatherCondition.cool => 'assets/illustrations/weather/cool.svg',
        WeatherCondition.snow => 'assets/illustrations/weather/snow.svg',
      };

  /// Short label shown as the rotated tag ("SUNNY", "RAINY", "CLEAR").
  String get shortLabel => switch (this) {
        WeatherCondition.sunny => 'SUNNY',
        WeatherCondition.rainy => 'RAINY',
        WeatherCondition.clearNight => 'CLEAR',
        WeatherCondition.cool => 'COOL',
        WeatherCondition.snow => 'SNOW',
      };

  /// Whole-screen palette for this condition — matches the reference:
  /// paper cream for day, ink black for night.
  WeatherPalette get palette => switch (this) {
        WeatherCondition.sunny => const WeatherPalette(
            background: Color(0xFFF4EFE7),
            ink: Color(0xFF1E1B18),
            mutedInk: Color(0xFF7A6E60),
            accent: Color(0xFFC43A2E),
          ),
        WeatherCondition.rainy => const WeatherPalette(
            background: Color(0xFFEDE8DF),
            ink: Color(0xFF2A2622),
            mutedInk: Color(0xFF7A6E60),
            accent: Color(0xFF3B342E),
          ),
        WeatherCondition.clearNight => const WeatherPalette(
            background: Color(0xFF0F0F10),
            ink: Color(0xFFEDE6D2),
            mutedInk: Color(0xFF9A8E70),
            accent: Color(0xFFD4B15A),
          ),
        // Cool: soft warm cream, slate ink, muted teal accent — reads
        // "misty morning" more than "dead of winter".
        WeatherCondition.cool => const WeatherPalette(
            background: Color(0xFFEDE7DA),
            ink: Color(0xFF2E3B47),
            mutedInk: Color(0xFF7A8794),
            accent: Color(0xFF4A6572),
          ),
        // Snow: near-white paper with a cool blue undertone; deep-navy
        // ink so snowflake linework stays crisp on light background.
        WeatherCondition.snow => const WeatherPalette(
            background: Color(0xFFF1F3F5),
            ink: Color(0xFF243447),
            mutedInk: Color(0xFF7E8B99),
            accent: Color(0xFF3E5B78),
          ),
      };

  /// Map the raw OpenWeatherMap `weather[0].main` string into our enum.
  /// Falls back to sunny for unknown values instead of throwing, because
  /// a broken illustration is better than a broken screen.
  factory WeatherCondition.fromApi(String apiCondition, {bool isNight = false}) {
    if (apiCondition == 'Snow') {
      return WeatherCondition.snow;
    }
    if (apiCondition == 'Rain' ||
        apiCondition == 'Drizzle' ||
        apiCondition == 'Thunderstorm') {
      return WeatherCondition.rainy;
    }
    // OpenWeatherMap groups fog/haze/mist/cloudy under separate strings —
    // for editorial purposes they all read as "cool overcast morning".
    if (apiCondition == 'Mist' ||
        apiCondition == 'Fog' ||
        apiCondition == 'Haze' ||
        apiCondition == 'Smoke' ||
        apiCondition == 'Clouds') {
      return WeatherCondition.cool;
    }
    if (apiCondition == 'Clear' && isNight) {
      return WeatherCondition.clearNight;
    }
    return WeatherCondition.sunny;
  }
}

/// Bundle of colors that theme one weather condition. Kept as a plain
/// class (not a Flutter ThemeData) because we only need it inside the
/// weather detail screen — no need to swap MaterialApp's theme globally.
class WeatherPalette {
  const WeatherPalette({
    required this.background,
    required this.ink,
    required this.mutedInk,
    required this.accent,
  });

  /// Full-screen background wash (paper cream / ink black).
  final Color background;

  /// Primary text + horizon-line color, high-contrast against [background].
  final Color ink;

  /// De-emphasized text (day labels, "C" superscript).
  final Color mutedInk;

  /// Warm illustration accent — sun red, moon gold.
  final Color accent;
}
