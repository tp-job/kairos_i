/// Every address in the app, in one place.
///
/// Call sites use these constants and helpers rather than string literals so
/// a renamed path is a compile error instead of a dead link. Paths mirror the
/// route table in `docs/user-flow.md` §2.1 — change one and change the other.
class Routes {
  Routes._();

  /// Boot screen. The router's initial location; redirects to [dashboard]
  /// once the brand hold elapses.
  static const splash = '/splash';

  // --- Shell branches (one per bottom-nav tab, in nav order) ---------------

  static const dashboard = '/';
  static const calendar = '/calendar';
  static const news = '/news';
  static const notes = '/notes';

  /// Branch index for each tab, matching `BottomNavBar.currentIndex`.
  static const branchOrder = <String>[dashboard, calendar, news, notes];

  // --- Pushed routes (above the shell, so they cover the nav bar) ----------

  static const noteNew = '/notes/new';

  /// The editor for an existing note. Uses [Note.id] as the path parameter,
  /// which is what makes a note a linkable address (see user-flow §5, A1).
  static String noteEdit(String id) => '/notes/$id';

  /// Path parameter name for [noteEdit]; kept here so the router and the
  /// helper cannot drift apart.
  static const noteIdParam = 'id';

  static const weather = '/weather';
  static const weatherDetail = '/weather/detail';

  /// Account and app settings. Above the shell like the weather canvas —
  /// it is a focused mode you come back from, not a fifth tab.
  static const account = '/account';

  /// The assistant conversation. Also above the shell: it is a place you go
  /// to and come back from, and a fifth nav item would shrink every other
  /// tab's hit target to buy it one tap.
  static const chat = '/chat';
}
