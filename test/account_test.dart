// The account screen and the local profile behind it.
//
// The regression that created this screen: theme settings lived in a bottom
// sheet whose `SegmentedButton` gave each Thai contrast label a third of the
// width. "ชัดสูงสุด" did not fit, so the labels overlapped and clipped, and
// the sheet's height cap pushed the last control under the floating nav bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/core/theme/app_theme.dart';
import 'package:kairos_i/core/theme/material_scheme.dart';
import 'package:kairos_i/core/theme/theme_provider.dart';
import 'package:kairos_i/features/account/account_screen.dart';
import 'package:kairos_i/features/account/models/user_profile.dart';
import 'package:kairos_i/features/account/providers/profile_provider.dart';

import 'support/prefs_harness.dart';

ProviderContainer _container() {
  final container = ProviderContainer(overrides: prefsOverrides);
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpAccount(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: prefsOverrides,
      child: MaterialApp(
        theme: AppTheme.buildTheme(MaterialSchemes.light),
        home: const AccountScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => initPrefs());

  group('UserProfile.initials', () {
    test('single name gives one letter', () {
      expect(const UserProfile(displayName: 'Marimar').initials, 'M');
    });

    test('two names give first and last initial', () {
      expect(const UserProfile(displayName: 'Somchai Jaidee').initials, 'SJ');
    });

    test('middle names are skipped — first and last only', () {
      expect(const UserProfile(displayName: 'a b c').initials, 'AC');
    });

    test('extra whitespace does not produce empty initials', () {
      expect(const UserProfile(displayName: '   Nok   ').initials, 'N');
    });

    test('no name gives no initials, never a placeholder letter', () {
      expect(const UserProfile().initials, '');
      expect(const UserProfile(displayName: '   ').initials, '');
    });

    test('Thai names work', () {
      expect(const UserProfile(displayName: 'สมชาย ใจดี').initials, 'สใ');
    });
  });

  group('profile persistence', () {
    test('name and email survive a restart', () {
      _container().read(profileProvider.notifier)
        ..setName('Marimar')
        ..setEmail('marimar@example.com');

      final restarted = _container().read(profileProvider);
      expect(restarted.displayName, 'Marimar');
      expect(restarted.email, 'marimar@example.com');
    });

    test('names are trimmed before they are stored', () {
      _container().read(profileProvider.notifier).setName('  Nok  ');
      expect(_container().read(profileProvider).displayName, 'Nok');
    });

    test('clear() wipes the profile and the wipe survives a restart', () {
      final first = _container();
      first.read(profileProvider.notifier)
        ..setName('Marimar')
        ..setEmail('marimar@example.com');
      first.read(profileProvider.notifier).clear();

      final restarted = _container().read(profileProvider);
      expect(restarted.hasName, isFalse);
      expect(restarted.email, isEmpty);
    });
  });

  group('greeting', () {
    test('omits the name entirely when none is set', () {
      // The header used to hardcode "สวัสดี, Marimar 👋" — every user was
      // greeted by a stranger's name.
      final greeting = _container().read(greetingProvider);
      expect(greeting, isNot(contains('Marimar')));
      expect(greeting, contains('สวัสดี'));
      expect(greeting.trim(), isNot(endsWith(',')));
    });

    test('includes the name once one is set', () {
      final container = _container();
      container.read(profileProvider.notifier).setName('มาริมาร์');
      expect(container.read(greetingProvider), contains('มาริมาร์'));
    });
  });

  group('AccountScreen layout', () {
    // The actual regression. A RenderFlex overflow throws during paint in
    // debug, so `takeException` is what catches the bug that shipped.
    testWidgets('renders without overflow on a narrow phone', (tester) async {
      await _pumpAccount(tester, size: const Size(320, 800));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on a normal phone', (tester) async {
      await _pumpAccount(tester, size: const Size(412, 915));

      expect(tester.takeException(), isNull);
    });

    testWidgets('every contrast label is fully visible, not clipped',
        (tester) async {
      await _pumpAccount(tester, size: const Size(320, 800));

      // All three were competing for a third of the width each in the
      // segmented control; as full-width rows they each get the whole line.
      for (final contrast in AppContrast.values) {
        final label = find.text(contrast.thaiLabel);
        expect(label, findsOneWidget, reason: '${contrast.name} is missing');

        final size = tester.getSize(label);
        expect(size.width, greaterThan(0));
        expect(
          tester.getTopLeft(label).dx,
          greaterThanOrEqualTo(0),
          reason: '${contrast.name} starts off-screen',
        );
      }
    });

    testWidgets('every theme mode label is present too', (tester) async {
      await _pumpAccount(tester, size: const Size(320, 800));

      for (final mode in ThemeMode.values) {
        expect(find.text(mode.thaiLabel), findsOneWidget);
      }
    });

    testWidgets('tapping a mode row changes the theme', (tester) async {
      await _pumpAccount(tester, size: const Size(412, 915));

      await tester.tap(find.text(ThemeMode.dark.thaiLabel));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AccountScreen)),
      );
      expect(container.read(themeProvider).mode, ThemeMode.dark);
    });

    testWidgets('tapping a contrast row changes the contrast', (tester) async {
      await _pumpAccount(tester, size: const Size(412, 915));

      await tester.tap(find.text(AppContrast.high.thaiLabel));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AccountScreen)),
      );
      expect(container.read(themeProvider).contrast, AppContrast.high);
    });
  });
}
