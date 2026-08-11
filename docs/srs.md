# Kairos — Software Requirements Specification

**Version:** 1.0
**Date:** 2026-08-05
**Status:** Baselined against commit `8021e37` + working tree
**Product:** Kairos (`kairos_i`) — a Thai-language personal AI dashboard for Flutter
**Author:** Engineering

> **How to read this.** Requirements are written against **what the code actually
> does today**, not against an aspiration. Each requirement carries a status:
> **`[IMPL]`** shipped and verifiable · **`[PARTIAL]`** works but with a stated
> gap · **`[MOCK]`** UI exists over hard-coded data · **`[PLANNED]`** not built.
> The sprint plan in [sprint-plan.md](sprint-plan.md) is derived from the
> non-`[IMPL]` rows and nothing else.

---

## 1. Introduction

### 1.1 Purpose

Kairos aggregates a user's day — weather, schedule, tasks, notes, tech news and
a stock watchlist — onto one bento-grid dashboard, and lets the user act on it
in natural Thai through an AI command bar. This document specifies the system's
functional and non-functional requirements to a level sufficient for sprint
planning, test design and release sign-off.

### 1.2 Scope

**In scope.** A single-user Flutter application (Android / iOS primary, desktop
incidental) that reads from five third-party APIs, holds a local task and note
store, and routes natural-language commands through an LLM to structured
actions.

**Out of scope for v1.** Multi-user accounts, authentication, server-side
components, push notifications, real-time messaging backend, payments,
team/collaboration features, and any offline-first sync protocol.

### 1.3 Definitions

| Term | Meaning |
|---|---|
| **Orchestrator** | The AI layer that converts free-text Thai into a `ParsedIntent` and executes it |
| **Bento grid** | The dashboard's compartmented tile layout (see [design-system.md](design-system.md)) |
| **Role** | A Material `ColorScheme` slot; the only legal way to name a color |
| **Local store** | The in-app source of truth for tasks and notes (currently in-memory) |
| **Mirror** | An optional, best-effort write to an external system (ClickUp) that must never gate the local write |

### 1.4 System context

```
                       ┌──────────────────────────┐
   OpenWeather ───────►│                          │
   ClickUp    ◄───────►│   Kairos (Flutter app)   │──► Local store
   GNews      ───────►│   Riverpod + dio         │    (tasks, notes)
   AlphaVantage ─────►│                          │
   OpenRouter ◄──────►└──────────────────────────┘
```

All five integrations are **direct client-to-vendor** calls. There is no backend
of our own. §5.2 explains why that is currently a security defect.

### 1.5 Current implementation baseline

| Metric | Value |
|---|---|
| Dart source | 54 files, ~8,200 LOC |
| Test files / cases | 6 / 64 (all passing) |
| State management | Riverpod 2.6 (`StateNotifier` + `FutureProvider`) |
| HTTP | dio 5.7, one shared instance, no interceptors enabled |
| Persistence | **None** |
| Routing | Declarative `go_router` 17.5 — one route table, per-tab nested navigators ([user-flow.md](user-flow.md)) |
| Localization | Thai strings inline in widgets; no ARB |
| CI | None |

---

## 2. Overall description

### 2.1 User personas

| Persona | Need | Primary surfaces |
|---|---|---|
| **P1 — The owner** (single Thai-speaking professional; the only real user of v1) | See the day at a glance; capture a task in one sentence without opening a form | Dashboard, AI command bar |
| **P2 — The operator** (same human, configuring the app) | Get five API keys in place and know which features degrade when one is missing | Config, error states |
| **P3 — The maintainer** (next developer) | Change one design token and have it hold across six theme variants | Design system, tests |

P3 is a real persona, not a courtesy: the design system's whole architecture
(roles only, two hex files, six-variant test matrix) exists to serve them.

### 2.2 Operating constraints

| Constraint | Consequence |
|---|---|
| AlphaVantage free tier: **25 requests/day** | Watchlist is 3 symbols = 3 requests per dashboard load → **quota exhausted after ~8 loads/day** |
| GNews free tier: 100 requests/day | Acceptable at 1 request/load |
| OpenRouter free models: rate-limited, no SLA | News summarization fans out **5 concurrent LLM calls per load**; task parsing adds 1 per command |
| No backend | API keys must live on the device (§5.2) |
| Thai as the primary language | Prompts, model output and all UI copy are Thai; the LLM must be capable in Thai |

**The binding constraint is quota, not code.** Without a cache layer the app is
functionally unusable after roughly eight dashboard opens in a day. See FR-8.3.

### 2.3 Assumptions

1. One user, one device, no account sync.
2. Network is usually available; degraded-network handling is required but
   offline-first is not.
3. Every external API may be unconfigured or failing at any moment, and the app
   must remain useful — this is a hard requirement, not a nicety (FR-8.2).

---

