# Design System Audit — kairos_i

**Date:** 2026-07-21
**Method:** Expert/heuristic review (no end users involved). Sources compared: the seven mockups in `template/`, the design system spec in `.agent/design-system/markdown/design-v1.md`, and the Flutter implementation in `lib/`.
**Scope note:** This is a *design-system conformance* audit, not user research. See "What this audit cannot tell you" at the end.

---

## 1. Headline finding: there is no single design system

The project has **four competing sources of visual truth**, none of which defers to the others.

| # | Source | Where it lives | Character |
|---|--------|----------------|-----------|
| 1 | **Celestial Glass** | `.agent/design-system/markdown/design-v1.md` | Hanken Grotesk, glassmorphism, light `#f9f9f9` surface, red `#b3272d` primary |
| 2 | **Stardust** | `template/theme.html` | Same token *names* as #1 but **dark** (`#121414` surface, `#ffb3af` primary) — the dark counterpart, never reconciled |
| 3 | **Screen mockups** | The other six `template/*.html` | **Inter**, not Hanken Grotesk. Five mutually unrelated palettes (see §2) |
| 4 | **Runtime themes** | `lib/core/theme/theme_provider.dart` | Defaults to `AppThemeMode.image` — a *dark* `ColorScheme` extracted at runtime from an Unsplash photo |

The practical consequence: **the app's default appearance is decided by a network image fetch**, not by any of the three design documents. `AppTheme.light` — the only theme that implements the written design system — is reachable only if the user explicitly picks light mode.

`design_tokens.dart:3` claims to be "transcribed 1:1 from design-v1.md". It is not:

| Token | design-v1.md | design_tokens.dart | Status |
|---|---|---|---|
| Font family | Hanken Grotesk | `IBM Plex Sans Thai` (`:90`) | **Conflict** |
| `primary` | `#b3272d` | `#FF5F5E` (`:20`) | Uses the *container* value as primary |
| `secondary` | `#5644d0` | `#6C5CE7` (`:25`) | Conflict |
| `tertiary` | `#934a27` | `#FFA177` (`:30`) | Conflict |
| `surface` | `#f9f9f9` | `#F9F9F9` (`:12`) | ✅ Match |

The file then adds two further palettes the spec never mentions — "Studio" (`:41`) and "Aurora" (`:51`) — plus a "Liquid Glass" system (`:117`) and an "ambient mesh" (`:128`). Those additions are *good work*; the problem is that they were layered on rather than folded in, so `design-v1.md` no longer describes the app.

> **Where "Studio" came from:** `ink #2A2A2A`, `pageBackdrop #E8ECF1`, `secondaryCard #EEF2FF` are lifted straight from `template/homepage_and_calender.html` (its three most-used hexes). So the token file is already a silent merge of spec + one mockup.

---

## 2. Template analysis — which mockups are usable

Per the brief, several templates hold more than one screen. Coverage against the shipped feature set:

