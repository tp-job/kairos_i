import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one on-device key/value store.
///
/// Held as a plain [Provider] that throws until `main()` overrides it with a
/// resolved instance. That is deliberate: every notifier that persists reads
/// it *synchronously* in its constructor, so a `FutureProvider` here would
/// force the whole task/note/theme layer to become async for a value that is
/// always available a few milliseconds after launch.
///
/// A thrown error rather than a nullable also means a forgotten override
/// fails loudly at startup instead of silently never saving anything.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider was not overridden in ProviderScope. '
    'main() must await SharedPreferences.getInstance() and pass it in.',
  ),
);

/// Every key this app writes. Keeping them in one place is what makes a
/// rename safe and a migration findable.
class PrefKeys {
  PrefKeys._();

  static const tasks = 'kairos.tasks.v1';
  static const notes = 'kairos.notes.v1';
  static const themeMode = 'kairos.theme.mode.v1';
  static const themeContrast = 'kairos.theme.contrast.v1';

  static const profileName = 'kairos.profile.name.v1';
  static const profileEmail = 'kairos.profile.email.v1';

  /// Set once the first launch has completed. Distinguishes "the user has no
  /// tasks" from "we have never run", which are the same empty list but need
  /// different UI.
  static const seeded = 'kairos.seeded.v1';
}
