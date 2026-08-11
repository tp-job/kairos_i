# Kairos — User Flow & Navigation System

**Version:** 1.0
**Date:** 2026-08-11
**Traces:** `FR-8.6` (declarative navigation + deep links) · `FR-7.1` (single floating nav, state preserved) · `FR-7.5` / `DEF-6` (Chat is mock) · `NFR-A4` (reduced motion) — see [srs.md](srs.md)
**Implements:** [sprint-plan.md](sprint-plan.md) items **3.1** (cut Chat, promote Notes) and **3.2** (adopt `go_router`)

> **How to read this.** §2 is the flow map — the *what*. §3 is the transition
> contract — the *how*, one named Flutter technique per edge, with the reason.
> §5 is the proof list; nothing here is "done" until §5 is demonstrated.
> Status markers match the SRS: **`[IMPL]`** · **`[PARTIAL]`** · **`[PLANNED]`**.

---

## 1. Why this exists

Three specific defects in navigation as it stood at `f038919`:

1. **The route table lived in eight scattered `Navigator.push(MaterialPageRoute(...))`
   call sites.** No single place described the app's shape, so no deep link, no
   restoration, and no way to reason about the back stack. (`FR-8.6`)
2. **`AppMotion` was ignored at exactly the moment motion is most visible.**
   [motion.dart](../lib/core/motion/motion.dart) defines a deliberate vocabulary —
   `emphasized`, `medium`, a real `SpringSimulation` — and every page transition
   fell through to Material's stock zoom instead. Cards spring under the finger;
   then the page they open arrives in a different physics. That is one system
   speaking with two voices.
3. **A quarter of primary navigation went to a screen made of hard-coded
   contacts** (`DEF-6`), while Notes — real, finished, tested — had no nav home
   and was reachable only through a dashboard mini-card.

The fix is one route table, one transition vocabulary derived from `AppMotion`,
and four tabs that each do something real.

---

## 2. The flow map

### 2.1 Route table

```
/splash                         SplashScreen        (root, no chrome)
  └─ auto-advance after 2200ms ─► /

StatefulShellRoute.indexedStack ─► MainShell (owns BottomNavBar)
  branch 0  /                     DashboardScreen
  branch 1  /calendar             CalendarScreen
  branch 2  /news                 NewsScreen
  branch 3  /notes                NotesScreen
              /notes/new          NoteFormScreen()          [root navigator]
              /notes/:id          NoteFormScreen(note: …)   [root navigator]

/weather                          WeatherGlassScreen        [root navigator]
  /weather/detail                 WeatherDetailScreen       [root navigator]
```

**Why `StatefulShellRoute.indexedStack` and not `ShellRoute`.** `FR-7.1` requires
each tab to keep its scroll offset and provider subscriptions while backgrounded.
`indexedStack` is the declarative equivalent of the hand-rolled `IndexedStack`
it replaces — same guarantee, but each branch now owns *its own `Navigator`*, so
a stack pushed inside Notes survives a trip to Calendar and back.

**Why `[root navigator]` on the weather routes.** The bottom nav is a floating
bar 108dp tall drawn over the page. An edge-to-edge weather canvas must cover
it, not fight it. Declaring `parentNavigatorKey: rootNavigatorKey` puts those
routes *above* the shell instead of inside it — the correct expression of "this
is a focused mode, not a destination."

**The note editor is the deliberate exception, and it forced a design change.**
A `Hero` only flies between routes in the *same* `Navigator`, so an editor on
the root navigator could not have the container transform §3 calls for — the
tint would hard-cut. The editor therefore stays inside the notes branch, and
the shell **retracts the nav bar** (`AnimatedSlide` + `IgnorePointer`) for any
location that is not a branch root. The editor still gets the full screen; the
shared element survives. Two consequences worth stating plainly:

* The notes branch needs its own `HeroController` in `observers:` — go_router
  does not install one on branch navigators, and a Hero with no controller
  fails **silently**.
* While a focused mode is open the nav bar is not merely hidden, it is
  non-interactive. Switching tabs from inside the editor is not a user-reachable
  flow (see A1).

### 2.2 Entry points per destination

| Destination | Reachable from | Mechanism |
|---|---|---|
| Dashboard | app launch; nav tab 0; system back from any other branch root | `go('/')` |
| Calendar | nav tab 1 | branch switch |
| News | nav tab 2 | branch switch |
| Notes | nav tab 3; dashboard Notes mini-card | branch switch (`go('/notes')`) |
| Note editor (new) | Notes FAB | `push('/notes/new')` |
| Note editor (edit) | tap a note card | `push('/notes/<id>')` |
| Weather (glass) | dashboard weather card | `push('/weather')` |
| Weather (editorial detail) | glass screen gear icon; weather card in the older layout | `push('/weather/detail')` |
| Quick-add task | centre "+" from **any** tab | `showModalBottomSheet` on the **root** navigator |

