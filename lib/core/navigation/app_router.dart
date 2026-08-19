import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/account_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/notes/note_form_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/notes/providers/notes_provider.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/weather/weather_glass_screen.dart';
import '../../features/weather/widgets/weather_detail_screen.dart';
import 'routes.dart';
import 'transitions.dart';

/// The app's one route table. Everything that used to be an imperative
/// `Navigator.push(MaterialPageRoute(...))` scattered across eight call sites
/// now has an address here (FR-8.6).
///
/// Shape mirrors `docs/user-flow.md` §2.1. Two structural decisions carry the
/// whole design:
///
/// 1. **[StatefulShellRoute.indexedStack]** — the declarative equivalent of the
///    hand-rolled `IndexedStack` it replaces. Every tab keeps its scroll offset
///    and provider subscriptions while backgrounded (FR-7.1), and each branch
///    now owns its *own* `Navigator`, so a page pushed inside Notes survives a
///    trip to Calendar and back.
/// 2. **`parentNavigatorKey: rootKey` on the weather routes** — the bottom nav
///    is a 108dp bar floating over the page. An edge-to-edge weather canvas is
///    a focused mode, not a destination, so it goes *above* the shell rather
///    than inside it and covers the bar cleanly.
///
/// The note editor is the deliberate exception: it stays *inside* the notes
/// branch, because its container transform is a [Hero] and a Hero cannot fly
/// between two different Navigators. [MainShell] retracts the nav bar for any
/// location that is not a branch root, which gets the editor the full screen
/// without giving up the shared element.

/// Where the app opens. Production boots at the splash; a widget test
/// overrides this to land directly on the screen under test instead of
/// pumping 2200ms of brand hold before every assertion.
final initialLocationProvider = Provider<String>((ref) => Routes.splash);

/// Held by a provider so the router is created once for the app's lifetime —
/// rebuilding it would throw away every branch's navigation stack.
final routerProvider = Provider<GoRouter>((ref) => _buildRouter(ref));

GoRouter _buildRouter(Ref ref) {
  // Created per router, not as top-level finals: a second router (a widget
  // test, a hot restart) reusing the same GlobalKeys throws a duplicate-key
  // assertion that reads as a framework bug rather than the aliasing it is.
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final branchKeys = [
    for (final name in ['dashboard', 'calendar', 'news', 'notes'])
      GlobalKey<NavigatorState>(debugLabel: name),
  ];

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: ref.read(initialLocationProvider),
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: Routes.splash,
        // Boot is not navigation — it should feel like the app resolving,
        // not a page arriving.
        pageBuilder: (context, state) => KairosPage<void>.fadeThrough(
          key: state.pageKey,
          child: SplashScreen(
            onFinished: () => context.go(Routes.dashboard),
          ),
        ),
      ),

      // --- The shell: four tabs behind one floating nav bar ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: branchKeys[0],
            routes: [
              GoRoute(
                path: Routes.dashboard,
                pageBuilder: (context, state) =>
                    _fade(state, const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: branchKeys[1],
            routes: [
              GoRoute(
                path: Routes.calendar,
                pageBuilder: (context, state) =>
                    _fade(state, const CalendarScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: branchKeys[2],
            routes: [
              GoRoute(
                path: Routes.news,
                pageBuilder: (context, state) =>
                    _fade(state, const NewsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: branchKeys[3],
            // The editor's container transform is a [Hero], and a Hero only
            // flies between routes in the *same* Navigator. go_router does not
            // install a HeroController on branch navigators, so the notes
            // branch gets its own — without this the tint would hard-cut
            // instead of flying (user-flow §3, A7).
            observers: [HeroController()],
            routes: [
              GoRoute(
                path: Routes.notes,
                pageBuilder: (context, state) =>
                    _fade(state, const NotesScreen()),
                routes: [
                  // Static path first: otherwise `/notes/new` matches `:id`.
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) =>
                        _fade(state, const NoteFormScreen()),
                  ),
                  GoRoute(
                    path: ':${Routes.noteIdParam}',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters[Routes.noteIdParam]!;
                      return _fade(state, _NoteEditorRoute(id: id));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // --- Focused modes, above the shell ----------------------------------
      GoRoute(
        path: Routes.account,
        parentNavigatorKey: rootKey,
        // Drill-in from the avatar the user just pressed, matching the
        // weather card's gesture.
        pageBuilder: (context, state) => KairosPage<void>.sharedAxisZ(
          key: state.pageKey,
          child: const AccountScreen(),
        ),
      ),
      GoRoute(
        path: Routes.weather,
        parentNavigatorKey: rootKey,
        // Drill-in from the dashboard card the user just pressed: Z-axis says
        // "deeper into the thing you touched".
        pageBuilder: (context, state) => KairosPage<void>.sharedAxisZ(
          key: state.pageKey,
          child: const WeatherGlassScreen(),
        ),
        routes: [
          GoRoute(
            path: 'detail',
            parentNavigatorKey: rootKey,
            // Two alternate presentations of the same data, not a hierarchy —
            // so lateral, not deeper.
            pageBuilder: (context, state) => KairosPage<void>.sharedAxisX(
              key: state.pageKey,
              child: const WeatherDetailScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

/// The default for peers and for pages whose continuity is already carried by
/// a [Hero] — a competing slide would fight the shared element.
Page<void> _fade(GoRouterState state, Widget child) =>
    KairosPage<void>.fadeThrough(key: state.pageKey, child: child);

/// Resolves `/notes/:id` against the live store.
///
/// The id is the address, so the note has to be looked up rather than passed —
/// that is exactly what makes the route linkable and restorable. A missing id
/// (deleted note, stale link) falls back to the list instead of throwing.
class _NoteEditorRoute extends ConsumerWidget {
  const _NoteEditorRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(notesProvider).where((n) => n.id == id);
    if (matches.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.notes);
      });
      return const SizedBox.shrink();
    }
    return NoteFormScreen(note: matches.first);
  }
}
