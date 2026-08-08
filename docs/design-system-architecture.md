# Solid Light — System Design (v3)

> **⚠️ Superseded (2026-07-25) by [`design-system.md`](design-system.md) (v4).**
> v3's diagnosis holds and is worth reading. Its conclusion does not: the app no
> longer ships a single hand-written light theme. Color now comes from the
> Material Theme Builder export (`.agent/docs/material-theme (2).json`) as six
> schemes — light/dark × three contrast levels — and `DesignTokens` holds no
> colors at all.

**Status:** Phase 0 settled. **Tier C is the product.**
**Date:** 2026-07-21
**Revises:** v1 (dark glass), v2 (light glass, chrome-only). No code written yet — reversals so far have cost nothing.

> ### v3 in one line
> **Ship Tier C as the default and only experience: solid surfaces, real colors, no blur.** Liquid Glass is deferred to an optional enhancement that may never be built.
>
> **Why:** the running app (screenshot, 2026-07-21) is a muddy lavender wash in which no color is the color anyone chose. Two causes, both structural — §0.1. Translucency stacking is what turns specified colors into mud, and the target hardware (vivo Y21s class) was never going to run the glass tier anyway. Removing translucency is simultaneously the color fix, the performance fix, and the contrast fix.
**Supersedes:** the palette/theme portions of `.agent/design-system/markdown/design-v1.md`
**Companion:** [`design-system-audit.md`](design-system-audit.md) — the drift this design exists to resolve
**Stack:** Flutter 3.44.4 stable, Dart ^3.12.2, Riverpod 2.6, Impeller

---

## 0. Phase 0 — decision (settled)

> **kairos_i is a light-theme mobile app with solid surfaces and a colorful accent system. No translucency, no backdrop blur. Every color on screen is a token someone chose.**

### 0.1 Why the app is currently lavender mud

The screenshot is not a styling bug. It is two structural faults, both named in the audit:

**Fault 1 — nobody chose that purple.** The startup chain:

```
theme_provider.dart:58   themeMode defaults to AppThemeMode.image
        ↓
_extractSchemeForPreset(0)  → 'Pitch Guru (Sunset)' Unsplash photo
        ↓
ColorScheme.fromImageProvider(brightness: Brightness.dark)
        ↓
getThemeData()  → surface forced to #12131C
        ↓
main.dart:31    → that scheme becomes the app's theme
        ↓
MeshBackground  → paints its blobs FROM that scheme
```

The app's entire palette is the average of a JPEG fetched over the network at launch. That is why it is "not the color I wanted" — **it isn't a color anyone specified.** Changing `DesignTokens` today would not alter that screenshot at all, because tokens are not what's driving it.

**Fault 2 — translucency stacks into mud.** Layer a translucent white glass tint over a drifting mesh over a tinted surface and every element converges toward the *same* value. Header, cards, nav, and canvas in the screenshot are all within a few percent of one another — the weather card is barely separable from the tile beside it, and "เชื่อมต่อ ClickUp" sits in a box you have to hunt for.

This is the failure mode v2 §4.3 predicted for light-over-light and tried to solve with a 72% frost floor. **Tier C solves it outright by removing the mechanism.** Opaque surfaces render the exact hex you specify.

### 0.2 The decision

| Question | v2 | **v3 — binding** |
|---|---|---|
| Default experience | Tier B (blur, chrome-only glass) | **Tier C — solid, no blur** |
| Liquid Glass | The design | **Deferred.** Optional enhancement, may never ship |
| `BackdropFilter` | Chrome layer only | **Zero. Anywhere.** |
| Mesh background | Faint ambient wash | **Removed** from the default path |
| Runtime image theming | Hue rotation within a locked band | **Off by default.** Cannot drive tokens (§4.4) |
| SPIKE-1 (shader) | Blocking Phase 1 | **Deferred** — nothing depends on it now |
| Perf floor | A54 target / Y21s floor | **Y21s is the target.** A54 gets headroom free |
| Platform focus | — | **Mobile only.** Phone portrait is the design surface |

**What this buys.** Every hard problem in v2 was created by translucency: the frost floor, adaptive tint, the sampling tiers, the shader spike, the ≤20% blur budget, the nesting ban, the readback question. All of them dissolve. What remains is a normal, well-built, colorful light theme — which is what the screenshot needs and what the target hardware can render at 60fps without effort.

