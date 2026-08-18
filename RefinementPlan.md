# Refinement Plan

Planned multi-milestone execution of `Refine.md`, grounded in a full pass over the current implementation. Each milestone is independently shippable, keeps tests green, and is ordered roughly by dependency (UI quick wins first, schema/data work last).

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

| # | Title | Refine.md items | Size | Depends on |
| --- | --- | --- | --- | --- |
| M1 | NavBar + Feed quick action | NavBar items 1-3; Feed item 1 | S | — |
| M2 | Gyms page | Gyms items 1-4 | S | — |
| M3 | Settings page | Settings items 1-3 | S | — |
| M4 | Workout / Editor rework | Workout items 1-2; Editor items 1-4 | M | M1 (tab icons) |
| M5 | History calendar | History items 1-2 | S/M | — |
| M6 | Input validation | Features/Inputs 1-2 | M | touches M2/M4 forms |
| M7 | Multiplier model | Multiplier items 1-2 | L | — |
| M8 | User-defined Feed graphs | Feed item 2 | L | — |

S = few files + tests. M = moderate, several files producing tests. L = schema/data-model or new feature surface.

Execution note: M2's gym dialog and M4/M6 all touch forms — do M6's shared validators before M2 to avoid building the dialog twice. If M2 ships first, import the shared validators when M6 lands.

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

- [ ] `feed_page.dart:129-133`: wrap the button in a `BlocBuilder<WorkoutCubit, WorkoutState>`; show **only when `state.isInProgress == false`** (i.e. "no activity yet"). When `isInProgress`, the tab itself plus its header suffice, so hide.
- Keep the Progression card as-is.

### Tests

- [ ] `tracker/test/widget_test.dart` currently asserts `find.text('Go to Current Workout')` (line 57): update label expectations (tab 'Workout') and add a gated test: each `BlocProvider(value: WorkoutCubit())` idle shows the button; after `cubit.startWorkout` the text is absent.
- [ ] Keep `HomePageSingleton.tabMap` test-level if any.
- [ ] Check `milestone8_test.dart` doesn't reference the tab label.

---

## M2 — Gyms page

Scope: four Refine Gyms items + the multiplier input hardening that M6 will rely upon.

- [ ] First gym is always baseline
  - In `_addGym` (`gyms_page.dart:42-56`): when the fetch of all gyms returns empty, create the new `Gym` with `isPrimary: true` (multiplier stays 1.0). No other cascade needed (multi-primary prohibition only needs UI guard).
  - `promptGym` limits unrelated.
- [ ] No two gyms with the same name (and description) ignoring case + "fluff"
  - Normalize = trim + collapse internal whitespace + lowercase. Apply on name and on `description ?? ''`.
  - On save in `_editGymDialog` save handler (265-278): compare against all gyms from `repo.gyms.getAll()`, except the one being edited (by `id`). Duplicate → inline red error text (or snack) "A gym with this name already exists", do not save. This is pure, so extract a helper `bool sameGymName(a, b)` in the page or a small util → unit-testable.
  - "fluff" = repeated/edge whitespace differences; ignore description too for "exact same name and descriptions".
- [ ] Clicking a gym enters the edit page
  - Give `_GymTile`'s `ListTile` an `onTap` → `_editGym(gym)` (same handler the popup-menu 'Edit' uses). Could become a full `GymEditPage` route via `pushTo` (matches app pattern) so validation surfaces cleanly; simplest now is to reuse `_editGymDialog` and add inline error text. Choose the dialog to keep the milestone small.
- [ ] Remove "Edit" from the 3-dot menu
  - Delete the `'edit'` branch (gyms_page.dart: trails) and its `PopupMenuItem` so the menu shows Set-as-primary / Estimate / Delete only.

### Tests

- [ ] `test/gyms_test.dart` (or extend existing): first gym is primary; duplicate name (case/space variants) rejected; non-primary can be estimated only after a primary exists.
- [ ] `gymsPage` test using a seeded repository; keep Isar fixtures used by current persistence tests.

---

## M3 — Settings page

Scope: the design overload on Settings.

- [ ] "Units" → a dropdown
  - Replace the tap-to-`SimpleDialog` (`settings_page.dart:125-142`) with an inline `DropdownButtonFormField<WeightUnit>` (or `ListTile` with trailing `DropdownButton`, or a `PopUpMenuButton`) — per "dropdown" phrasing. Keep the current `state.unit` read. Show label "Units", value `state.unit.symbol` → `setUnit`.
  - Simplify: default `WeightUnit.kilograms`.