The quick-add sheet is deliberately *not* a route. It is a transient mode with
no address: there is nothing meaningful to deep-link to, and putting it in the
table would let a link drop a user into a half-filled form with no back stack.

### 2.3 Back behavior — the contract

| Where the user is | System back / gesture does | Why |
|---|---|---|
| Dashboard (branch 0, empty stack) | exits the app | the one true root |
| Calendar / News / Notes root | returns to **Dashboard**, does not exit | a tab is not a history entry; exiting from tab 3 is the classic Android bug |
| Note editor | pops back to the list | the branch's own Navigator handles it first; the header's back button additionally **saves**, matching the behavior it already had (the editor has no discard affordance and never had one) |
| Weather detail → glass → dashboard | pops one level each | ordinary drill-out |
| Quick-add sheet | dismisses, no write | a sheet is cancellable by definition |

Implemented as a `PopScope(canPop: …)` in `MainShell`, evaluated against the
current branch index and that branch's own `Navigator.canPop()`.

### 2.4 What was removed

`lib/features/chat/` is deleted (`DEF-6`). Five hard-coded contacts with
hard-coded previews occupied 25% of primary navigation and delivered zero
function; shipping them teaches the user the app lies. Notes takes the slot.
The parked backlog entry in [sprint-plan.md](sprint-plan.md) §6 stands: chat for
real is a backend epic, not a tab.

---

## 3. The transition contract

One rule: **every transition in the app resolves its duration and curve from
`AppMotion`.** No literal `Duration` and no bare `Curves.*` appears in a route.

Material 3 names four motion patterns; the table below assigns each edge in §2.1
exactly one, and states the reason. This is the "Flutter design technique" column
— it is what makes the app read as designed rather than assembled.

| Edge | Pattern | Flutter technique | Reason |
|---|---|---|---|
| Tab ↔ tab | **Fade through** | `AnimatedBuilder` over the `IndexedStack`: opacity `0.4→1`, scale `0.985→1`, `AppMotion.medium` + `emphasized` | Peers with no hierarchy. No directional slide, because there is no direction — tab 3 is not "right of" tab 0 in any user's mental model |
| Dashboard card → `/weather` | **Shared axis Z** | `KairosPage.sharedAxisZ` — outgoing scales to `1.10` and fades, incoming enters at `0.80` and fades in, `AppMotion.medium` | Drill-in. Z-axis says "deeper into the thing you touched", which is exactly what the card promised when it dipped under the finger |
| Notes list → `/notes/:id` | **Container transform** | `Hero(tag: 'note-<id>')` on the card's tinted surface + `KairosPage.fadeThrough` for the body | The note *is* the container. Its tint is its identity (`FR-4.3`); carrying that rectangle into the editor is the strongest continuity signal available |
| Notes FAB → `/notes/new` | **Container transform** | `Hero(tag: 'note-new')` on the FAB | Same argument; the FAB is the seed of the new note |
| `/weather` ↔ `/weather/detail` | **Shared axis X** | `KairosPage.sharedAxisX` — ±30% width slide + fade, `AppMotion.medium` | Two *alternate presentations* of the same data, not a hierarchy. X-axis is the only pattern that says "sideways, same level" |
| Splash → shell | **Fade through** | `go_router` redirect + `KairosPage.fadeThrough` | Boot is not navigation; it should feel like the app resolving, not a page arriving |
| Anything → quick-add sheet | **Modal** | `showModalBottomSheet(useRootNavigator: true)` | Transient, cancellable, over everything |

**Press feedback stays where it is.** `PressableScale` already runs a
`SpringSimulation` seeded with live velocity. The route transitions are
curve-based on purpose: a page is not something the finger is still touching, so
there is no velocity to carry, and a spring on a full-screen page reads as
sloppy rather than tactile.

**Reduced motion (`NFR-A4`).** `KairosPage` checks `AppMotion.reduced(context)`
and returns the child unanimated — no cross-fade, no scale. Honouring the
platform flag at the transition layer means every route gets it for free rather
than per-screen.

---

## 4. File layout

