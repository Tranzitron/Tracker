# Refinement Plan

Planned multi-milestone execution of `Refine.md`, grounded in a full pass over the current implementation. Each milestone is independently shippable, keeps tests green, and is ordered by implementation dependency so shared foundations and state-model changes land before the screens that consume them. The milestone numbers are stable references; the recommended execution order is listed below.

Contents:

- [Current state evidence](#current-state-evidence)
- [Milestone overview](#milestone-overview)
- [M1 — Navigation bar & feed quick action](#m1-navigation-bar-feed-quick-action)
- [M2 — Gyms page](#m2-gyms-page)
- [M3 — Settings page](#m3-settings-page)
- [M4 — Workout / Editor rework](#m4-workout-editor-rework)
- [M5 — History calendar](#m5-history-calendar)
- [M6 — Input validation everywhere](#m6-input-validation-everywhere)
- [M7 — Weight multipliers per movement/equipment, time-adapted](#m7-weight-multipliers-per-movementequipment-time-adapted)
- [M8 — User-defined graphs (Feed)](#m8-user-defined-graphs-feed)
- [Ambiguities](#ambiguities)
- [CI / hygiene notes](#ci-hygiene-notes)

---

## Current state evidence

| Area | File | Current behavior |
| --- | --- | --- |
| NavBar | `tracker/lib/home_page.dart:95-151` | `NavigationBar`, 5 tabs, `labelBehavior: alwaysShow`. Label `'CurrentWorkout'` (line 128) overflows narrow destinations. No per-tab icon geometry override; M3 default ripple/ink; `indicatorColor` transparent (line 97). Tab → page map at lines 76-83. |
| Tab names | `home_page.dart:206` | `TabName { feed, history, currentWorkout, editor, exercises }` — `currentWorkout` entry feeds `HomePageSingleton.tabMap` (lines 186-194). |
| Feed | `tracker/lib/pages/feed_page.dart:129-133` | `'Go to Current Workout'` button lives in an **always-appended** footer sliver; no `WorkoutCubit` read → shows even when a workout is active and even when no session exists yet. Pushes `changeTab(currentWorkout)`. |
| Gyms list | `tracker/lib/pages/settings/gyms_page.dart` | `_addGym` (42-56) never auto-promotes the first gym to primary. No duplicate-name check anywhere. `_GymTile` (287-347): `Card > ListTile`, **no tile `onTap`** — only the trailing `PopupMenuButton` (321-343) with 'primary/edit/estimate/delete'. |
| Gym edit | `gyms_page.dart:205-285` | `_editGymDialog` AlertDialog: name, description, multiplier `TextField`s. Save: `double.tryParse(...) ?? 1.0` (267-268), no range check. Name guard only shows silent return at 267. |
| Gym model | `tracker/lib/models/gym.dart:12-19` | `isPrimary`, `order`, `multiplier` (global, default 1.0). No duplicate enforcement, first-gym-primary, or per-exercise multipliers. |
| Settings | `tracker/lib/pages/settings_page.dart` | 5 options, all tappable full-width cards via `_buildSettingsCard` (67-84). Units opens a `SimpleDialog` (125-142). Booleans open `_confirmToggle` dialog with an inline `Switch` (177-205). Profile card (30-37) + `_editProfile` dialog (86-123) — `displayName`/`email` read nowhere else in the app. |
| Settings state | `tracker/lib/pages/settings/settings_cubit.dart:15-19` | `unit`, `displayName`, `email`, `notificationsEnabled` (default true), `analyticsEnabled` (default true), all hydrated. |
| Workout page | `tracker/lib/pages/workout/workout_page.dart` | Splits grouped into `BuildMaterialSplit` cards: split header tile → `SplitEditorPage`, day tiles → `SplitDayPage` (50-57). `BuildStartWorkoutButton` lives **above** the list unconditionally (line 50). Day subtitles render raw `exerciseId` ints (line 204) instead of names. |
| Split editor | `tracker/lib/pages/workout/new_split_page.dart` | No Start button. Name guard via snackbar (89-95). **No delete-split affordance** — delete only via popup menu on the list page isn't present either; split removal is currently possible nowhere obvious. |
| Day editor | `tracker/lib/pages/workout/split_day_editor_page.dart` | Title/description/exercises via reorderable list. Day title empty → falls back to `'Split Day'` (75). |
| Split detail | `tracker/lib/pages/workout/split_day_page.dart:58-83` | Builds plan from day items, `startPlanWorkout(title: 'SplitTitle · DayTitle')`, then switches to the workout tab. Satisfies "click a split-day to start that workout". |
| Populars | whole repo | **No split templates exist** — only `Refine.md` / `Plan.md` mention PPL. |
| History | `tracker/lib/pages/history_page.dart`, `history_calendar.dart`, `calendar_grid.dart` | Calendar = one tall `Column`: month header → weekday row → full `GridView.count` (7×6 = 42 cells always) → metrics strip → divider → "Workouts · date" title → inline day list. The whole block scrolls inside the page's `CustomScrollView`; selecting a day grows the list and pushes the grid off-screen — you must page-scroll to see the workouts. No independent scroll region (`_dayList` is a plain Column, calendar_grid.dart always allocates 42 cells: GridView in calendar at 116-124, cell margin/padding at 144-162). |
| Session detail | `tracker/lib/pages/history/session_detail_page.dart` | Fine as-is. |
| ValidateForms | `new_exercise_page.dart` only | Only exercise creation uses `Form` + validator + "Required" (82-90). Split editor, gym dialog, profile dialog, split/current add-set all have no `Form`, no validator, no inline error text. |
| Multi‑lier | `tracker/lib/analytics/analytics.dart` | `normalizedWeight` scales raw weight by `multipliers[gymId]` (global per gym). `estimateGymMultiplier` (258-286): median of per-exercise mean-ratio across shared exercises — no time weighting, bundles only PL/Gym level. `WorkoutSession` has `gymId` + `WorkoutSet { exerciseId, weight, reps, type, order }` (workout_session.dart / workout_set.dart) → enough data for per-exercise, date-weighted estimates. |
| Multimap | `gyms_page.dart:80-102` | manual or auto (`_estimateMultiplier` needs primary gym). |

---

## Milestone overview

| Execution order | Milestone | Title | Refine.md items | Size | Depends on |
| --- | --- | --- | --- | --- | --- |
| 1 | M1 | NavBar + Feed quick action | NavBar items 1-3; Feed item 1 | S | — |
| 2 | M6 | Input validation | Features/Inputs 1-2 | M | — |
| 3 | M2 | Gyms page | Gyms items 1-4 | S | M6 (shared validators) |
| 4 | M3 | Settings page | Settings items 1-3 | S | — |
| 5 | M4 | Workout / Editor rework | Workout items 1-2; Editor items 1-4 | M | M1, M3, M6 |
| 6 | M5 | History calendar | History items 1-2 | S/M | — |
| 7 | M7 | Multiplier model | Multiplier items 1-2 | L | — |
| 8 | M8 | User-defined Feed graphs | Feed item 2 | L | M7 (final analytics/multiplier API) |

S = few files + tests. M = moderate, several files producing tests. L = schema/data-model or new feature surface.

### Recommended execution order

The M-number labels are stable references used throughout this document; the **Execution order** column is the order to implement them. This ordering prioritizes shared foundations and API/model changes before dependent screens, so a later milestone does not have to retrofit or replace work from an earlier one:

1. **M1 — NavBar + Feed quick action**: finish the already-started navigation/feed slice and establish the stable tab entry point.
2. **M6 — Input validation**: build the shared validators and apply them to every existing form, including split, gym, exercise, and current-workout inputs.
3. **M2 — Gyms page**: build the gym UX on top of the finished validation and duplicate-normalization helpers; do not implement temporary dialog validation that M6 would later replace.
4. **M3 — Settings page**: simplify settings state and controls before the workout list consumes the new start-button placement setting.
5. **M4 — Workout / Editor rework**: use the M6 form patterns and M3 settings model while reworking the split list/editor; this avoids revisiting those files for validation and settings changes.
6. **M5 — History calendar**: compact the calendar as an independent UI slice after the core entry/edit flows are stable.
7. **M7 — Weight multipliers per movement/equipment, time-adapted**: complete the multiplier model and analytics API before any new consumer is built.
8. **M8 — User-defined Feed graphs**: build graph persistence and rendering against the final M7 analytics/multiplier behavior, avoiding a second graph/analytics migration.

M1, M5, and M7 can be developed independently in principle, but this sequence keeps the main product flow coherent. M6 intentionally precedes both M2 and M4 because it is the shared form foundation; M3 precedes M4 because M4 consumes its settings state; and M7 precedes M8 because M8 consumes analytics and normalized metrics.

Execution note: do not start M2's gym dialog or M4's editor/forms in isolation before M6. If a screen needs a form during an earlier spike, use the shared validator API immediately rather than adding screen-specific validation. Likewise, keep M7's analytics signature and persistence changes together before implementing M8 graph consumers.

---

## M1 — Navigation bar & feed quick action

Scope: the task bar and the Feed → Workout entry point.

### NavBar changes (`tracker/lib/home_page.dart`)

- [x] Rename the 4th destination label and its handling:
  - Change `'CurrentWorkout'` label → `'Workout'` (line 128-like).
  - Keep `TabName.currentWorkout` for `HomePageSingleton.tabMap` (setName must not change or `changeTab(TabName.currentWorkout)` from `feed_page.dart:130` and `split_day_page.dart:82` break). Only the displayed label changes.
- [x] Lifted icon ("always lifted a bit"): wrap the tab icon so the glyph sits visually higher. Cleanest is a custom `Icon` wrapped with `Transform.translate(offset: Offset(0, -2))` inside the `NavigationDestination.icon` slot (per-destination placement), or set an `IconTheme`/custom `assets`. Prefer a small `Transform.translate` and validate on small widths.
  - Nudge values: start `Offset(0, -3)`; verify at textScale/overflow to avoid clipping (label inside `NavigationDestination` is `maxLines: 2`, softWrap off).
- [x] Icons for Editor/Exercises: currently `Icons.add_box_sharp` (editor) and `Icons.library_books_sharp` (exercises). Options (user decision at implementation time, default marked first):
  - Editor: `Icons.assignment_sharp` (default) / `Icons.edit_note_sharp` / keep `add_box_sharp`
  - Exercises: `Icons.local_gym_sharp` (default) / `Icons.sports_gymnastics_sharp`
- [x] Remove tap ripple/click flash of the whole `NavigationBar`:
  - Set `indicatorColor: Colors.transparent` (already, line 97) — *also* set `ThemeData.navigationBarTheme.overlayColor = WidgetStatePropertyAll(Colors.transparent)` to kill the press-state ripple highlight. If a pure transparent `overlayColor` looks "no feedback" at all, keep a faint press — confirm with user, default = fully transparent.
  - Confirm active-tap does still `popUntil(first)` (existing `_selectTab` re-tap behavior, lines 85-95) — that's a zoom behavior we keep.

### Feed — gate quick action

- [x] `feed_page.dart:129-133`: wrap the button in a `BlocBuilder<WorkoutCubit, WorkoutState>`; show **only when `state.isInProgress == false`** (i.e. "no activity yet"). When `isInProgress`, the tab itself plus its header suffice, so hide.
- Keep the Progression card as-is.

### Tests

- [x] `tracker/test/integration/app_test.dart` asserts tab label 'Workout' and gated Feed action: idle shows button; after `cubit.startWorkout` text absent.
- [ ] Keep `HomePageSingleton.tabMap` test-level if any.
- [ ] Check `milestone8_test.dart` doesn't reference the tab label.

---

## M2 — Gyms page

Scope: four Refine Gyms items + the multiplier input hardening that M6 will rely upon.

- [x] First gym is always baseline
  - `_addGym` marks newly created gym primary when fetched gym list is empty; primary multiplier remains 1.0.
  - `promptGym` limits unrelated.
- [x] No two gyms with the same name (and description) ignoring case + "fluff"
  - `_normalizeGymField` trims, collapses internal whitespace, and lowercases name/description; `sameGymName` is unit-tested.
  - `_editGymDialog` compares against all existing gyms, excludes edited ID, and rejects duplicates with `A gym with this name already exists` without saving.
  - "fluff" = repeated/edge whitespace differences; descriptions participate in equality.
- [x] Clicking a gym enters the edit page
  - `_GymTile` ListTile opens existing edit dialog through `onTap`.
- [x] Remove "Edit" from the 3-dot menu
  - Popup menu now contains only Set as primary, Auto-estimate multiplier (when available), and Delete.

### Tests

- [x] `test/unit/gyms_test.dart` covers duplicate normalization, description matching, and missing/empty descriptions.
- [x] Analyzer passes; Isar-backed `gymsPage` integration coverage remains blocked by repository-wide stale native Isar test binaries (Core 3.1.0+1 vs required 3.3.2). Existing persistence fixtures unchanged.

---

## M3 — Settings page

Scope: the design overload on Settings.

- [x] "Units" → a dropdown
  - Replaced tap-to-`SimpleDialog` with inline `DropdownButton<WeightUnit>` showing `kg`/`lb`; selection calls `setUnit`.
  - Default remains `WeightUnit.kilograms`.
- [x] Remove "Profile" option
  - Removed Profile card and profile dialog.
  - Removed `displayName`/`email` from `SettingsState`, `copyWith`, hydration output, and cubit API; `fromJson` tolerates legacy keys by ignoring them.
- [x] Boolean options inline
  - Notifications and Privacy & Security now use inline `SwitchListTile`s; confirmation dialog removed.
  - Privacy switch directly controls analytics sharing.

### Tests

- [x] Unit/integration tests verify legacy profile keys are ignored and omitted, inline switches change state without dialogs, and unit dropdown changes selection.

---

## M4 — Workout / Editor rework

Addresses the page-structure confusion. Two distinct jobs: (A) splits list as the entry point to start workouts; (B) the split editor.

### Workout tab (splits list)

- [x] List of all splits with days — existing list preserved; day tiles open `SplitDayPage`. Day subtitles now resolve exercise IDs to exercise names.
- [x] "Start Workout" button placement — configurable `Before`, `After`, or `Disabled` through `FreeStartPlacement` in `SettingsState`; default is `before`.

### Editor

- [x] Remove "Start Workout" button — editor never renders free-form start; splits-list button can be disabled through settings.
- [x] Rework editor UI — title now shows inline `Cannot be empty` validation; day cards retain edit/remove behavior; empty editor shows `No days yet — add one below`; add-day flow remains available.
- [x] Delete split INSIDE the edit page — existing splits show a bottom `Delete split` action with confirmation; new splits hide it.
- [x] Suggest popular splits — added four pure templates (`PPL`, `Bro Split`, `Upper / Lower`, `Full Body`) in `lib/models/workout_split_templates.dart`; editor can apply templates to prefill day names without exercises.

### Tests

- [x] Template list: `test/unit/workout_templates_test.dart` asserts four templates, non-empty days, and empty exercise scaffolds.
- [x] Split editor: template application and delete controls implemented; title validation is inline.
- [x] Workout list: setting controls button placement; day subtitle resolves names.

Verification: `flutter analyze` and focused settings/template/workout tests pass.

---

## M5 — History calendar

Status: complete. Compact calendar and bounded internal workout panel implemented; focused history tests pass.

- [x] Make the calendar more compact
  - `calendar_grid.dart` (116-124) starts with a `GridView.count(crossAxisCount: 7, childAspectRatio: ~0.9)` instead of the default tall/large cells.
  - Cull per-cell vertical budget: cell `margin: all(2)` → `all(1)` (line 144), day-number style to `bodySmall`, dot from 5×5 → 4×4 or inline dot, gap 2→0 (lines 155-162).
  - Trim the `_MetricsStrip` (265-284) — compress "Workout days / git streak" into compact chips or one line. (Optional alternative: replace with a single-line cohesion row.)
- [x] No scrolling to see workouts of a day
  - The inline day-list pushes grid off-screen today. Reorder so both are visible without page scroll:
  - **Option A (chosen default):** Pin the calendar widget to a fixed viewport area: grid + a bounded "Workouts · <date>" panel below it. The day list becomes a `ListView` inside a fixed-height region (about two tiles) with `shrinkWrap`/internal scrolling — grid always visible, long days scroll within the panel, no page scroll needed.
  - **Option B:** Show the day's workouts in a `showModalBottomSheet`/`DraggableScrollableSheet` on tap instead of inline. Simpler, but loses the at-a-glance empty-state and adds a tap-to-open step.
  - Keep the grid on top; the page-level `CustomScrollView` (history_page.dart:55) stays the only page scroll.
  - `CalendarGrid`/`currentStreak` math (pure in `calendar_grid.dart`) is untouched by the visual compaction.

### Tests

- [x] Grid still marks a day that has workouts; existing calendar math tests remain green; bounded day-list behavior has integration coverage.

---

## M6 — Input validation everywhere

Status: implementation complete for shared validators, exercise/split/day/gym/current-workout inputs, and multiline descriptions; focused tests and analyzer pass.

Thorough pass on every free text / numeric input.

### Validation layer

- [x] Shared util `lib/pages/custom/form_validators.dart` provides `requiredText` and positive-number `requiredDouble` with exact validation messages.

### Apply

- [x] Gym dialog validates name and positive multiplier with inline error text; invalid save is blocked; duplicate normalization from M2 retained.
- [x] SplitEditor title uses inline validation; SplitDayEditor validates day title.
- Profile removed in M3.
- [x] `NewExercisePage` retains `Form` validation with shared `requiredText` and expanding description.
- [x] `CurrentWorkoutPage._AddSetForm` validates positive weight and reps with inline errors before logging.

### Auto-expanding description boxes — "1 line, growing as you type"

- [x] Target descriptions use `minLines: 1`, `maxLines: null`, and `TextInputType.multiline` for split, day, exercise, and gym inputs.

### Tests

- [x] `test/unit/form_validators_test.dart` covers required/positive validation; focused workout/widget tests pass.

---

## M7 — Weight multipliers per movement/equipment, time-adapted

Status: complete. Additive per-exercise overrides, time-aware estimation, regenerated Isar schema, consumer updates, and analytics tests implemented.

Replaces the global gym multiplier concept with per-machine/movement estimates that self-update.

### Data check

Already sufficient: `WorkoutSession { gymId, startTime }` + `WorkoutSet { exerciseId, weight, reps, type }` + `Exercise { movementPattern, equipment, muscles }` — everything needed for per-exercise, date-weighted estimation already persists.

### Design (two-track)

- [x] Model/basic UI (schema-light) — per-exercise overrides persisted in additive embedded Isar records; global fallback retained.
  - Extend the estimate to per-exercise with a movement fallback: add a `Map<int, double> perExerciseMultipliers` on `Gym` in addition to `multiplier` (the global fallback stays for safety). Manual display in gym editor: "×1.2 …" list of per-machine multiplic.
  - Isar change → `dart run build_runner build` + regenerated `.dart`; schema version migration needed (Isar handles internally, but CI drifts must pass).
- [x] Time-aware auto-estimation — exponential half-life weighting and movement fallback implemented in analytics.
  - Replace/augment `estimateGymMultiplier` in analytics (258-286): for each shared exercise pair (gym A primary, gym B): compute windowed ratio with **exponential/linear time-decay** — weights from recent sessions dominate. Moving-average window e.g. last-M sessions, then median across exercises; fall back to movement-group median when no shared exercise; does not require identical dates.
  - Automatic re-estimation: after each session in a new gym (`endWorkout`), update the best-estimated multipliers for that gym (cheap; pure function + repo put — same as current manual estimate, but hook `endWorkout` or page-visit compute).
- [x] UI: Gyms page shows per-exercise override count; Auto-estimate recomputes and persists overrides.
- [x] `normalizedWeight` accepts exercise context and applies per-exercise override before global gym fallback.

### Effort note

This is the largest milestone — schema + analytics + models change. Plan a spike on Isar map persistence and drift checks. Keep Math pure and unit-tested (median, decay) in `analytics_test.dart`.

### Tests

- [x] Pure-function tests cover per-exercise override precedence, recent-heavy decay, movement fallback, and no-data behavior; Isar schema regenerated and migration-compatible defaults preserved.

---

## M8 — User-defined graphs (Feed)

Status: implementation complete. Hydrated graph configuration, analytics series selection, Feed graph editor/cards, and unit coverage implemented.


### Shape

- [x] Feed retains Recent activity and adds Analytics section with Add graph action.
- [x] Graph config supports title, optional exercise/all filter, metric (best 1RM/peak weight/volume), and timeframe; cards render through existing `LineChart` and analytics series APIs.
- [x] Graphs persist in hydrated `SettingsState` with tolerant parsing and CRUD methods.
- [x] `AnalyticsService` supplies timeframe-aware point series and exercise-filtered volume.
- [x] Feed renders graph cards with edit/delete actions and empty/no-data states.

### Size

Large — new persisted model + analytics wiring + UI. Could be split into two M8a (bare: add graph labelled from existing exercise list, no timeline range) and M8b (filters/ranges).

---

## Ambiguities

Decisions the plan defaults to; flag if you disagree.

1. **Feed button text/gating**  
   "Only show 'Go to current workout' if there is no activity yet" → show only when `!isInProgress`. Button label stays 'Go to Current Workout'.
2. **"Editor: Remove Start workout button"** vs. **"Workout: make it configurable (Before/After/Delete)"** — the button today lives on the splits-list page only, not in the editor. Interpretation: the **splits-list** Start button becomes configurable placement with a 'Delete' (hidden) option; the editor page itself never renders such a button. One control, both Refine items satisfied.
3. **"First gym is always baseline"** = first-created gym gets `isPrimary: true`, auto-multiplier 1.0. No UI change needed beyond that default.
4. **"fluff"** = collapsing whitespace, non-sensitive normalization (trim + lower).
5. **Units dropdown** chosen over the panel (simple dropdown in a card list row).
6. **Evolution of gym multiplier architecture** (M7): per-movement estimate extends rather than replaces the global multiplier and the `isPrimary` baseline lock (×1.0).
7. **Big editorial split in editor day-labels**: falls not a functional change.

## CI / hygiene notes

- Any model change (M7, M8 if settings-share) → `cd tracker && dart run build_runner build --delete-conflicting-outputs`, and CI's generated-file drift check must pass.
- The repo duplicates `flutter analyze` + advanced tests on `ubuntu-latest`; run both after every milestone.
- `libisar.dylib` (gitignored) is required by local `flutter test` — unchanged by these milestones.
- Keep the `test/` suite green per milestone; update `widget_test.dart` immediately for tab label/feed gating.
