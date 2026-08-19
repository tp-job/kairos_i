import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/prefs.dart';
import '../models/user_profile.dart';

/// Owns the local profile, persisted like tasks and notes.
class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier(this._prefs) : super(const UserProfile()) {
    state = UserProfile(
      displayName: _prefs.getString(PrefKeys.profileName) ?? '',
      email: _prefs.getString(PrefKeys.profileEmail) ?? '',
    );
  }

  final SharedPreferences _prefs;

  void setName(String name) {
    final trimmed = name.trim();
    state = state.copyWith(displayName: trimmed);
    _prefs.setString(PrefKeys.profileName, trimmed);
  }

  void setEmail(String email) {
    final trimmed = email.trim();
    state = state.copyWith(email: trimmed);
    _prefs.setString(PrefKeys.profileEmail, trimmed);
  }

  /// Wipes the local profile. Not a sign-out — there is no session — but the
  /// account screen needs a way to undo "I typed my name into a demo app".
  void clear() {
    state = const UserProfile();
    _prefs.remove(PrefKeys.profileName);
    _prefs.remove(PrefKeys.profileEmail);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(ref.watch(sharedPreferencesProvider)),
);

/// The dashboard's greeting line, e.g. "สวัสดีตอนเช้า, มาริมาร์ 👋".
///
/// Derived rather than stored: it changes with the clock, and the header
/// previously hardcoded both the time-of-day and the name.
final greetingProvider = Provider<String>((ref) {
  final name = ref.watch(profileProvider).displayName.trim();
  final hour = DateTime.now().hour;

  final part = switch (hour) {
    >= 5 && < 12 => 'สวัสดีตอนเช้า',
    >= 12 && < 17 => 'สวัสดีตอนบ่าย',
    >= 17 && < 21 => 'สวัสดีตอนเย็น',
    // 21:00–04:59. Not "good night" — the user is still awake and using it.
    _ => 'สวัสดีตอนดึก',
  };

  return name.isEmpty ? '$part 👋' : '$part, $name 👋';
});