| Template | Screens it contains | Maps to | Palette / font | Verdict |
|---|---|---|---|---|
| `theme.html` | Nav, hero, 3-card grid, CTA, footer | *(none — it's a marketing page)* | Hanken Grotesk, Celestial dark | **Use for tokens only.** It is the sole template carrying the design system, but its layouts are desktop-marketing and irrelevant to the app |
| `homepage_and_calender.html` | Dashboard, Timeline/Calendar | `dashboard_screen.dart`, `calendar_screen.dart` | `#2A2A2A` charcoal on off-white, Inter | **Highest value.** Already the de-facto source for the Studio tokens; both target screens exist |
| `overview_chat_and_ai_chat.html` | Contact list, Active chat | `chat_screen.dart` | Pastel gradients, Inter | **Use the chat screen.** Contact-list screen has no counterpart in `lib/` |
| `news.html` | Article view, Payment hub | `news_screen.dart` | Near-black + periwinkle `#d6d6fb`, Inter | **Use the article view only.** The payment hub is out of scope — no payment feature exists |
| `weather.html` | 3 screens (main, sunny, sunrise) | `weather_glass_screen.dart` + `widgets/` | Warm stone neutrals, Inter | Rich, and the weather feature is the most built-out in code (8 widget files). But its palette is unrelated to every other screen |
| `formtask.html` | Add-habit modal | `notes/note_form_screen.dart` | `#1A1A1A` primary, Inter | Useful as a *form pattern* reference; "habits" is not a feature here |
| `card-or-section.html` | 3 screens (practices, reflection, statistics) | *(none)* | Sage/cream earthy, Inter | **Lowest value.** No matching features; palette is a fifth unrelated direction |

**Recommendation:** treat `homepage_and_calender.html` + `overview_chat_and_ai_chat.html` + `news.html` (article) as the layout canon, and `theme.html` as the token canon. Explicitly retire `card-or-section.html` and the payment-hub screen from consideration — keeping unusable references in `template/` is what produced the palette sprawl in the first place.

---

## 3. Implementation conformance

Measured across the 50 Dart files in `lib/`.

### 3.1 Typography — 99 raw `TextStyle(` vs 8 theme reads

```
Files constructing raw TextStyle:   18   (99 occurrences)
Files reading Theme...textTheme:     5   (8 occurrences)
```

`app_theme.dart:97-143` defines a complete `TextTheme` from the token scale. Almost nothing consumes it. Worst offenders: `dashboard_screen.dart` (24), `chat_screen.dart` (13), `weather_glass_screen.dart` (11), `news_screen.dart` (10), `calendar_screen.dart` (10).

This is the single highest-leverage fix: the type scale exists and is correct; it is simply bypassed.

### 3.2 The glass primitive is bypassed on the screens that most need it

`GlassContainer` (`glass_container.dart`) is a careful 4-layer implementation of the spec's §"Elevation & Depth". It is used in **4 files** — and three of those are core/infra (`bento_card.dart`, `ai_command_bar.dart`, `splash_screen.dart`).

Meanwhile three screens hand-roll their own `BackdropFilter`:

- `chat_screen.dart:445` — `blur(10)` on an avatar
- `chat_screen.dart:497` — `blur(10)` on message bubbles
- `bottom_nav_bar.dart` — own blur
- `weather_glass_screen.dart` — own blur

All use **sigma 10**, against the token's `glassBlurSigma = 24` (`design_tokens.dart:122`) and the spec's mandated `blur(20px)`. So glass surfaces in the app frost at two different intensities depending on which screen you're on, and none matches the spec.

### 3.3 Radius — 16 distinct values for a 6-step scale

```
14px ×8   28px ×4   20px ×4   12px ×4   999 ×2   2px ×2
18px ×2   16px ×2    7 6 40 4 26 24 22 10  ×1 each
```

`DesignTokens.radius*` is referenced **7 times** total. The token scale (4/8/12/16/24/full) is essentially unused; `14` and `28` — neither of which is in the scale — are the two most common values.

### 3.4 Color — 236 hardcoded literals outside the token file

`dashboard_screen.dart` alone: 51 `Colors.*` + 11 `Color(0x...)`. Representative:

```dart
// dashboard_screen.dart:415
BoxShadow(color: Color(0x14000000), blurRadius: 8),   // vs AppTheme.softCard's 16
```

Note the pattern at `dashboard_screen.dart:121-126` and `:398-415` — hand-written `isDark ? ... : ...` ternaries that reimplement `AppTheme.softCard()` (`app_theme.dart:31`), which already handles exactly this. Two copies, already diverged (blur 8 vs 16).

*(Exempt: `weather_condition.dart` (20) and `note_model.dart` (12) are semantic data palettes — legitimately literal, though they should still be named in the token file.)*

### 3.5 Accessibility — zero coverage

```
Semantics( / semanticLabel / tooltip:   0 occurrences
textScaler handling                     0 occurrences
MediaQuery / LayoutBuilder              5 occurrences (50 files)
```

No screen reader labelling anywhere in the app. This is disproportionately serious for *this* design language: glassmorphism means low-contrast text on a live animated backdrop (`mesh_background.dart`), so the visual channel is already compromised — and there is no non-visual fallback. Roughly 40 icons render at ≤24px, several as the sole affordance of a tap target.

The spec compounds this: design-v1.md §Colors prescribes "70% opacity white for secondary labels". Over the mesh gradient that will not reach WCAG AA (4.5:1) at body sizes.

### 3.6 Motion — the one system that works

`core/motion/motion.dart` is exemplary: a closed vocabulary of three durations and three curves, `FadeSlideIn` for staggered entrances, `PressableScale` for tactile feedback, and — notably — `AppMotion.reduced()` honouring `disableAnimations`. It is the only part of the design system that is both well-specified *and* respected by callers. **Use it as the template for how the color/type layers should be rebuilt.**

---

## 4. Prioritized recommendations

Ordered by (impact ÷ effort).

**P0 — Resolve the source of truth.** Nothing below is durable until this is done.
1. Decide the default: is this a light glass app (design-v1.md) or a dark image-themed app (`theme_provider.dart` default)? Currently the code says one thing and every document says another.
2. Rewrite `design-v1.md` to describe what actually ships — Aurora + Studio + Liquid Glass + mesh — or amend `design_tokens.dart` to match the spec. Do not leave the `:3` "1:1 transcription" comment standing; it is false and will mislead the next contributor.
3. Settle the font. `IBM Plex Sans Thai` vs Hanken Grotesk is likely a deliberate Thai-script decision — if so, record *why* in the spec.

**P1 — Reconnect the code to the tokens.** Mechanical, high volume, low risk.
4. Replace the 99 raw `TextStyle(` with `Theme.of(context).textTheme.*`. Start with `dashboard_screen.dart`.
5. Route all four hand-rolled `BackdropFilter` sites through `GlassContainer`, or at minimum through `DesignTokens.glassBlurSigma`.
6. Collapse the 16 radius values onto the 6-step scale. `14 → radiusMd(12)` or `radiusLg(16)`; `28 → radiusXl(24)`.
7. Delete the `softCard` reimplementation in `dashboard_screen.dart:121` and `:398`; call `AppTheme.softCard()`.

**P2 — Accessibility floor.**
8. Add `Semantics`/`tooltip` to every icon-only tap target.
9. Contrast-check the glass surfaces against the mesh at its brightest and darkest drift positions. The spec's 70%-white secondary text is the likely failure.
10. Enforce 44×44 minimum hit targets.

**P3 — Prune the references.**
11. Remove `card-or-section.html` and the payment-hub screen from `template/`, or move unused mockups to `template/archive/`. Five unused palettes in the reference folder is how a sixth ends up in the code.

---

## 5. What this audit cannot tell you

The command that produced this was a *user-research* skill, but **no user research was performed** — there are no participants, sessions, or data in this repo, and none can be synthesized from source code. Everything above is expert inspection against a written spec.

Questions that remain genuinely open, and that only real users can answer:

- **Is glassmorphism the right call at all?** It costs contrast and GPU. Whether users perceive it as "premium" (the spec's stated goal at design-v1.md §Brand) or as "hard to read" is an empirical question. A 5-participant usability test on the dashboard would settle it in a week.
- **Does the runtime image-theming feature matter to anyone?** `theme_provider.dart` carries four presets plus custom-URL extraction — meaningful complexity, and it's the reason the default theme contradicts the design system. Worth confirming it earns its place before you spend P0 effort reconciling around it.
- **Which of the four tab destinations do people actually use?** The shell hard-codes Dashboard/Calendar/News/Chat (`main_shell.dart:37`), while Weather — the most heavily built feature in the codebase, 8 widget files — is demoted to a card tap. That ranking looks inverted relative to build effort; it may or may not be inverted relative to use.

If you want the research arm run properly, the highest-value first study is a **5-participant moderated usability test of the dashboard**, testing legibility of glass surfaces and discoverability of Weather. That is one week of work and would de-risk the P0 decision above.