| File | Responsibility |
|---|---|
| `lib/core/navigation/app_router.dart` | The single route table. `rootNavigatorKey`, `shellNavigatorKeys`, the `GoRouter` instance behind a Riverpod provider |
| `lib/core/navigation/transitions.dart` | `KairosPage` — `fadeThrough`, `sharedAxisX`, `sharedAxisZ`. The only place a page transition is defined |
| `lib/core/navigation/routes.dart` | Path constants + typed helpers (`Routes.noteEdit(id)`). No string literal path appears at a call site |
| `lib/features/notes/note_heroes.dart` | The two Hero tags. Both sides of a flight must agree exactly, and a Hero with no partner fails silently — one file makes that impossible rather than unlikely |
| `lib/features/shell/main_shell.dart` | Consumes `StatefulNavigationShell`; owns the nav bar, its retraction, and the `PopScope` contract |
| `test/support/router_harness.dart` | `pumpAppAt(tester, location)` — pumps the real router at a given address, optionally with motion reduced |

`main.dart` moves from `MaterialApp(home:)` to `MaterialApp.router`.

---

## 5. Acceptance criteria

Each is observable; none is satisfied by "it compiles."

| # | Criterion | Traces | Verified by |
|---|---|---|---|
| **A1** | A branch that has a page pushed keeps it when the branch is left and re-entered, with typed text intact. *(Amended: the original wording routed this through a tab tap from inside the editor. The nav bar retracts for focused modes, so that path does not exist — the guarantee is real, the user route to it is a jump by address, not a tab tap.)* | FR-7.1, FR-8.6 | `navigation_test.dart` |
| **A2** | Scroll the dashboard, visit Notes, return: the scroll offset is unchanged. | FR-7.1 | `navigation_test.dart` |
| **A3** | From a non-dashboard branch root, system back lands on Dashboard; with a page pushed, it pops that page first. | §2.3 | `navigation_test.dart` |
| **A4** | `grep -rn "MaterialPageRoute" lib/` returns nothing. | FR-8.6 | grep — clean |
| **A5** | No literal `Duration` or bare `Curves.*` in `lib/core/navigation/` — every timing comes from `AppMotion`. | §3 | grep — clean |
| **A6** | With animations disabled, a route change is complete in one frame with no partial fade on the page's transition wrapper. | NFR-A4 | `navigation_test.dart` |
| **A7** | Tapping a note animates its tinted rectangle into the editor's background; the tint never flashes to a different colour mid-flight, in any of the six theme variants. | FR-4.3 | **not yet verified** — device check, see below |
| **A8** | `lib/features/chat/` does not exist; the nav bar's fourth slot reads `โน้ต` and opens the notes list. | DEF-6, FR-7.5 | `navigation_test.dart` + grep |
| **A9** | `flutter analyze` clean; `flutter test` green, including the six-variant render matrix. | NFR-M1, NFR-M2 | analyze clean · 64 tests green |

**A7 is the one criterion still open.** The Hero pair, its shuttle and the
branch `HeroController` are all in place and the six-variant render matrix
passes, but a shared-element *flight* is a per-frame visual property: a widget
test can confirm the Heroes exist and cannot confirm the tint stays constant
across the flight. Run it on a device before calling this done.

### Regression found and fixed during the build

Promoting Notes from a pushed page to a tab put its "new note" FAB **behind**
the floating nav bar — rendered, but not tappable. It had never collided
before, because the screen used to sit above the shell. Fixed by lifting the FAB
by `navBarClearance`; caught by the A1 test, not by looking at it.

### Explicitly out of scope for this change

| Item | Status | Why |
|---|---|---|
| OS-level deep links (Android `intent-filter`, iOS associated domains) | `[PLANNED]` | The route table makes them *possible* — `/notes/<id>` is now an address — but registering a scheme with the OS is a platform-manifest change and a product decision about what the scheme should be. Claiming deep links work before that is exactly the kind of unverified "done" the SRS forbids |
| Route restoration across process death | `[PLANNED]` | Blocked on `DEF-3`: restoring `/notes/<id>` is meaningless while the note store is in-memory and the note is gone. Do it after Sprint 1 persistence |
| Android predictive back | `[PARTIAL]` | Custom page transitions replace the predictive-back animation on the routes that declare them. The gesture still works; the peek-behind preview does not render for them |

---

## 6. Traceability

| Requirement | Before | After |
|---|---|---|
| `FR-8.6` — declarative navigation | `[PLANNED]` | `[PARTIAL]` — declarative table done; OS deep-link registration outstanding |
| `FR-7.5` / `DEF-6` — Chat is mock | `[MOCK]` | **Closed by removal** |
| `FR-7.1` — nav preserves state | `[IMPL]` | `[IMPL]` — mechanism changed, guarantee unchanged and now covers per-tab stacks |
| `NFR-A4` — reduced motion | `[IMPL]` | `[IMPL]` — extended to route transitions |
