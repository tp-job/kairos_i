import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos_i/core/storage/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `sharedPreferencesProvider` override every test needs.
///
/// `sharedPreferencesProvider` throws unless overridden — deliberately, so a
/// forgotten wiring in `main()` fails at launch instead of silently never
/// saving. The cost is that every test constructing a `ProviderScope` or
/// `ProviderContainer` has to supply one too, which is what this is for.
///
/// Call [initPrefs] once inside `setUp`, then spread [prefsOverrides] into
/// the scope. Each call installs a *fresh* in-memory store, so one test's
/// saved tasks cannot leak into the next.
late SharedPreferences _prefs;

Future<void> initPrefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  _prefs = await SharedPreferences.getInstance();
}

List<Override> get prefsOverrides =>
    [sharedPreferencesProvider.overrideWithValue(_prefs)];

/// The live store, for a test that wants to assert what was actually written
/// to disk rather than what the notifier is holding in memory.
SharedPreferences get testPrefs => _prefs;
