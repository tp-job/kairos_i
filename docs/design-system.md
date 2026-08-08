# Kairos Design System (v5 — Soft Minimal Japandi)

**Status:** implemented.
**Date:** 2026-08-05
**Source of truth:** `.agent/docs/material-theme-main.json` — Material Theme Builder export, seed `#8F9A98` (sage).
**Supersedes:** v4 ("bento notes", black ⇄ cream). The *architecture* of v4 is unchanged and was not touched: roles only, two hex files, six schemes. What changed is the pigment, the corner radius, the type and the press physics.

---

## 0. The identity — and where we departed from the export

**Modern Japanese Eco-Luxury / Soft Minimal Japandi.** Warm cream page, sage
primary, oat mid-tone, warm-clay accent, muted-charcoal ink. Quiet luxury means
*lightness and detail*, not gold: there is no metallic in the system, and the
accent earns its place by being the only warm thing on a cool page.

Two corrections were made to the raw Theme Builder export, both recorded in
`material_scheme.dart`:

| Export says | We ship | Why |
|---|---|---|
| Neutrals are near-grey (`#FBF9F8` page, `#BCAAA2` neutral-variant) | Warm cream ramp landing on `#FDFBF7` at tone 98, greige outlines | The export's page reads as hospital white at full-screen size. Japandi is warm paper. |
| `tertiary` is `#5E5F5C` — a grey | Warm clay (`#885B50`), whose 80/90 tones are the brief's muted blush | A grey tertiary leaves the palette with sage-on-grey-on-grey and no accent at all. |

Taking the export literally would have produced a technically-correct, visually
dead app. If the seed is ever re-exported, re-apply both corrections or the
palette regresses.

## 1. One line

**Every color on screen is a Material role resolved from `Theme.of(context)`. There are exactly two files that may contain a hex value, and no widget is one of them.**

## 2. Where color lives

| File | Contains | Edit when |
|---|---|---|
| `lib/core/theme/material_scheme.dart` | The six `ColorScheme`s (light/dark × standard/medium/high contrast) and the five tonal palettes | Re-export from Material Theme Builder, then re-apply the two §0 corrections |
| `lib/core/theme/kairos_palette.dart` | `KairosPalette`, a `ThemeExtension` for what Material has no role for: the hero surface, success (up/online), the six note tints, the one shadow tone, the frosted-glass triplet | A genuinely new semantic appears |
| `lib/core/theme/design_tokens.dart` | Shape, spacing, touch targets, type family — **no colors** | A new spacing/radius step is needed |
| `lib/core/theme/app_theme.dart` | Scheme → `ThemeData`, including every component theme, plus the `context.colors / .text / .palette` extension | A component needs a default |
| `lib/core/theme/theme_provider.dart` | The two user-facing knobs: `ThemeMode` and `AppContrast` | — |

A static `Color` constant cannot know whether the app is currently light, dark, or high contrast. That is why v3's `DesignTokens.cardWhite`, `textStrong`, `hairline` and friends are gone rather than re-valued: every one of them was a latent dark-mode bug.

## 3. Rules

1. **Role, not hex.** `context.colors.onSurfaceVariant`, never `Colors.white70`.
2. **Always pair a role with its `on` role.** `primary`/`onPrimary`, `primaryContainer`/`onPrimaryContainer`, `heroGradient`/`onHero`. This is what guarantees contrast across all six variants without hand-checking each one.
3. **Never `Colors.white` on a brand fill.** In the dark scheme `primary` is a *light* sage; white content on it is unreadable. Use `palette.onHero`.
4. **Surfaces step by container role**, not by shadow: `surface` → `surfaceContainerLow` → `surfaceContainerHigh` → `surfaceContainerLowest` (raised cards). One shadow tone (`palette.shadow`) exists for lift, not for hierarchy.
5. **Don't restate what a component theme already says.** Buttons, inputs, sheets, dialogs, snackbars and chips are themed centrally; a widget passing `fillColor`/`border`/`shape` again is drift waiting to happen.
6. **48px minimum touch target** (`DesignTokens.minTouchTarget`). Interactive controls carry `Semantics` with a Thai label.
7. **Tonal palettes are for families, not substitutes.** `MaterialTones` exists so the six note tints can be related; reaching for a tone instead of a role is a review failure.

## 4. Shape, type and motion

**Shape.** The signature corner is `radius2xl = 24` — the top of the brief's
16–24 range, down from v4's 32. Above ~28 a half-width bento tile stops reading
as a box and starts reading as a pill, which kills the grid rhythm. The one
deliberately round shape is the button: `StadiumBorder` on filled / elevated /
outlined, so the fully-round control is what says "tap me" against a page of
soft-cornered boxes.

**Type.** Plus Jakarta Sans (Latin) with IBM Plex Sans Thai registered as
`fontFamilyFallback`. One family cannot serve the brief — the geometric
grotesque it asks for has no Thai coverage, and Thai faces that do look nothing
like it in Latin. The engine falls back per glyph, so `งาน 3 รายการ` renders
Jakarta digits beside Plex Thai loops. Applied across the *whole* ramp,
including `labelLarge` (every button).

Display weights dropped from w800 to w600 and tracking from −1.2 to −0.8: an
airy headline reads as expensive, a heavy one reads as a sale banner. Body
leading is looser than Material's default — airiness is a typographic property
before it is a spacing one.

**Motion.** `PressableScale` runs a real `SpringSimulation`
(`AppMotion.squish`, damping ratio 0.62) seeded with the controller's current
velocity, not a fixed-duration curve. That continuity — tapping again mid-bounce
picks up where the last gesture left off — is the difference between "animated"
and "physical". It honours `MediaQuery.disableAnimations`.

`GlassContainer(frosted: true)` opts into the washi-glass preset
(`palette.glassFill / glassStroke / glassBlur`): a translucent veil that lets the
page tint through. It costs a save layer per frame, so it is opt-in and only
worth it over something that actually moves.

## 5. Theming knobs

`ThemeMode.system` (default) / `light` / `dark`, crossed with `AppContrast.standard` / `medium` / `high`, reachable from the dashboard header avatar. `MaterialApp` receives both themes at once, so the OS setting is followed live.

The v3-era "theme from an Unsplash image" mode is removed. It made the app's palette depend on a network fetch at launch, ignored the OS light/dark setting, and produced schemes nobody reviewed for contrast.

## 6. Deliberate exceptions

`lib/features/weather/models/weather_condition.dart` and `widgets/weather_detail_screen.dart` keep their own art-directed palettes (paper cream for day, ink black for night, per weather condition). This is an editorial illustration surface, self-consistent and fixed-contrast — not theme drift. Everything else in the weather feature, including `weather_glass_screen.dart`, now uses the app palette.

## 7. Conformance check

```bash
flutter analyze
flutter test
```

`test/theme_test.dart` renders the primary screens under all six schemes and fails on any layout or paint exception; a grep for `Color(0x` outside the two color files should return only the weather exceptions in §6.
