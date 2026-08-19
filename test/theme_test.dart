// Conformance tests for the Material Theme Builder design system.
//
// The point of these is the *matrix*: every primary screen is rendered under
// all six exported schemes. A widget that hard-codes a color still passes
// analysis and still renders — it just renders wrong — so what these catch is
// the class of failure that killed the previous theme: a screen that only
// builds (or only reads) under one brightness.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/core/theme/app_theme.dart';
import 'package:kairos_i/core/theme/design_tokens.dart';
import 'package:kairos_i/core/theme/kairos_palette.dart';
import 'package:kairos_i/core/theme/material_scheme.dart';
import 'package:kairos_i/core/theme/weather_palettes.dart';
import 'package:kairos_i/features/account/account_screen.dart';
import 'package:kairos_i/features/calendar/calendar_screen.dart';
import 'package:kairos_i/features/dashboard/dashboard_screen.dart';
import 'package:kairos_i/features/news/news_screen.dart';
import 'package:kairos_i/features/notes/notes_screen.dart';

import 'support/prefs_harness.dart';

const _schemes = <String, ColorScheme>{
  'light': MaterialSchemes.light,
  'light-medium': MaterialSchemes.lightMediumContrast,
  'light-high': MaterialSchemes.lightHighContrast,
  'dark': MaterialSchemes.dark,
  'dark-medium': MaterialSchemes.darkMediumContrast,
  'dark-high': MaterialSchemes.darkHighContrast,
};

/// Relative luminance contrast ratio (WCAG 2.1).
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() => initPrefs());

  group('every screen builds under every exported scheme', () {
    final screens = <String, Widget>{
      'dashboard': const DashboardScreen(),
      'calendar': const CalendarScreen(),
      'news': const NewsScreen(),
      'notes': const NotesScreen(),
      'account': const AccountScreen(),
    };

    for (final scheme in _schemes.entries) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} @ ${scheme.key}', (tester) async {
          // A phone-sized surface; the dashboard's horizontal card row and
          // the notes masonry both overflow on the 800x600 test default.
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              overrides: prefsOverrides,
              child: MaterialApp(
                theme: AppTheme.buildTheme(scheme.value),
                home: screen.value,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));

          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('KairosPalette', () {
    for (final scheme in _schemes.entries) {
      test('hero content is legible on the hero fill @ ${scheme.key}', () {
        final palette = KairosPalette.fromScheme(scheme.value);
        final fill = (palette.heroGradient as LinearGradient).colors;

        // Both ends of the gradient must clear WCAG AA for large text (3:1)
        // against the content color the widgets are told to use.
        for (final stop in fill) {
          expect(
            _contrast(stop, palette.onHero),
            greaterThanOrEqualTo(3.0),
            reason: 'onHero on $stop is unreadable in ${scheme.key}',
          );
        }
      });

      test('note ink is legible on every note tint @ ${scheme.key}', () {
        final palette = KairosPalette.fromScheme(scheme.value);
        for (final tint in palette.noteTints) {
          expect(
            _contrast(tint, palette.onNote),
            greaterThanOrEqualTo(4.5),
            reason: 'note body text on $tint fails AA in ${scheme.key}',
          );
        }
      });
    }

    test('tint count matches the model contract', () {
      expect(
        KairosPalette.fromScheme(MaterialSchemes.light).noteTints.length,
        KairosPalette.fromScheme(MaterialSchemes.dark).noteTints.length,
      );
    });
  });

  // The weather screen is the one that regressed: it held its own Color table
  // and painted a cream page underneath a dark app. These lock both halves of
  // that fix — the pigments are reachable through the theme, and every text
  // pair on the poster is actually legible.
  group('WeatherPalettes', () {
    for (final scheme in _schemes.entries) {
      test('the extension is registered on the built theme @ ${scheme.key}',
          () {
        // A missing registration silently falls back to `fromScheme`, so
        // asserting the pigments alone would pass even if AppTheme forgot it.
        final theme = AppTheme.buildTheme(scheme.value);
        expect(
          theme.extension<WeatherPalettes>(),
          isNotNull,
          reason: 'WeatherPalettes missing from ThemeData in ${scheme.key}',
        );
      });

      test('every sky follows the scheme brightness @ ${scheme.key}', () {
        final skies = WeatherPalettes.fromScheme(scheme.value);
        for (final sky in WeatherSky.values) {
          // Night depicts a night sky in both brightnesses — it is content,
          // not chrome, and is the documented exception.
          if (sky == WeatherSky.night) continue;
          expect(
            ThemeData.estimateBrightnessForColor(skies.forSky(sky).background),
            scheme.value.brightness,
            reason: '$sky ignores ${scheme.key} brightness',
          );
        }
      });

      test('ink and mutedInk clear AA on their own sky @ ${scheme.key}', () {
        final skies = WeatherPalettes.fromScheme(scheme.value);
        for (final sky in WeatherSky.values) {
          final p = skies.forSky(sky);
          // Both carry small type (the city name is 11px), so this is the
          // 4.5:1 body-text threshold, not the 3:1 large-text one.
          expect(
            _contrast(p.background, p.ink),
            greaterThanOrEqualTo(4.5),
            reason: '$sky ink fails AA in ${scheme.key}',
          );
          expect(
            _contrast(p.background, p.mutedInk),
            greaterThanOrEqualTo(4.5),
            reason: '$sky mutedInk fails AA in ${scheme.key}',
          );
        }
      });

      test('the accent is legible as the selected day label @ ${scheme.key}',
          () {
        final skies = WeatherPalettes.fromScheme(scheme.value);
        for (final sky in WeatherSky.values) {
          final p = skies.forSky(sky);
          expect(
            _contrast(p.background, p.accent),
            greaterThanOrEqualTo(4.5),
            reason: '$sky accent fails AA in ${scheme.key}',
          );
        }
      });
    }

    test('every sky is defined in both brightnesses', () {
      for (final scheme in [MaterialSchemes.light, MaterialSchemes.dark]) {
        final skies = WeatherPalettes.fromScheme(scheme);
        for (final sky in WeatherSky.values) {
          expect(skies.skies[sky], isNotNull, reason: '$sky missing');
        }
      }
    });
  });

  // The Japandi brief's two constraints that nothing else in the suite would
  // catch. Both have already been lost once by a well-meaning re-export.
  group('Japandi brief invariants', () {
    test('every surface is warm — red channel leads blue', () {
      for (final scheme in _schemes.entries) {
        for (final surface in <String, Color>{
          'surface': scheme.value.surface,
          'surfaceContainer': scheme.value.surfaceContainer,
          'surfaceContainerHigh': scheme.value.surfaceContainerHigh,
        }.entries) {
          // A cool or neutral page is the single failure that turns this
          // system back into the grey export it was corrected from.
          expect(
            (surface.value.r * 255).round(),
            greaterThanOrEqualTo((surface.value.b * 255).round()),
            reason:
                '${surface.key} in ${scheme.key} is cool-biased, not warm cream',
          );
        }
      }
    });

    test('the signature corner stays inside the brief\'s 16–24 range', () {
      expect(DesignTokens.radius2xl, inInclusiveRange(16, 24));
      expect(DesignTokens.radiusLg, inInclusiveRange(16, 24));
    });
  });
}
