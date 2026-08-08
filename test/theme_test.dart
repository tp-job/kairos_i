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
import 'package:kairos_i/features/calendar/calendar_screen.dart';
import 'package:kairos_i/features/chat/chat_screen.dart';
import 'package:kairos_i/features/dashboard/dashboard_screen.dart';
import 'package:kairos_i/features/notes/notes_screen.dart';

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
  group('every screen builds under every exported scheme', () {
    final screens = <String, Widget>{
      'dashboard': const DashboardScreen(),
      'calendar': const CalendarScreen(),
      'chat': const ChatScreen(),
      'notes': const NotesScreen(),
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