- [ ] Remove "Profile" option
  - Remove the Profile card (lines 30-37) + `_editProfile` (86-123).
  - Delete `displayName`/`email` from `SettingsState` (cubit lines 15-19), `saveProfile` (75-77), and stop writing them in `toJson` (37-42). `fromJson` must stay tolerant of old stored JSON (one-arg fields with defaults already gives that; simply don't read them).
  - Confirm: `settings_cubit_test`/persistence tests updated accordingly (milestone8_test, settings_test).
  - Placeholder remains in hydrated storage; no migration needed.
- [ ] Boolean options inline
  - Replace `_confirmToggle` dialogs (settings_page.dart:177-205) with real inline `SwitchListTile`s in the card (leading icon, title, `value:`, `onChanged: → setNotificationsEnabled/...`). Remove the dialog + `_buildSettingsCard`'s `trailing` chevron for booleans.
  - "Privacy & Security" becomes a normal switch titled inline (analytics sharing), not a thin dialog.

### Tests

- [ ] Unit test `SettingsState.fromJson` keeps old keys absent; widget test taps switches inline (no dialog popped).

---

## M4 — Workout / Editor rework

Addresses the page-structure confusion. Two distinct jobs: (A) splits list as the entry point to start workouts; (B) the split editor.

### Workout tab (splits list)

- [ ] List of all splits with days — this **exists** (`BuildMaterialSplit`, workout_page.dart:122-173): header + day tiles, which open `SplitDayPage` ⇒ satisfies "click a split day to start that day" already. Remaining polish:
  - Show exercise **names** (not `exerciseId` ints) in the day subtitle: load the names map in `_WorkoutPageState` (like `SplitDayPage._load`) and render names. (workout_page.dart:204).
- [ ] "Start Workout" button placement — configurable (Before / After / Delete)
  - Add a setting to `SettingsState`: e.g. `enum FreeStartPlacement { before, after, disabled }` (default `before` to preserve behavior, or `after`; pick default = `before`).
  - In `_WorkoutPageState.build` read it via `SettingsCubit` and place/hide `BuildStartWorkoutButton` accordingly (workout_page.dart:50-57).

### Editor

- [ ] Remove "Start Workout" button — In this milestone the free-form Start button already lives on the splits list, not in the editor — after (2) with `placement: disabled` the user can drop it entirely, which satisfies "Remove the Start Workout button" as a user-selectable choice (see [Ambiguities](#ambiguities)).
- [ ] Rework the editor UI: keep structure but:
  - Title field required inline error (no snackbar-only) — from M6 pattern.
  - Keep day cards with enter/remove; add day count.
  - Day empty today shows "No days yet — add one below".
- [ ] Delete split INSIDE the edit page, at the end
  - In `SplitEditorPage` for an existing split (`widget.split != null`), render a `TextButton`/`FilledButton.tonal` "Delete split" at the bottom of the column (after the day list). On confirm → `repo.splits.delete(split.id)` then `Navigator.pop()`. For new splits hide the button. This replaces the need for delete-only-popup.
- [ ] Suggest popular splits (PPL / BroSplit / UL / FB)
  - Add a `"Use a template"` affordance on `SplitEditorPage` (header action or an outlined button next to "Add day").
  - Templates data: const maps like `{ 'PPL': { title: 'PPL', days: ['Push', 'Pull', 'Legs'] }, UL: [Upper, Lower], FB: [Full Body], BroSplit: [Chest, Back, Legs] }` (BroSplit cheats). All in `lib/models/workout_split_templates.dart` (pure const, testable).
  - Applying a template **prefills day names** (creates `WorkoutSplitDay`s with `title`, order, no exercises; user fills exercise later). Recipe: template → replace `_days` in the editor with those day scaffolds, then the user edits each day. If the split isn't saving in-progress state, apply-on-edit works on the in-memory `_days`.

### Tests

- [ ] Template list: assert 4 templates, each ≥1 day.
- [ ] Split editor: delete renders only when editing existing; template pick sets `_days`.
- [ ] Workout list: after disabling the setting, no `Start Workout` button; day subtitle shows names.

---

## M5 — History calendar

- [ ] Make the calendar more compact
  - `calendar_grid.dart` (116-124) starts with a `GridView.count(crossAxisCount: 7, childAspectRatio: ~0.9)` instead of the default tall/large cells.
  - Cull per-cell vertical budget: cell `margin: all(2)` → `all(1)` (line 144), day-number style to `bodySmall`, dot from 5×5 → 4×4 or inline dot, gap 2→0 (lines 155-162).
  - Trim the `_MetricsStrip` (265-284) — compress "Workout days / git streak" into compact chips or one line. (Optional alternative: replace with a single-line cohesion row.)
- [ ] No scrolling to see workouts of a day
  - The inline day-list pushes grid off-screen today. Reorder so both are visible without page scroll:
  - **Option A (chosen default):** Pin the calendar widget to a fixed viewport area: grid + a bounded "Workouts · <date>" panel below it. The day list becomes a `ListView` inside a fixed-height region (about two tiles) with `shrinkWrap`/internal scrolling — grid always visible, long days scroll within the panel, no page scroll needed.
  - **Option B:** Show the day's workouts in a `showModalBottomSheet`/`DraggableScrollableSheet` on tap instead of inline. Simpler, but loses the at-a-glance empty-state and adds a tap-to-open step.
  - Keep the grid on top; the page-level `CustomScrollView` (history_page.dart:55) stays the only page scroll.
  - `CalendarGrid`/`currentStreak` math (pure in `calendar_grid.dart`) is untouched by the visual compaction.

### Tests

- [ ] Grid still marks a day that has workouts; reduced-size helpers unit tests; the no-scroll behavior is confirmed by empty_grid.

---

## M6 — Input validation everywhere

Thorough pass on every free text / numeric input.

### Validation layer

- [ ] New small util file `lib/pages/custom/form_validators.dart`:
  - `requiredText(String? v, {String msg = 'Required'})`
  - `requiredDouble(...)` → message "Must be greater than X"
  - Message formats: `"Cannot be empty"`, `"Must be greater than 0"`.

### Apply

- [ ] Gym dialog name (+ dupe normalize from M2), multiplier → `>0`: errorText under fields, disable Save until valid.
- [ ] SplitEditor title (replaces snackbar-only, new_split_page.dart:89-95); description multi-line (see below); day title.
- Profile removed in M3.
- [ ] `NewExercisePage` already uses a `Form` + `validator` (new_exercise_page.dart:82-90); keep it, it's the reference pattern to extend.
- [ ] `CurrentWorkoutPage._AddSetForm` weight + reps numeric: add inline `errorText` & disable "log set" when empty/≤0 (current does the storage; check).

### Auto-expanding description boxes — "1 line, growing as you type"

- [ ] Change the following `TextField` with fixed lines → `minLines: 1, maxLines: null` (growing): split description (new_split_page.dart:150-157), day description (split_day_editor_page.dart:114-121), exercise description (new_exercise_page.dart:92-99). Gym description (dialog same).
- [ ] Flutter's default `textFieldSizeCap` cap prevents unbounded; set `maxLines: null` + `keyboardType: TextInputType.multiline`.

### Tests

- [ ] Validator unit tests; widget test priority: blocked save blocks save / shows text; title save-bounciness removed.

---

## M7 — Weight multipliers per movement/equipment, time-adapted

Replaces the global gym multiplier concept with per-machine/movement estimates that self-update.

### Data check

Already sufficient: `WorkoutSession { gymId, startTime }` + `WorkoutSet { exerciseId, weight, reps, type }` + `Exercise { movementPattern, equipment, muscles }` — everything needed for per-exercise, date-weighted estimation already persists.

### Design (two-track)

- [ ] Model/basic UI (schema-light)
  - Extend the estimate to per-exercise with a movement fallback: add a `Map<int, double> perExerciseMultipliers` on `Gym` in addition to `multiplier` (the global fallback stays for safety). Manual display in gym editor: "×1.2 …" list of per-machine multiplic.
  - Isar change → `dart run build_runner build` + regenerated `.dart`; schema version migration needed (Isar handles internally, but CI drifts must pass).
- [ ] Time-aware auto-estimation
  - Replace/augment `estimateGymMultiplier` in analytics (258-286): for each shared exercise pair (gym A primary, gym B): compute windowed ratio with **exponential/linear time-decay** — weights from recent sessions dominate. Moving-average window e.g. last-M sessions, then median across exercises; fall back to movement-group median when no shared exercise; does not require identical dates.
  - Automatic re-estimation: after each session in a new gym (`endWorkout`), update the best-estimated multipliers for that gym (cheap; pure function + repo put — same as current manual estimate, but hook `endWorkout` or page-visit compute).
- [ ] UI: Gyms page per-gym shows "Auto (movement-based)" value; "Auto-estimate" button per-gym recomputes all; confirm.
- [ ] `normalizedWeight` signature evolves: `(raw, multipliers, gymId, exerciseId)` so it can apply the per-exercise override first, then the fallback gym multiplier.

### Effort note

This is the largest milestone — schema + analytics + models change. Plan a spike on Isar map persistence and drift checks. Keep Math pure and unit-tested (median, decay) in `analytics_test.dart`.

### Tests

- [ ] Pure-function tests for per-exercise/movement estimation with simulated cold data (recent-heavy weights → ratio ≈ expected); migration smoke test.

---

## M8 — User-defined graphs (Feed)

### Shape

- [ ] Feed keeps "Recent activity"; add an "Analytics" section header + "＋ Add graph" button (feed_page.dart:117-135 area).
- [ ] A graph = config row `{ title, exerciseId (or all), metric (best-1RM | peak weight | volume), timeframe }`, rendered via existing `LineChart` (`lib/pages/custom/line_chart.dart`) using `AnalyticsService.snapshot`-style data (series per exercise; `exerciseBest1rm`, `exercisePeakWeight`, `volumeTrend`).
- [ ] Persistence: since it is per-user prefs to the feed, extend `SettingsState` with `List<GraphConfig> graphs` (copyWith/toJson/fromJson), so it hydrates without a new table. (`Settings` is a HydratedCubit — fits.)
- [ ] `AnalyticsService` already has snapshot/memoization; add point-series per config.
- [ ] Feed page: after recent-activity list, `for (final g in configs) _GraphCard(config)` each with `LineChart`; plus remove/edit.

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