**What it costs.** The app will not look like iOS 26. That look was never reachable on a Helio G80 anyway; v2 was already conceding it to Tier C on that device. v3 makes the concession honest and designs *for* it instead of treating it as degradation.

| Question | v1 | **v2 — binding** |
|---|---|---|
| Brightness | Dark only | **Light.** `Brightness.light` is the shipped default |
| Color | Bright accents on near-black | **Colorful accents on off-white**, dual-variant (§4.1) |
| What sits behind glass | A procedural mesh we control | **Real scrolling content** |
| Glass scope | Every elevated surface | **Navigation/chrome layer only** (§3) ← *the big change* |
| Perf floor | Unnamed | **Galaxy A54** = design target · **vivo Y21s** = degradation floor (§5.1) |
| `AppTheme.light` | Deleted | **Kept and becomes the only theme.** Dark deleted instead |

### The one thing that changed everything

"Content is behind the glass" is not a small amendment. It invalidates v1's central mechanism (§4.3 analytic luminance) and forces a scope decision that v1 got wrong — and, usefully, it moves the design *toward* how Apple's material actually works rather than away from it.

In iOS 26, Liquid Glass is **the navigation layer, not the content layer.** Tab bars, toolbars, floating controls, sheets — these are glass, and content scrolls *underneath* them. Content itself sits on ordinary opaque surfaces. v1 made every card glass, which is both un-Apple and, on a mid-range Android, unshippable.

So the layer model inverts:

```
v1:  glass cards  over  procedural mesh        (glass everywhere, ~60% of viewport blurred)
v2:  glass chrome over  opaque content         (glass ~15% of viewport, content is king)
```

This single correction resolves three problems at once — authenticity to the material, the mid-range perf budget (§5), and the light-on-light contrast trap (§4.3). Everything below follows from it.

---

## 1. Requirements

### Functional
- One light theme, applied globally. No user-facing dark mode.
- A glass material used **exclusively** for chrome: bottom nav, top bar, FAB, sheets, floating controls, the AI command bar.
- Content surfaces are **opaque** — cards, lists, rows, forms. They may be colorful; they are never translucent.
- Colorful accents readable on white, in two variants (fill vs. text).
- The material reacts: to content passing behind it, to touch, to scroll.

### Non-functional
| Requirement | Target |
|---|---|
| Frame budget | **60fps sustained on a Galaxy A54** during scroll-under-glass (the worst case). 60fps on a vivo Y21s **in Tier C** (§5.1) |
| Blurred viewport area | **≤ 20%** (was 60% in v1) |
| Glass surfaces per screen | ≤ 3, **0 nested** |
| Contrast | WCAG AA against the **worst-case content** passing behind the glass — not average, not the mesh |
| Accessibility | Reduce Transparency / Increase Contrast / Reduce Motion each degrade to a legible, unblurred UI |
| Platform | Android is now the **primary** perf target. iOS gets the headroom for free |

### Constraints
- **Flutter has no native Liquid Glass API.** `UIGlassEffect` is not exposed; platform views are not viable here. This is a from-scratch approximation.
- **Mid-range Android is the hardest case for this material.** `BackdropFilter` is fill-rate-bound, and mid-range GPUs are exactly where fill rate runs out. The ≤20% budget is not conservatism; it is the requirement.
- Impeller required. No Skia fallback for the shader tier.
- Solo/small team, 7.2k lines, heavy existing drift.

---

## 2. What Liquid Glass requires

Six behaviors. Current `GlassContainer` implements two.

| # | Behavior | Today | Plan |
|---|---|---|---|
| 1 | **Backdrop frost** | ✅ `BackdropFilter` | Keep, unify sigma |
| 2 | **Edge refraction** — rim bends content behind it like a lens bevel | ❌ **missing** | Fragment shader (§4.2). *The defining behavior* |
| 3 | **Specular highlight** on a light source | ⚠️ static gradient | Motion-driven light vector |
| 4 | **Adaptive tint** — preserves contrast as content varies behind | ❌ missing | §4.3 — **completely redesigned in v2** |
| 5 | **Fluid morph** between states | ❌ missing | `AppMotion` + uniform lerp |
| 6 | **Regular / Clear variants** | ❌ single | `GlassVariant` enum |