## 3. Functional requirements

### Epic 1 — AI Orchestrator

The numbering below preserves the `Feature N.M` scheme already referenced in
source comments (`openrouter_service.dart`, `clickup_service.dart`).

| ID | Requirement | Status |
|---|---|---|
| **FR-1.1** | The AI command bar SHALL accept free-text Thai and show a busy state for the duration of the round trip. | `[IMPL]` |
| **FR-1.2** | The system SHALL parse a command into a `ParsedIntent` (`role`, `action`, `task_name`, `due_date`, `reply_text`) via OpenRouter, resolving relative dates ("พรุ่งนี้") against an injected reference time. | `[IMPL]` |
| **FR-1.3** | The system SHALL synthesize weather + schedule into one advisory Thai sentence, re-running automatically when either input refreshes. | `[PARTIAL]` — see **DEF-1** |
| **FR-1.4** | When `action == create_task`, the system SHALL create the task. | `[PARTIAL]` — no user confirmation; see **DEF-2** |
| **FR-1.5** | The system SHALL surface a parse failure or API failure to the user as a readable Thai message, distinguishable from "no keys configured". | `[PLANNED]` |
| **FR-1.6** | The system SHALL NOT execute a destructive or irreversible action (delete, external write) from a parsed intent without explicit user confirmation. | `[PLANNED]` |

**Acceptance — FR-1.2**
- Given `"พรุ่งนี้บ่ายโมงมีนัดส่งงาน"` at a known `now`, the parsed intent has
  `role=tasks`, `action=create_task`, `task_name` ≈ `"ส่งงาน"`, and `due_date`
  on the following calendar day at 13:00 ±0 minutes.
