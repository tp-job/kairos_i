# Kairos — Sprint Plan

**Version:** 1.0
**Date:** 2026-08-05
**Derived from:** [srs.md](srs.md) — every item below cites an FR or DEF id.
**Horizon:** 4 sprints (8 weeks) to a defensible v1.0, plus a parked backlog.

---

## 0. Capacity assumptions — change these first

| Assumption | Value | If this is wrong |
|---|---|---|
| Team | 1 developer | Halve/double sprint count proportionally; the *ordering* does not change |
| Sprint length | 2 weeks | — |
| Velocity | ~20 points/sprint (unvalidated — Sprint 1 sets the real baseline) | Treat Sprint 1 as calibration; re-plan 2–4 after it closes |
| Points | 1 ≈ half a day · 3 ≈ 1–2 days · 5 ≈ 3–4 days · 8 ≈ most of a sprint | — |

Sprint 1 is deliberately loaded slightly under capacity. A first sprint that
finishes early gives you a real velocity number; one that finishes late gives you
nothing but a demoralised burndown.

---

## 1. The ordering argument

Read this before the backlog — it is the actual recommendation, and the sprint
contents follow from it.

**Kairos is a well-built shell around data that does not survive and APIs that
run out.** The design system is genuinely finished: roles-only architecture, six
theme variants, a 24-case render matrix, machine-checked contrast. The feature
surface is broad — weather, tasks, notes, calendar, news, market, AI — and most
of it works.

But three facts dominate everything else:

1. **Every task and note the user creates is destroyed on restart** (DEF-3).
2. **AlphaVantage's free tier dies after ~8 dashboard opens per day** (DEF-5).
   Not degrades — dies.
3. **The shipped binary contains all five API keys** (DEF-7).

Until (1) and (2) are fixed, nothing else is worth building, because there is no
product to build it on. New features on top of a store that forgets are new ways
to lose the user's work. That is why Sprint 1 has no user-visible feature in it
and I would not trade any of it for one.

(3) is different in kind: it is a **decision**, not a task. Fixing it properly
means standing up a proxy, which reverses the "no backend" call in SRS §1.2.
Sprint 4 forces that decision rather than letting it drift — but if this app is
ever going into a store or onto another person's phone, it is the first thing to
resolve, not the last. **Escalate it now if distribution is on the table.**

The one product call I would make outside of engineering: **cut the Chat tab**
(DEF-6). It is five fake contacts occupying a quarter of primary navigation, and
building it for real needs a messaging backend that v1 has explicitly scoped out.
Shipping fake conversations teaches the user the app lies. Reclaim the slot for
Notes, which is real, finished, and currently has no home in the nav.

---

## 2. Sprint 1 — "The data survives" (18 pts)

**Goal:** A task created today is still there tomorrow, and the dashboard works
on the tenth open of the day.

| # | Item | Pts | Traces |
|---|---|---|---|
| 1.1 | Persist the local task store. Introduce a `TaskRepository` behind `LocalTasksNotifier`; back it with `sqflite` (tasks have queryable date semantics — `shared_preferences` would force full-list rewrites and block FR-4.5 search later). Migrate the seed data path so a first run still shows a populated timeline. | 5 | FR-3.5, DEF-3 |
| 1.2 | Persist notes through the same repository seam. | 3 | FR-4.4, DEF-3 |
| 1.3 | Persist theme mode + contrast. `shared_preferences` is correct here — two scalars, read once at boot. | 2 | FR-7.4 |
| 1.4 | **Response cache layer.** A dio interceptor with per-endpoint TTL: market 6h, weather 30m, news 2h. Serve stale-while-revalidate so a cold open paints instantly. | 5 | FR-8.3, FR-2.4, FR-6.4, DEF-5, NFR-P3 |
| 1.5 | Unit tests for the repository (write → restart → read) and the cache interceptor (TTL hit, TTL miss, stale serve). | 3 | NFR-M3 |

