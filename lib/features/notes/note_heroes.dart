/// Hero tags for the note container transform.
///
/// The list card and the editor are in different files but must agree on the
/// tag exactly, or the flight silently does not happen — Flutter does not warn
/// about a Hero with no partner. Keeping both sides on these two helpers is
/// what makes that failure impossible rather than merely unlikely.
class NoteHeroes {
  NoteHeroes._();

  /// The FAB → blank editor flight.
  static const newNote = 'note-new';

  /// The card → editor flight for an existing note.
  static String forNote(String id) => 'note-$id';
}
