import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kairos_i/core/navigation/app_router.dart';
import 'package:kairos_i/core/theme/app_theme.dart';
import 'package:kairos_i/core/theme/material_scheme.dart';

import 'prefs_harness.dart';

/// Pumps the real app — real route table, real shell, real transitions —
/// opened directly at [location].
///
/// The caller must have run `initPrefs()` (normally in `setUp`) — this only
/// spreads the resulting override in. Keeping the init in the test rather
/// than here is what lets a test write to the store *before* pumping, to
/// stand in for data saved on a previous launch.
///
/// Overriding `initialLocationProvider` rather than driving the splash means a
/// navigation test asserts on navigation, not on a 2200ms brand hold. Phone
/// metrics because the dashboard's card row and the notes masonry both
/// overflow the 800x600 test default.
Future<void> pumpAppAt(
  WidgetTester tester,
  String location, {
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialLocationProvider.overrideWithValue(location),
        ...prefsOverrides,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.buildTheme(MaterialSchemes.light),
          routerConfig: ref.read(routerProvider),
          // Stands in for the OS "remove animations" setting, which is what
          // AppMotion.reduced reads.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reducedMotion),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