**Definition of Done**
- Kill and relaunch the app: every task and note created in the session is present, in order, with pin/tint/done state intact.
- Open the dashboard 20 times in one day with a real AlphaVantage key; the market card renders every time and issues ≤4 upstream requests total.
- `flutter analyze` clean; `flutter test` green.

**Risk.** Schema churn — `TaskModel` is still moving (the source TODO says as
much). Mitigation: version the schema table from commit one and write the
migration path before the second field change, not after.

---

## 3. Sprint 2 — "The AI is trustworthy" (20 pts)

**Goal:** The command bar never silently does the wrong thing, and a missing API
key reads as "not configured", not as "broken".

| # | Item | Pts | Traces |
|---|---|---|---|
| 2.1 | **Confirm-before-write.** A parsed `create_task` intent populates the quick-add sheet pre-filled; the user commits. Model output becomes a *proposal*, never a write. | 5 | FR-1.4, FR-1.6, DEF-2, NFR-S3 |
| 2.2 | Fix `dailyAdviceProvider` to read `localTasksProvider`, not the ClickUp `tasksProvider`. Advice then works with zero external task config, as `tasks_provider.dart` always claimed. | 2 | FR-1.3, DEF-1 |
| 2.3 | **Distinguish "not configured" from "failed."** Give `Env` a non-throwing `has(key)`; add a fourth state to `AsyncCardBody` with Thai copy that names the missing key and points at setup. | 5 | FR-8.2, FR-1.5 |
| 2.4 | Cache news summaries by article URL; drop the per-load 5-call fan-out to a per-article once-ever call. | 3 | FR-5.3, DEF-4 |
| 2.5 | Orchestrator error surface: JSON parse failure, rate limit and network failure each get a distinct, readable Thai message. | 3 | FR-1.5 |
| 2.6 | Unit tests: `parseIntent` against recorded fixtures — fenced JSON, malformed JSON, relative Thai dates ("พรุ่งนี้", "อาทิตย์หน้า") resolving against a frozen clock. | 2 | NFR-M3, FR-1.2 |

**Definition of Done**
- Fresh checkout, empty `.env`: app launches, every card explains which key it needs, nothing crashes, tasks/notes/calendar fully usable.
- A deliberately malformed model response produces a Thai error, no task, no crash.
- No task is ever created without a user tap.

**Risk.** 2.1 changes the AI bar from magic to a two-step flow, which can feel
slower. It is the right trade — an unreviewed write from a free-tier 8B model is
a data-integrity bug waiting to happen — but pre-fill and focus the sheet so the
commit is one tap, or the feature will feel worse rather than safer.

---

## 4. Sprint 3 — "The navigation is honest" (19 pts)

**Goal:** Every tab does something real; the app is navigable declaratively.

| # | Item | Pts | Traces |
|---|---|---|---|
| ~~3.1~~ | ~~**Remove the Chat tab**; promote Notes into the freed nav slot.~~ **Done 2026-08-11** | 3 | FR-7.5, DEF-6 |
| ~~3.2~~ | ~~Adopt `go_router`~~ **Done 2026-08-11** — route table, per-tab stacks, `AppMotion`-driven transitions ([user-flow.md](user-flow.md)). *OS-level deep-link registration remains open;* re-point it at a follow-up item rather than treating FR-8.6 as closed. | 5 | FR-8.6 |
| 3.3 | Note search over title + body, incremental, with an empty-result state. | 3 | FR-4.5 |
| 3.4 | User-editable watchlist, persisted, capped at 3 symbols with the quota reason stated in the UI copy. | 5 | FR-6.3 |
| 3.5 | ClickUp mirror reconciliation: queue failed mirrors, retry on next foreground, show a quiet "not synced" affordance. | 3 | FR-3.6 |

**Definition of Done**
- Four tabs, four real features. No hard-coded content in any primary screen.
- A deep link to a specific note opens it from cold start.
- Removing ClickUp keys mid-session does not lose a task or produce a false sync indicator.