Behavior #4 was the hard problem in v1 and is *harder* in v2 — arbitrary content, not a mesh we control, and light-on-light instead of light-on-dark.

---

## 3. High-level architecture

The load-bearing split is **chrome vs. content**.

```
┌────────────────────────────────────────────────────────────┐
│  CHROME LAYER — glass, ≤20% of viewport                     │
│                                                             │
│    ┌──────────────────────────────────────────┐            │
│    │  GlassSurface  · top bar                 │            │
│    │                · bottom nav / FAB        │  frost      │
│    │                · sheets, command bar     │  refract    │
│    └──────────────────────────────────────────┘  specular   │
│                        ▲                          adaptive  │
│                        │ scroll-coupled tint (§4.3)         │
├────────────────────────┼────────────────────────────────────┤
│  CONTENT LAYER — opaque, scrolls underneath                 │
│                                                             │
│    cards · lists · rows · forms · charts                    │
│    solid fills, colorful, full contrast, ZERO blur          │
├─────────────────────────────────────────────────────────────┤
│  CANVAS — off-white, optional faint ambient wash            │
├─────────────────────────────────────────────────────────────┤
│  TOKENS — DesignTokens. No widget defines a color.          │
└─────────────────────────────────────────────────────────────┘
```

Two rules make this enforceable:

1. **Glass is chrome. Chrome is glass.** If it scrolls, it is not glass. If it floats above scrolling content, it is glass. No exceptions, no judgment calls.
2. **Content never blurs content.** The `GlassSurface` in the chrome layer is the only `BackdropFilter` in the tree.

Rule 1 is why v1's nesting ban (chat bubbles inside a blurred screen — `chat_screen.dart:497`) becomes structurally impossible rather than review-enforced. Message bubbles are content, so they are opaque, so they cannot nest.

---

## 4. Deep dive

### 4.1 Token layer — light, colorful, dual-variant

**Canvas & content:**
```
canvasBase       #F7F8FC   the page — off-white, faintly cool
surfaceOpaque    #FFFFFF   content cards — solid, always
surfaceSunken    #EEF1F7   wells, inputs, inactive tracks
hairline         #E2E6EF   dividers, card edges
```

**Accents — two variants each.** This is the part light themes get wrong.

A saturated color bright enough to fill a button is almost never dark enough to be *text* on white. One token cannot serve both. Every accent therefore ships as a pair:

| Role | `…Fill` (bg, white text on it) | `…Ink` (text/icons on white) |
|---|---|---|
| primary — coral | `#F2564F` | `#C8322B` |
| secondary — violet | `#6C5CE7` | `#5442C4` |
| tertiary — cyan | `#1CA5D8` | `#0F7BA6` |
| success — mint | `#12A67B` | `#0B7D5C` |
| warning — amber | `#E8940C` | `#9A5F00` |
| error — rose | `#E11D48` | `#B3123A` |

- `…Fill` targets ≥3:1 against white so it is a legal **UI/large-text** surface, with white text on top.
- `…Ink` targets ≥4.5:1 against `canvasBase` and `surfaceOpaque` so it is legal **body text**.
- Using `…Fill` as text, or `…Ink` as a large fill, fails review.

> **Verify, don't trust.** These are designed to targets, not measured. Phase 2 must run every pair through a contrast checker against `canvasBase`, `surfaceOpaque`, **and glass-over-worst-case-content** (§4.3). Any pair that misses gets darkened. I am not asserting the exact ratios.

**Text ramp:**
```
textPrimary    #14161F   headings, body
textSecondary  #4A5063   supporting
textTertiary   #6B7280   FLOOR — meta only, never on glass (§4.3)
textOnFill     #FFFFFF   on any …Fill surface
```

**Deleted:** the entire dark palette from v1, `ink`/`onInk`, `cardWhite`, `secondaryCard`, `pageBackdrop`, all `glass*` back-compat aliases, and every radius not in the 6-step scale. Back-compat aliases are how the drift happened; they don't survive.

### 4.2 The refraction shader

Unchanged from v1 in mechanism. `shaders/liquid_glass.frag`, registered under `flutter: shaders:`, applied inside `BackdropFilter`:

