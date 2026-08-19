import 'package:flutter/foundation.dart';

/// Who is using the app.
///
/// Kairos has no authentication and no server — this is a *local* profile,
/// stored on the device only. It is modelled explicitly rather than left as
/// a hardcoded string because the dashboard greeted every user as "Marimar",
/// which is somebody else's name on somebody else's phone.
///
/// The shape deliberately matches what a real account would carry, so wiring
/// a sign-in later replaces where this comes from without changing every
/// widget that reads it.
@immutable
class UserProfile {
  const UserProfile({this.displayName = '', this.email = ''});

  /// What the user is called. Empty means they have not set one — the UI
  /// falls back to a name-less greeting rather than inventing a placeholder.
  final String displayName;

  /// Optional, and never sent anywhere. Present so the account screen has a
  /// second real field and so a future sync has somewhere to put it.
  final String email;

  bool get hasName => displayName.trim().isNotEmpty;

  /// One or two letters for the avatar. Falls back to a person glyph at the
  /// call site when there is no name to derive from.
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      // `characters` would be more correct for emoji, but a single grapheme
      // of a Thai or Latin name is what this needs and substring is enough.
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({String? displayName, String? email}) => UserProfile(
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
      );

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.email == email;

  @override
  int get hashCode => Object.hash(displayName, email);
}
