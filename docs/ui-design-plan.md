# Kairos — UI Design Plan

**Version:** 1.0
**Date:** 2026-08-20
**Scope:** The interaction and layout plan for the Flutter client. Colour,
type and spacing tokens are specified in [design-system.md](design-system.md)
and are not restated here; this document covers **what goes where, why, and
what happens when the user touches it.**

> **Companion documents.** [srs.md](srs.md) says what the system must do.
> [user-flow.md](user-flow.md) is the route table. This is the layer between
> them: the rules that decide a screen's shape.

---

## 1. Design position

Kairos is a **single-user Thai personal dashboard on a phone**. Three facts
about that sentence drive every decision below.

| Fact | Consequence |
|---|---|
| **One thumb, one hand, in transit** | Primary actions live in the bottom third. Nothing important sits in a top corner. |
| **Thai copy** | Labels run 30–60% longer than the English mock. Any layout that divides a fixed width between labels is a defect waiting for a translation. |
| **Every API may be missing** | Four states are mandatory per surface, not three. "Not configured" is a different message from "broken". |

The visual language — *Soft Minimal Japandi*, warm cream and sage, one diffused
shadow, 24px corners — is settled and documented. This plan does not reopen it.

---

## 2. The five layout laws

These are the rules a new screen is reviewed against.

### L1 — Options stack; they do not share a row

A row of N fixed segments divides the width by N. In Thai that overflows.

This is not hypothetical: the contrast control shipped as a three-segment
`SegmentedButton` and **overflowed by 85px on a 412dp phone** because
"ชัดสูงสุด" does not fit in a third of the screen. The date chips shipped as a
fixed `Row` and overflowed by the same amount the moment the third chip showed
a date instead of "เลือกวัน" — **133px at 320dp**.

**Rule.** More than two choices, or any choice whose label is user- or
locale-determined, becomes a **full-width row list** (settings) or a **`Wrap`**
(chips). A second line is free. A clipped control is not.

### L2 — A settings surface is a screen, not a sheet

A bottom sheet is height-capped and sits under the floating nav bar. It suits
**one decision with a short form**: add a task, edit a profile.

It does not suit a surface with two multi-option controls and a profile on it.
That is a screen with an app bar and a back gesture.

| Container | Use for |
|---|---|
| Bottom sheet | One focused input the user is already mid-thought about |
| Focused route above the shell | Settings, chat, the weather canvas — places you go and come back from |
| Tab | Only the four things worth permanent nav real estate |

### L3 — The nav bar holds four, and that is the budget

Four destinations plus a centre FAB. A fifth item shrinks every hit target to
buy one tap.

Chat, account and weather are all **routes above the shell**. They are reached
from the surface that motivates them — the AI pill, the avatar, the weather
card — which is a shorter path than a tab for anything you enter deliberately.

### L4 — Every list has four states, and the empty one is honest

Loading · empty · error · not-configured. The empty state is the one most often
skipped, and skipping it is what produces fake data.

The task list shipped with **four seeded demo tasks** (*Meeting, Icon set,
Prototype, Check asset*) so screenshots looked populated. A real user's first
launch showed four commitments they never made. Seed data is banned; an empty
state that explains the next action replaces it.

### L5 — The keyboard is half the screen

Any form reachable with the keyboard raised must:

- lift above `viewInsets`
- scroll, because the remaining space is smaller than the form
- dismiss on drag — reaching for a covered control *is* the dismiss gesture
- end its field chain on `done`/`send`, not a dead return key
- autofocus **only when the field is empty** — opening the keyboard over
  existing text hides what the user came to check

---

## 3. Screen plan

### 3.1 Dashboard — the answer to "what about today?"

Read top to bottom, most-perishable first.

```
┌──────────────────────────────┐
│ hero header                  │  greeting (clock + profile) · avatar → account
│ ┌──────────────────────────┐ │
│ │ ask the assistant     [↑]│ │  straddles the header edge; sends → chat
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ ✦ สรุปวันนี้                  │  weather × today's tasks, one sentence
│   "…"                        │  tap → chat. Collapses silently on failure.
├──────────────────────────────┤
│ ภาพรวม        ▸ horizontal   │  weather · market · news · notes
├──────────────────────────────┤
│ งานของฉัน                    │  ≤5 upcoming; tap → edit, checkbox → done
└──────────────────────────────┘
```

**Why the advice card sits second.** It is the only element that answers the
question the user opened the app with. It sat unbuilt for the whole project
while being the headline feature — `dailyAdviceProvider` existed and was wired
to nothing.

**Why it fails silently.** The dashboard must work with no API key at all. An
advisory nicety may not put an error banner above the user's real tasks, so on
failure the card collapses to zero height.

