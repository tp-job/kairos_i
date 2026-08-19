import 'package:flutter/material.dart' show IconData, Icons;
import 'package:kairos_i/core/theme/weather_palettes.dart';

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

  /// The glyph for this condition in the day strip.
  ///
  /// Derived from the condition rather than hand-assigned per day, which is
  /// what let the old hardcoded strip pair a snowflake with a sunny label.
  IconData get icon => switch (this) {
        WeatherCondition.sunny => Icons.wb_sunny_rounded,
        WeatherCondition.rainy => Icons.grain_rounded,
        WeatherCondition.clearNight => Icons.nights_stay_rounded,
        WeatherCondition.cool => Icons.cloud_rounded,
        WeatherCondition.snow => Icons.ac_unit_rounded,
      };

  /// Which sky this condition paints.
  ///
  /// The colors themselves live in `core/theme/weather_palettes.dart` as a
  /// [ThemeExtension] — this getter is the whole bridge between the API
  /// vocabulary and the design system. Read the palette with
  /// `context.skies.forSky(condition.sky)`; never hold a `Color` here.
  WeatherSky get sky => switch (this) {
        WeatherCondition.sunny => WeatherSky.day,
        WeatherCondition.rainy => WeatherSky.overcast,
        WeatherCondition.clearNight => WeatherSky.night,
        // Fog/haze/mist/cloudy all read as "misty morning", not "winter".
        WeatherCondition.cool => WeatherSky.cool,
        WeatherCondition.snow => WeatherSky.snow,
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