**Risk.** 3.1 is a product decision with an owner outside engineering. Get it
signed off *before* the sprint starts — a half-removed tab is worse than either
outcome. If the answer is "keep chat", it becomes an epic of its own and pushes
this sprint's remaining scope right by a full sprint; it does not fit inside one.

---

## 5. Sprint 4 — "It can ship" (20 pts)

**Goal:** Release hardening, and a decided answer on key custody.

| # | Item | Pts | Traces |
|---|---|---|---|
| 4.1 | **Decision spike: API key custody.** Two options costed and one recommended — (a) accept device-side keys and restrict to personal side-load, documenting the exposure; (b) a minimal proxy (Cloudflare Worker / Supabase Edge) holding all five keys, reversing SRS §1.2. Output is an ADR, not code. | 3 | FR-8.4, DEF-7, NFR-S2 |
| 4.2 | Implement the ADR's choice. Estimate assumes (b) for one service as a pilot; re-estimate if the ADR lands elsewhere. | 8 | FR-8.4 |
| 4.3 | CI: GitHub Actions running `flutter analyze` + `flutter test` on every push, required for merge. | 2 | NFR-M4 |
| 4.4 | Accessibility audit: Thai `Semantics` on every interactive control; verify 48dp targets and contrast on a real device with TalkBack. | 3 | NFR-A2, NFR-A3 |
| 4.5 | `.env.example`, and a README that replaces the Flutter default with real setup steps and a per-key "what breaks without it" table. | 2 | FR-8.5 |
| 4.6 | Performance pass: measure dashboard FMP on a mid-range device, fix what misses 1.5s. | 2 | NFR-P1 |

**Definition of Done**
- A new developer clones, follows the README, and reaches a running app in under 15 minutes.
- CI is green and required.
- The key-custody question has a written, dated answer — whichever way it went.

---

## 6. Parked backlog (not scheduled)

| Item | Traces | Why parked |
|---|---|---|
| Localization / ARB extraction | FR-8.7 | Single-language product with one user. Real work, no current payoff. Do it before a second language, never for its own sake. |
| Golden tests for the six theme variants | NFR-M2 | The render matrix already catches the failure class that matters. Goldens add churn on every deliberate design change. |
| Offline-first sync | §1.2 | Out of v1 scope; Sprint 1's cache covers the realistic degraded-network case. |
| Push notifications | §1.2 | Needs the backend from 4.1(b). Revisit only if that ADR chooses a proxy. |
| Chat, for real | DEF-6 | Only if 3.1 is overruled. Multi-sprint epic — backend, auth, realtime, moderation. Not a tab; a product. |
| Champagne-gold accent role | design-system | Open design question from the v5 redesign. |

---

## 7. Cross-sprint risks

| Risk | Impact | Mitigation |
|---|---|---|
| **Free-tier vendors change limits without notice** | Cache TTLs stop being sufficient; a card breaks in production with no deploy | Sprint 1 makes TTL configurable per endpoint, not hard-coded at the call site |
| **The 8B free model is deprecated or rate-limited harder** | Command bar and news summaries both die | 2.3/2.5 make degradation legible; model id is already a single constant to swap |
| **Velocity is a guess** | Sprints 2–4 are fiction until Sprint 1 closes | Re-plan after Sprint 1 with a measured number. Do not defend the original plan against evidence |
| **Schema churn during persistence** | Migration debt in the first weeks | Version the schema from day one (Sprint 1 risk note) |
| **3.1 lacks a product owner** | Sprint 3 stalls on an unmade decision | Force the call before Sprint 3 planning |

---

## 8. Release definition — v1.0

v1.0 ships when, and only when:

- Every **High** severity defect (DEF-3, DEF-5, DEF-7) is closed or has a
  written, accepted risk decision.
- Every primary screen renders real data or an honest, named empty state.
- `flutter analyze` clean and `flutter test` green **in CI**, not just locally.
- A cold install with an empty `.env` is usable for tasks, notes and calendar.