```dart
final program = await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
final shader = program.fragmentShader()
  ..setFloat(0, size.width)
  ..setFloat(1, size.height)
  ..setFloat(2, cornerRadius)
  ..setFloat(3, bevelWidth)       // how far the lens distortion reaches inward
  ..setFloat(4, refractionIndex)  // displacement strength
  ..setFloat(5, lightVector.dx)
  ..setFloat(6, lightVector.dy)
  ..setFloat(7, adaptiveTint);    // ← new in v2, driven by §4.3

BackdropFilter(
  filter: ui.ImageFilter.compose(
    outer: ui.ImageFilter.shader(shader),   // ← SPIKE-1
    inner: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
  ),
  child: ...,
)
```

Algorithm: signed distance to the rounded rect; within `bevelWidth` of the rim, displace sampled UV along the SDF gradient by a curve of that distance. Specular = SDF-gradient normal · `lightVector`.

> **SPIKE-1 — blocking, do first.** Confirm `ui.ImageFilter.shader()` composes with `blur` inside `BackdropFilter` on Impeller, in a **release** build, with content scrolling behind it — measured on **both** reference devices (§5.1). v1 treated this as a correctness spike; in v2 it is equally a *performance* spike.
> **Its real output is the tier boundary**, not a yes/no: where does A end and B begin, and does the Y21s hold Tier C at 60fps? Record frame times for all three tiers on both devices.
> **Fallback if the shader path fails:** render the rim as a `CustomPaint` overlay over a backdrop snapshot refreshed on scroll-settle. Cheaper, less alive, acceptable.
> **Timebox: 1 day.** Nothing in Phase 2+ starts until it resolves.

### 4.3 Adaptive contrast — redesigned

**v1's mechanism is dead.** It computed mesh luminance analytically because we owned the mesh. Arbitrary content can't be computed — and the exact risk v1 flagged as open question #3 ("does anything media-rich sit behind glass?") is now the confirmed default.

The problem is also worse than v1's. Light glass over light content is the lowest-contrast configuration in UI design: white-ish text is illegible, and dark text competes with whatever passes underneath. A photo scrolling behind a nav bar will destroy either choice.

**The layered answer — correctness never depends on sampling:**

**Tier 1 — A frost floor that is legible unconditionally.** Light-mode glass is *frostier* than dark-mode glass: white tint at **~72% top / ~62% bottom** over blur 24, not v1's 35%/14%. Backing content reads as diffuse color and movement, never as legible shapes. `textPrimary` on this passes AA over *any* backdrop. This is the guarantee, and it holds with zero sampling.

The cost is honest: less transparent than iOS. On light-over-light there is no alternative — Apple hits the same wall and solves it the same way, with heavier `.regular` frost in light mode.

**Tier 2 — Scroll-coupled tint, as enhancement only.** When content is scrolled under a bar, nudge `adaptiveTint` up (frostier, slightly deeper) and relax it when the content beneath is empty or near-canvas. Driven by scroll *offset and velocity* — data we already have, no readback, no GPU stall.

**Tier 3 — Optional low-frequency sampling, Tier A devices only.** Downscale the backdrop to ~8×8 via `RenderRepaintBoundary.toImage()` on **scroll-settle only** (never per-frame), read mean luminance, refine the tint. Off by default on mid-range. Cut it entirely if SPIKE-1 shows no headroom.

**The invariant:** Tiers 2 and 3 make the glass feel alive. Tier 1 makes it *legible*. Contrast correctness never depends on 2 or 3 — so it never depends on a readback, and never regresses on a slow device.

Consequence for tokens: **`textTertiary` is banned on glass.** Meta text goes in the content layer where it has an opaque background.

### 4.4 Canvas and the runtime image theming

The mesh is no longer a lighting model — content is what sits behind glass now. It survives, demoted twice over: a **faint, low-saturation ambient wash** on `canvasBase`, visible only where content doesn't cover it, at a fraction of v1's saturation. On light it must stay near-white or it competes with content.

The Unsplash extraction (`theme_provider.dart`), the audit's fourth source of truth, is subordinated harder than in v1:

```
extracted color  ──→  accent HUE rotation, within a locked lightness/chroma band   ✅
                 ──→  ambient wash tint                                             ✅
                 ──✗  lightness, chroma, or any text color                          ✗
```