- Given a model response wrapped in ```` ```json ```` fences, parsing succeeds.
- Given a model response that is not JSON, FR-1.5 applies — the app does not crash.

**DEF-1 (defect).** `dailyAdviceProvider` awaits `tasksProvider` — the **ClickUp**
provider — rather than `localTasksProvider`. Daily advice therefore fails on any
install without ClickUp credentials, even though tasks themselves work locally.
This contradicts the stated design intent in `tasks_provider.dart` ("nothing in
the UI may depend on this succeeding").

**DEF-2 (defect).** `OrchestratorController.submit` writes a task straight from
model output with no confirmation step. A mis-parse silently creates junk data,
and text arriving from any non-user source would execute unreviewed.

### Epic 2 — Weather

| ID | Requirement | Status |
|---|---|---|
| **FR-2.1** | The dashboard SHALL show current condition, temperature and rain probability for the user's location. | `[IMPL]` |
| **FR-2.2** | A dedicated weather screen SHALL present an art-directed, condition-specific illustration with a day selector. | `[IMPL]` |
| **FR-2.3** | Weather art SHALL be self-consistent at fixed contrast and is an explicit, documented exception to the theme-role rule. | `[IMPL]` |
| **FR-2.4** | Weather data SHALL be cached and served stale-while-revalidate on reopen. | `[PLANNED]` |

### Epic 3 — Tasks

| ID | Requirement | Status |
|---|---|---|
| **FR-3.1** | The system SHALL fetch uncompleted ClickUp tasks and filter to "due today or tomorrow". | `[IMPL]` |
| **FR-3.2** | The system SHALL create a task from a natural-language command. | `[IMPL]` |
| **FR-3.3** | The local store SHALL be the source of truth; adding a task SHALL succeed with no API keys, no network and no AI configured. ClickUp is a best-effort mirror whose failure is swallowed. | `[IMPL]` |
| **FR-3.4** | The user SHALL create, edit, complete and delete tasks through a quick-add sheet reachable from every tab. | `[IMPL]` |
| **FR-3.5** | Tasks SHALL survive app restart. | `[PLANNED]` — **DEF-3**, explicit `TODO(persistence)` in source |
| **FR-3.6** | A failed ClickUp mirror SHALL be retried or surfaced, so local and remote do not diverge silently. | `[PLANNED]` |

**DEF-3 (defect, severity: high).** `LocalTasksNotifier` and `NotesNotifier` are
in-memory. **All user-created tasks and notes are destroyed on app restart.**
This is the single largest gap between the app's apparent and actual capability.

### Epic 4 — Calendar & Notes

| ID | Requirement | Status |
|---|---|---|
| **FR-4.1** | The calendar SHALL render a chronological day timeline from the local task store, with undated tasks sorted last. | `[IMPL]` |
| **FR-4.2** | The user SHALL create, edit, pin, tint and delete notes. | `[IMPL]` |
| **FR-4.3** | A note SHALL keep its color identity across a light/dark theme flip. | `[IMPL]` — guaranteed by fixed pigments + `test/theme_test.dart` |
| **FR-4.4** | Notes SHALL survive app restart. | `[PLANNED]` — **DEF-3** |
| **FR-4.5** | The user SHALL search notes by title and body. | `[PLANNED]` |

### Epic 5 — News

| ID | Requirement | Status |
|---|---|---|
| **FR-5.1** | The system SHALL fetch technology headlines (GNews, `category=technology`, max 5). | `[IMPL]` |
| **FR-5.2** | Each article SHALL be compressed to a 3-line Thai bullet summary; on AI failure the raw description SHALL be shown instead of failing the card. | `[IMPL]` |
| **FR-5.3** | Summaries SHALL be cached per article so a refresh does not re-bill 5 LLM calls. | `[PLANNED]` — **DEF-4** |

**DEF-4 (defect, severity: medium).** `newsProvider` fans out one LLM call per
article on every load, concurrently. On a free-tier model this is the most
likely source of rate-limit errors, and the latency is paid on every visit.

### Epic 6 — Market

| ID | Requirement | Status |
|---|---|---|
| **FR-6.1** | The dashboard SHALL show a fixed watchlist (`AAPL`, `NVDA`, `MSFT`) with a daily sparkline and change indicator. | `[IMPL]` |
| **FR-6.2** | A rising quote SHALL use the `success` semantic, never the brand color. | `[IMPL]` |
| **FR-6.3** | The watchlist SHALL be user-editable. | `[PLANNED]` |
| **FR-6.4** | Quotes SHALL be cached for ≥1 hour to stay inside the 25 req/day quota. | `[PLANNED]` — **DEF-5**, see §2.2 |

### Epic 7 — Shell, Chat & Design System

| ID | Requirement | Status |
|---|---|---|
| **FR-7.1** | A single floating bottom nav SHALL host four primary tabs plus a center quick-add, preserving each tab's scroll and provider state. | `[IMPL]` — now via `StatefulShellRoute.indexedStack`; each tab also keeps its own stack |
| **FR-7.2** | Every color SHALL resolve from `Theme.of(context)`; only `material_scheme.dart` and `kairos_palette.dart` may contain hex. | `[IMPL]` |
| **FR-7.3** | The app SHALL ship light and dark themes at three contrast levels, following the OS setting live. | `[IMPL]` |
| **FR-7.4** | Theme mode and contrast SHALL persist across restart. | `[PLANNED]` |
| **FR-7.5** | The Chat tab SHALL provide real conversations. | **Withdrawn** — DEF-6 resolved by removing the tab; Notes took the slot |

**DEF-6 — closed 2026-08-11.** Chat was five hard-coded contacts occupying 25%
of primary navigation while delivering zero function. Resolved by the second
option: `lib/features/chat/` is deleted and Notes — real, finished, previously
homeless in the nav — took the slot. "Chat for real" remains parked in
[sprint-plan.md](sprint-plan.md) §6 as the backend epic it always was.

### Epic 8 — Platform & Configuration

| ID | Requirement | Status |
|---|---|---|
| **FR-8.1** | Missing configuration SHALL fail loudly at the point of use with a named key, not as a null deep in a widget. | `[IMPL]` — `Env._require` |
| **FR-8.2** | Every feature backed by an external API SHALL render a distinct, readable state for *loading*, *error*, *empty* and *not configured*. | `[PARTIAL]` — `AsyncCardBody` covers loading/error; "not configured" is indistinguishable from "broken" |
| **FR-8.3** | Responses SHALL be cached with a per-endpoint TTL sufficient to stay inside every vendor's free-tier quota. | `[PLANNED]` — **DEF-5** |
| **FR-8.4** | API credentials SHALL NOT be extractable from a distributed build. | `[PLANNED]` — **DEF-7** |
| **FR-8.5** | A `.env.example` and a setup section in the README SHALL let a fresh checkout reach a running app. | `[PLANNED]` |
| **FR-8.6** | Navigation SHALL be declarative and support deep links. | `[PARTIAL]` — route table is declarative and every screen has an address ([user-flow.md](user-flow.md)); OS-level link registration (Android `intent-filter`, iOS associated domains) outstanding |
| **FR-8.7** | User-facing strings SHALL be externalized for localization. | `[PLANNED]` |

**DEF-7 (security defect, severity: high).** `.env` is declared as a **Flutter
asset** in `pubspec.yaml`. Assets are bundled into the shipped binary, so all
five API keys are trivially extractable from any distributed APK/IPA by
unzipping it. `.gitignore` protects the repo but not the artifact. For a
personal side-loaded build this is tolerable; for **any** distribution it is not,
and the only real fix is a thin proxy that holds the keys server-side —
which reopens the "no backend" decision in §1.2.

---

## 4. External interface requirements

| Interface | Endpoint | Auth | Failure mode required |
|---|---|---|---|
| OpenWeather | current weather | `OPENWEATHER_API_KEY` | Card shows error state; rest of dashboard unaffected |
| ClickUp v2 | `GET/POST /list/{id}/task` | `CLICKUP_API_TOKEN` header | **Silently swallowed** — local write already succeeded (FR-3.3) |
| GNews | `/v4/top-headlines` | `GNEWS_API_KEY` | News screen shows error state |
| AlphaVantage | `TIME_SERIES_DAILY` | `ALPHAVANTAGE_API_KEY` | Market card shows error state |
| OpenRouter | `/v1/chat/completions` | `OPENROUTER_API_KEY` bearer | News falls back to raw description (FR-5.2); command bar must surface the error (FR-1.5) |

Timeouts are set once on the shared `dio` instance: 10s connect, 15s receive.

---

## 5. Non-functional requirements

### 5.1 Performance

| ID | Requirement | Status |
|---|---|---|
| **NFR-P1** | Dashboard first meaningful paint ≤ 1.5s on a mid-range device with warm cache. | `[PLANNED]` — unmeasured |
| **NFR-P2** | Scrolling holds 60fps; `BackdropFilter` is opt-in only where something moves behind the surface. | `[IMPL]` — enforced by `GlassContainer(frosted:)` being opt-in |
| **NFR-P3** | No screen SHALL issue more than one network round trip per external service per load. | `[PARTIAL]` — violated by market (3) and news (1 + 5) |

### 5.2 Security

| ID | Requirement | Status |
|---|---|---|
| **NFR-S1** | Secrets SHALL NOT be committed. | `[IMPL]` — `.env` in `.gitignore` |
| **NFR-S2** | Secrets SHALL NOT be recoverable from a shipped artifact. | `[PLANNED]` — **DEF-7** |
| **NFR-S3** | Model output SHALL be treated as untrusted data: it may populate a form for review, but SHALL NOT trigger an external write unreviewed. | `[PLANNED]` — **DEF-2** |

### 5.3 Accessibility

| ID | Requirement | Status |
|---|---|---|
| **NFR-A1** | Body text ≥ 4.5:1, large text ≥ 3:1, across all six theme variants. | `[IMPL]` for hero and note surfaces — machine-checked in `test/theme_test.dart` |
| **NFR-A2** | Interactive targets ≥ 48dp. | `[IMPL]` — `DesignTokens.minTouchTarget`, applied via component themes |
| **NFR-A3** | Interactive controls carry Thai `Semantics` labels. | `[PARTIAL]` — unaudited |
| **NFR-A4** | `MediaQuery.disableAnimations` is honoured by every entrance, press **and route** animation. | `[IMPL]` — `AppMotion.reduced`, applied once in `KairosPage`; covered by `navigation_test.dart` |

### 5.4 Maintainability

| ID | Requirement | Status |
|---|---|---|
| **NFR-M1** | `flutter analyze` clean, zero warnings. | `[IMPL]` |
| **NFR-M2** | Every primary screen renders under all six theme variants without exception. | `[IMPL]` — 24-case matrix in `test/theme_test.dart` |
| **NFR-M3** | Services and providers have unit tests with mocked transports. | `[PLANNED]` — **zero coverage today** |
| **NFR-M4** | Analyze + test run on every push. | `[PLANNED]` — no CI |

---

## 6. Defect register (consolidated)

| ID | Severity | Summary | Requirement |
|---|---|---|---|
| **DEF-3** | High | Tasks and notes are in-memory; all user data lost on restart | FR-3.5, FR-4.4 |
| **DEF-7** | High | `.env` bundled as an asset → API keys extractable from the binary | FR-8.4, NFR-S2 |
| **DEF-5** | High | No caching; AlphaVantage quota exhausts after ~8 dashboard loads/day | FR-6.4, FR-8.3 |
| **DEF-1** | Medium | Daily advice depends on ClickUp, so it breaks without ClickUp keys | FR-1.3 |
| **DEF-2** | Medium | Orchestrator creates tasks from model output with no confirmation | FR-1.4, NFR-S3 |
| **DEF-4** | Medium | News fans out 5 concurrent LLM calls per load, uncached | FR-5.3 |
| ~~DEF-6~~ | ~~Medium~~ | ~~Chat tab is entirely mock data in 25% of primary navigation~~ — **closed 2026-08-11**, tab removed | FR-7.5 |

---

## 7. Traceability

Each `[PLANNED]` and `[PARTIAL]` requirement above maps to exactly one backlog
item in [sprint-plan.md](sprint-plan.md); each backlog item cites its FR/DEF id.
An item with no requirement id is not in the sprint.

## 8. Verification

```bash
flutter analyze     # NFR-M1
flutter test        # NFR-M2, NFR-A1, and the Japandi invariants
```

Sign-off for a release requires: analyze clean, all tests green, and every
requirement claimed for that release moved to `[IMPL]` **with its acceptance
criteria demonstrated on a device** — not merely compiling.