### 3.2 Chat — one AI surface, not three

The app had **three** free-text AI inputs: an orphaned command bar never mounted
anywhere, an unreachable quick-add sheet, and a dashboard bar that fired into a
provider whose result nothing displayed. Two were dead; one was a silent no-op.

```
dashboard bar ──send──►  ┌─ chat ─────────────┐  ◄── tap the pill
                         │ empty: 4 prompts   │
                         │ ───────────────────│
                         │ transcript (kept)  │
                         │ ✓ task card [เลิกทำ]│
                         │ ───────────────────│
                         │ composer  1–4 lines│
                         └────────────────────┘
```

| Decision | Reason |
|---|---|
| Four **tappable** example prompts on empty | The old bar hid one example in hint text. Nobody knew what it could do; the empty state is now the feature list. |
| Transcript persists | A reply that vanishes cannot be checked later against what the assistant claimed it did. |
| Last 12 turns sent to the model | Without history a follow-up has no antecedent. Trimmed because a free-tier context window overflows *silently*, which reads as the assistant going stupid. |
| Created task = card with `เลิกทำ` | An action rendered as ordinary grey text is indistinguishable from chatter. |
| Failures stay in the transcript | Dropping one leaves the user's message with no reply and no explanation. |

### 3.3 Task sheet — one form, create and edit

Same sheet both ways: same fields, same date logic, same keyboard handling. A
second copy is one more place for them to drift, and this app had already
accumulated four near-identical bottom sheets.

Delete uses **undo, not confirm**. A confirm dialog taxes the common path to
protect the rare one, and undo additionally covers the mis-tap a dialog would
be dismissed through.

### 3.4 Account — settings with room to breathe

Profile card (gradient, initials, edit / clear) → colour mode → contrast →
about. Every option is a full-width row carrying **a description of what it
does**, because "ชัดขึ้น" alone does not tell anyone what changes.

### 3.5 Weather — the one art-directed screen

Five per-condition palettes as a `ThemeExtension`, light and dark. `night` is
dark in **both** brightnesses: it depicts a night sky, which is content, not
chrome, and inverting it would be a lie about the weather.

---

## 4. Feedback and reversibility

| Event | Feedback |
|---|---|
| Task saved | Snackbar. If ClickUp is configured **and failed**, the message says so — 6s instead of 4s, because there is more to read. |
| Task deleted | Snackbar + `เลิกทำ`, 6s |
| Task created by AI | Inline card in the transcript + `เลิกทำ` |
| Profile cleared | Confirm dialog — genuinely unrecoverable, and rare |
| AI request failed | A failed turn in the transcript, with a hint about the key |
| Advice failed | Nothing. Deliberate; see 3.1 |

**The rule:** reversible actions get undo, irreversible ones get a dialog, and
nothing gets both.

---

## 5. Motion

Durations and curves are tokens (`AppMotion`); this is where they apply.

| Where | What | Why |
|---|---|---|
| Route into a focused mode | Shared-axis Z | The thing you pressed opens *deeper* |
| Weather ↔ detail | Shared-axis X | Two views of one dataset, not a hierarchy |
| Tab change | Fade-through | Peers |
| Cards on load | `FadeSlideIn`, staggered ~40–180ms | Composed, not dumped |
| Any press | `PressableScale`, spring | Carries velocity, so a fast double-tap does not feel laggy |
| New chat message | Animated scroll after layout | Scrolling in the same frame lands short |

`MediaQuery.disableAnimations` is honoured everywhere. The spinner keeps
drawing when motion is reduced — a still indicator beats an invisible one.

---

## 6. Accessibility floor

Non-negotiable, and machine-checked where possible.

| Rule | Enforcement |
|---|---|
| Body ≥ 4.5:1, large ≥ 3:1, in all six variants | `test/theme_test.dart` |
| Targets ≥ 48dp | `DesignTokens.minTouchTarget` |
| Selection never conveyed by colour alone | Check icon beside the fill |
| Every control has a Thai `Semantics` label | Review |
| No overflow at 320dp | Widget tests at 320 and 412 |

The contrast rule is not decorative: four weather text colours failed it when
first audited, the worst at **2.98:1** while carrying 11px text.

---

## 7. Review checklist

Before a screen is called done:

- [ ] Renders under all six theme variants
- [ ] No overflow at 320dp, keyboard raised and lowered
- [ ] Loading, empty, error and not-configured all designed
- [ ] No seed or placeholder data
- [ ] Every touch target ≥ 48dp
- [ ] Reversible actions have undo; irreversible have a dialog
- [ ] No `Color` literal outside the two token files
- [ ] Field chain ends on `done`/`send`; scrollables dismiss on drag
- [ ] Any regression test added was **observed failing first**