Rotating hue while pinning lightness and chroma means every derived accent inherits the verified contrast of the pair it replaces. The picker still changes the app's mood; contrast stays provable. If holding that band proves fiddly in Phase 3, delete the feature — it has never been validated with users (audit §5).

### 4.5 Motion-lit specular

`sensors_plus` → low-pass gravity vector → `lightVector`. 30Hz ceiling, subscribed only while glass is mounted and foregrounded, hard-off under Reduce Motion, static vector on web/desktop.

**Now the first thing to cut, not merely a candidate.** The perf floor moved to mid-range Android and the frame budget is tighter; if SPIKE-1 comes back marginal, this goes before anything else is touched.

---

## 5. Performance

### 5.1 Reference devices — two roles, not one choice

| | **Galaxy A54** (2023) | **vivo Y21s** (2021) |
|---|---|---|
| SoC | Exynos 1380 | Helio G80 |
| GPU | **Mali-G68 MP5** | **Mali-G52 MC2** |
| Display | 1080×2340 @ **120Hz** | 720×1600 @ 60Hz |
| RAM | 6–8 GB | 4 GB |
| Class | **Mid-range** | **Entry-level** |

These are two classes apart — roughly 5 shader cores against 2, and two generations. They are not alternatives; they answer different questions, so **both are named, with different jobs**:

- **Galaxy A54 — the design target.** Tier B (blur, no shader) must be *correct and 60fps* here. Every number in §5.2 is sized against this device. If it looks right nowhere else, it must look right here.
- **vivo Y21s — the degradation floor.** Expect **Tier C**. Its job is not to run glass; its job is to prove the ladder degrades automatically and that Tier C is a genuinely good theme rather than a sad fallback. If the Y21s experience is embarrassing, Tier C is under-designed.

`BackdropFilter` is fill-rate-bound, so the Y21s' low resolution (45% of the A54's pixels) partly offsets its much weaker GPU — but not enough to expect blur + shader at 60fps. **Plan for Tier C there and treat anything better as a finding, not a requirement.**

**Two device-specific gotchas:**

1. **The A54 is a 120Hz panel.** At 120Hz the frame budget is 8.3ms, not 16.6ms — the *harder* target, and easy to measure against by accident. The requirement is **60fps sustained**; glass screens should cap to 60Hz on Android rather than chase 120. Only Tier A devices should attempt glass at 120.
2. **The Y21s has 4GB RAM.** `BackdropFilter` allocates `saveLayer` buffers. Less acute at 720p, but memory pressure is a real Tier-C trigger — watch it during SPIKE-1 rather than assuming fill rate is the only limit.

> **If Y21s-class hardware turns out to be a large share of real users, this design inverts:** Tier C becomes the default experience and glass becomes progressive enhancement for the minority. That is a product-data question, not an architecture one — see §8 Q1. Worth answering before Phase 4, because it changes which tier gets the design attention.

### 5.2 Budget

| Rule | v1 | **v2** |
|---|---|---|
| Blurred viewport area | ≤60% | **≤20%** |
| Glass surfaces per screen | ≤6 | **≤3** |
| Nested glass | 0 | **0 — structurally impossible** (§3) |
| Shader refraction layers | 1 | **1** |
| Blur sigma | token only | token only |
| `RepaintBoundary` isolating chrome from content | — | **required** |

The chrome-only scope is what buys the budget. A bottom nav plus a top bar is roughly 15–18% of a phone viewport — inside budget with headroom, where v1's glass-everything model had none on this hardware.

The `RepaintBoundary` line is not optional: without it, every content scroll frame repaints the glass. With it, the glass repaints only when its own tint changes.

### 5.3 Degradation ladder

Perf tiers and accessibility settings collapse into one mechanism — still the best structural idea in the design.

| Tier | Trigger | Renders |
|---|---|---|
**The ladder is retired.** v3 ships one tier on every device:

| Tier | Status |
|---|---|
| **C — Solid** | **The product.** Every device, every user, all three a11y settings. The only tier that exists |
| B — Blur | Deferred. Revisit only if §8 Q1 shows a flagship-heavy user base |
| A — Shader | Deferred indefinitely. Depends on B |

Deleting the ladder deletes the tier-detection machinery, the jank telemetry that would have driven it, and the requirement to design and review every screen twice. On a solo team that saving is larger than it looks — v2's §7.2 checklist demanded every screen be verified in two tiers against two devices, which is four review passes per screen.

Reduce Transparency and Increase Contrast now need no special handling: **there is nothing to reduce.** Reduce Motion still matters and `AppMotion.reduced()` already handles it.

### 5.4 Depth without blur

Glass was carrying elevation. Removing it means depth has to come from somewhere, and the answer is the boring one that works on every GPU — three ranked cues, applied in this order:

1. **Color step.** `canvasBase #F7F8FC` → `surfaceOpaque #FFFFFF`. A raised surface is *lighter* than its ground. This does most of the work and costs nothing.
2. **Hairline.** `1px #E2E6EF`. Defines the edge crisply — the thing the screenshot most lacks, where cards dissolve into their background.
3. **Soft shadow, sparingly.** `rgba(16,20,40,0.06)`, blur 16, y+4. One level only. Two shadow tiers on light surfaces read as dirt, not depth.

For the bottom nav and any floating chrome, add a **top hairline plus a slightly stronger shadow** so it reads as sitting above the scroll — the job the blur used to do.

Explicitly rejected: multiple shadow elevations (Material's 1–24dp) and tinted shadows. Both muddy a light theme, and muddiness is the exact fault v3 exists to correct.

Tier C remains a deliberately designed theme, not a broken one. A user with Reduce Transparency gets better contrast, not a degraded app.

---

## 6. Trade-offs

| Decision | Cost | Why anyway |
|---|---|---|
| **Glass = chrome only** | Less glass on screen than the mockups imply; some `template/` cards can't be glass | Buys the mid-range perf budget, matches Apple's actual scope, and kills nesting structurally. The highest-value decision in v2 |
| **Frost floor ~72%** (§4.3 Tier 1) | Noticeably less transparent than iOS marketing shots | Light-over-light has no other legible answer. Apple frosts harder in light mode for the same reason |
| Content opaque, not translucent | Loses the layered depth of the v1 concept | Depth now comes from the chrome floating *over* content — which is the real effect anyway |
| Dual-variant accents | 12 tokens instead of 6; authors must pick correctly | One token cannot be both a legal fill and legal body text on white. The alternative is silent AA failures |
| Custom shader on mid-range | GLSL maintenance, Impeller-only, and now a real perf risk | Refraction *is* Liquid Glass. But SPIKE-1 is now a genuine go/no-go, not a formality |
| Light-only, delete dark | One-way door; loses dark-mode users | Four themes is why nothing is consistent. Tier C covers the high-contrast need |
| Keep image theming, hue-only | Complexity retained for an unvalidated feature | Hue-only rotation makes it contrast-safe. Still a product call, still unanswered |

**On the reversal itself:** flipping Phase 0 one turn later cost nothing, because nothing was built. The same flip after Phase 2 would have meant re-verifying every accent pair and re-auditing every screen in both tiers. The phasing in §7.3 keeps the token rewrite behind the spike partly for this reason — decisions stay cheap until Phase 2 starts.

---

## 7. Workflow

> **Note:** there is no `/workflows` skill installed in this session. I read the intent as *how design changes flow into the app, and in what order*. If you meant CI/`.github` automation or a user-facing feature flow, say so and I'll redo this section.

### 7.1 Token pipeline — one direction

```
  this document  ─→  design_tokens.dart  ─→  app_theme.dart  ─→  widgets
   (decisions)        (raw values only)      (ThemeData map)     (consume only)
```

Grep-enforceable in review:
1. **No widget declares a color, radius, duration, or blur.** `Color(0x…)`/`Colors.*` outside `design_tokens.dart` fails. *(Exception: semantic data palettes — `weather_condition.dart`, `note_model.dart` — which move into tokens as named sets.)*
2. **No widget builds a raw `TextStyle`.** `Theme.of(context).textTheme.*` only.
3. **No widget calls `BackdropFilter`.** `GlassSurface` only — and only in the chrome layer.
4. **No content widget is translucent.** New in v2, and the rule that keeps §3 honest.
5. `app_theme.dart` maps; it never decides.
6. Design changes edit this doc first, then tokens. Never code first.

Rules 1–3 are exactly the three drift vectors the audit measured (236 literals, 99 `TextStyle`s, 4 rogue blurs). Rule 4 is the new structural one.

### 7.2 Definition of done — per screen
- [ ] Zero color/type/blur literals (grep-clean)
- [ ] Chrome is `GlassSurface`; **content is opaque**
- [ ] ≤3 glass surfaces, 0 nested, ≤20% blurred area
- [ ] `RepaintBoundary` between chrome and content
- [ ] Reviewed in **Tier B first**, then A and C
- [ ] Contrast verified with **worst-case content** scrolled under the glass — a photo, a chart, a dense list
- [ ] No `textTertiary` on glass
- [ ] Every icon-only target has `Semantics`/`tooltip`, ≥44×44
- [ ] Profiled **on the A54 in Tier B** — no dropped frames scrolling under glass
- [ ] Spot-checked **on the Y21s in Tier C** — legible, complete, not embarrassing

### 7.3 Phasing

| Phase | Work | Gate |
|---|---|---|
| **0** ✅ | Decision settled — solid light, Tier C is the product | *done* |
| **0.5** ✅ | Reference devices named — Y21s is the target | *done* |
| **1** | ~~SPIKE-1~~ **Deleted.** No shader, so nothing to spike. Phase 2 starts immediately | — |
| **2a** ✅ | **Stop the bleeding.** Defaulted `themeMode` to light, stopped startup image extraction, pinned every M3 role to a token, removed `MeshBackground`, retargeted token *values* without renaming | *done 2026-07-21 — `flutter analyze` clean, 6/6 tests pass. **Not yet visually verified on a device.*** |
| **2b** | Rename/delete tokens properly: drop the dark palette, Studio/Aurora overlap, and all `glass*` back-compat aliases. **Verify all 12 accent pairs with a contrast checker** | Compiles, one palette, contrast verified |
| **3** | Delete `GlassContainer`, `MeshBackground`, and all 4 rogue `BackdropFilter` sites. Replace with the §5.4 depth cues | Zero blur in the codebase |
| **4** | Screen migration, drift-order: `dashboard` → `chat` → `weather` → `calendar` → `news` → `notes` | §7.2 checklist each |
| **5** | Accessibility sweep — the audit's 0-coverage finding | Semantics everywhere |

**2a before 2b is the important sequencing.** 2a is a handful of lines in three files and immediately fixes the screenshot, because the fault is *which theme is selected*, not what the tokens contain (§0.1). 2b is the wide, breaking rename. Doing 2a first means the app looks right while the larger cleanup proceeds, instead of staying lavender until a 50-file refactor lands.

Phases 3–5 are now the entire remaining design work. v2 had a shader spike, a chrome/content reclassification, a material primitive, and two-tier reviews on top of this — all of it deleted by the v3 decision.

---

## 8. Open questions

1. **What share of real users are on Y21s-class hardware?** If it's large, the design inverts — Tier C becomes the default and glass becomes enhancement (§5.1). Answer before Phase 4; it decides which tier gets the design effort. This is the highest-value open question in the document.
2. **SPIKE-1** — shader composition, frame cost, and tier boundaries on both devices. Blocks Phase 2. *(1 day)*
3. **Which `template/` surfaces are chrome vs. content?** The mockups render many things as glass cards that §3 makes opaque. Worth walking `homepage_and_calender.html` and `overview_chat_and_ai_chat.html` and labelling every surface before Phase 3 — that's the whole Phase 3 input.
4. **Is the image-theming feature worth its complexity?** Architecturally safe now (§4.4), still an unvalidated product question. Carried from the audit.
5. **Font.** `IBM Plex Sans Thai` vs. Hanken Grotesk remains unrecorded. If it's a Thai-script requirement, write it down and close it.

---

## 9. What I'd revisit as this grows

- **The ≤20% blur budget** is sized for one bottom nav plus one top bar. A design wanting a glass sheet *and* a glass command bar simultaneously will breach it — at which point the sheet should occlude rather than blur.
- **Tier B as the design target** is right while Android mid-range is the floor. If analytics later show an iOS-heavy user base, promoting Tier A to the design target unlocks the sampling tier and a lighter frost.
- **The frost floor (~72%)** is the most likely token to move after real testing. It is set for the worst case — a photo under the bar. If content is mostly text and quiet cards, it can come down, and the glass gets more transparent for free.
- **Shader count.** One `.frag`. Resist growth — each one is a platform correctness risk with no Skia safety net.
