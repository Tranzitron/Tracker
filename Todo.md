# TODO — Fitness Tracker (product completion)

Breakdown of tasks and checkpoints to ship a complete product. Tasks are grouped into **milestones**; each milestone ends with verifiable **checkpoints**. Items reference the product spec in [`Plan.md`](Plan.md) (section numbers like `2.1`) and the current codebase state.

Legend:
- `STATUS`: `[ ]` not started · `[ ] (in progress)` actively being worked · `[x]` done

---

## Milestone 0 — Foundation cleanup (pre-requisite)

Fix the scaffold so the rest builds on solid ground. No new features.

- [x] Create `CLAUDE.md` + project understanding
- [x] Fix case-mismatch import in `lib/main.dart` (`package:tracker/Models/exercise.dart` → `models/exercise.dart`); currently resolves only via case-insensitive macOS path, breaks on Linux CI
- [x] Replace the outdated counter `test/widget_test.dart` with a smoke test that actually matches the app (builds `MyApp`, finds the bottom nav tabs)
- [x] Decide & document commit hygiene for generated/platform files (`tracker/ios/Podfile.lock`, `tracker/build/`, `.DS_Store`); update `.gitignore` accordingly
- [x] **Checkpoint 0**: `flutter analyze` clean from a fresh `flutter pub get` on CI (`dart.yml`), and the existing app boots on one desktop target

---

## Milestone 1 — Data layer (Isar domain model + repository)

Currently `Exercise` and `WorkoutSplit` are Isar `@collection` models, but the DB (`DbInstance.getIsar`) is **not wired into any page** and splits shown are hardcoded sample data. Build the full persistence foundation.

- [x] Design the complete Isar schema for the full domain: extend `Exercise` (add `ExerciseItem`/variation model — replaces the `List<int>` placeholder in `WorkoutSplitDay` per the `TODO create ExerciseItem model` comment), add `WorkoutSession` + `Set` (weight, reps, `@enumerated` warmup flag — see `2.1`), `Gym` profile (`2.2`), muscle groups & movement patterns (`1.4.1`), units
- [x] Add a **repository/service layer** that owns all Isar queries so pages never touch `Isar` directly; the `WorkoutCubit` should hold a reference instead of reading the DB itself
- [x] Wire the Isar DB into app startup and dependency-inject it (extend the `MultiBlocProvider`/`DbInstance` setup in `main.dart`)
- [x] Add an **exercise seed library** (a curated set of exercises with muscle/equipment defaults) and a `muscle.dart`-driven categorization model (`1.4`)
- [x] Add comment block + positional note for `dart run build_runner build` (document the codegen workflow near the models; `.g.dart` files are generated — never edit by hand)
- [x] **Checkpoint 1**: create/read/update/delete of every new model works via the repository; a widget test persists a session and reads it back; `build_runner` regenerates cleanly

> **Note (Milestone 1)**: the full `flutter build macos --debug` fails to compile due to a **third-party** dependency incompatibility — `jni`/`jni_util` (pulled transitively by `path_provider_android` → Isar) at their latest published versions (1.0.3/1.0.0) don't compile on the local Flutter 3.41 / Dart 3.11 SDK. None of the Milestone 1 source is involved (`flutter analyze` clean, all `flutter test` green, `build_runner` clean). CI pins Flutter 3.29.x where this tree resolves; to rebuild the app locally, align to the pinned Flutter or add a `dependency_overrides`/upgrade path for `jni`. Also note a host-side Isar test artifact `libisar.dylib` was copied to `tracker/` (gitignored) so `flutter test` can load the native lib.

---

## Milestone 2 — Navigation & app shell finalization

`home_page.dart` per README's plan: tabs should be **Home(Feed) · History · CurrentWorkout · WorkoutsEditor · Exercices**, with Settings as a child of Feed.

- [ ] Fix `home_page.dart` tab wiring: tab 2 and 3 both currently build `WorkoutPage`; give the workout/editor tabs distinct pages and add the **Current Workout** destination (README's open todo)
- [ ] Move **Settings** into the Feed tab as a child page (`SettingsPage` exists at `lib/pages/settings_page.dart` but is not wired into `home_page.dart`); standardize back button via `CustomAppBar`/`pushTo` (`1.5`)
- [ ] Audit & consolidate the tab-index bookkeeping (`HomePageSingleton`/`BiMap`, `_navigatorKeys`) — remove the singleton if imperative `changeTab` calls are no longer needed
- [ ] Apply the standard `CustomAppBar` + `pushTo` slide navigation consistently across all screens
- [ ] **Checkpoint 2**: every top-level nav path resolves to a real (non-placeholder) screen; switching tabs preserves each tab's nav stack and state

---

## Milestone 3 — Core workout logging (active session)

Implements the heart of the app: the active workout tracker.

- [ ] Build the **active-workout screen** (`CurrentWorkout`): list the split's exercises for today, log sets with weight/reps, and display them inline
- [ ] **Warmup support** (`2.1`): flag sets as warmup with a distinct UI indicator; exclude warmup sets from analytics/volume/1RM later
- [ ] **Gym selection** on workout start (`2.2`): prompt to choose a gym when >1 gym profile exists; store the session's gym for history + equivalence
- [ ] Replace the placeholder split-tile navigation (`Text('restart if stuck in fake workout')`) and hardcoded splits in `workout_page.dart` with repository-loaded data
- [ ] Persist completed workouts as `WorkoutSession` records (not just the hydrated `WorkoutState`); evolve/retire the cubit's `startTime`/`completedExercises` bookkeeping so real sessions drive it
- [ ] **Checkpoint 3**: start → select gym → log working + warmup sets → end workout → session appears in history with correct gym, sets, and duration

---

## Milestone 4 — Exercises & splits management (`1.3`, `1.4`)

- [ ] **Exercises library** (`1.4`): category view browsed by muscle group/movement pattern; exercise detail view (`1.4.1.1`); custom exercise creation
- [ ] **Split editor** (`1.3.1`): finish `NewSplitPage` stub (`Text('asdasd')`) into a real split CRUD editor
- [ ] **Split day editor** (`1.3.1.1`): configure days within a split
- [ ] **Split day exercises editor** (`1.3.1.1.1`): add/remove/reorder exercises for a day; introduce `ExerciseItem` ordering model (replaces the `List<int>` placeholder)
- [ ] **Checkpoint 4**: user can create an exercise, create a split, add days, add/reorder exercises, and the workout screen reflects the edited split

---

## Milestone 5 — History & calendar (`1.2`, `2.5`)

- [ ] **History overview** (`1.2`): list past logged workouts with dates and historical performance; view a session's full sets from history
- [ ] **Calendar view** (`2.5`): interactive calendar of workout days with frequency/consistency metrics and quick links to past session logs
- [ ] **Checkpoint 5**: any completed workout is reachable from both history and the calendar; calendar marks workout days and shows consistency

---

## Milestone 6 — Analytics, multipliers & progression (`2.3`, `2.4`)

The most advanced feature set — analytics that normalize across machines.

- [ ] **Per-exercise historical stats & graphs** (`1.4.1.1`): weight/reps over time, performance logs
- [ ] **Machine weight equivalence & multipliers** (`2.3`): define a primary home-gym machine as baseline (multiplier 1.0); estimate trendlines to auto-calc equivalence multipliers for secondary machines; allow manual override
- [ ] **Normalized progression analytics** (`2.4`): normalize performance across machines/equipment to a standard effort scale; aggregate identical movements across brands onto unified charts
- [ ] **General progression graphing** (`2.4`): plot overall strength, volume trends, and trajectory over time; compute 1RM estimates and peak volume respecting warmup exclusions (`2.1`)
- [ ] **Checkpoint 6**: logging the same movement on two machines with different multipliers yields a unified, normalized chart; 1RM/progression figures exclude warmup sets

---

## Milestone 7 — Feed, settings & app polish (`1.1`, `1.5`)

- [ ] **Feed** (`1.1`): activity stream of recent accomplishments and personal updates (replaces the bare `FeedPage` shell)
- [ ] **Settings** (`1.5`): user profile, units (kg/lbs) with consistent formatting everywhere, gym configuration, general app settings; make the `SettingsPage` snackbar placeholders real
- [ ] Units & formatting: ensure kg/lbs and weight/plate math are used consistently across all screens
- [ ] Empty/loading/error states, theme polish (Material 3 light/dark already wired in `main.dart`), and animation consistency via `CustomAppBar`/`pushTo`
- [ ] **Checkpoint 7**: full app walk-through on a supported desktop platform with no placeholder UI remaining

---

## Milestone 8 — QA, testing & release

- [ ] Expand widget/unit tests: repository, cubit (incl. hydrated persistence), and key screen flows
- [ ] Manual test matrix on all supported platforms (iOS/Android/macOS/Windows/Linux present in repo) incl. the fix from Milestone 0 for case-insensitive imports
- [ ] Review CI: `dart.yml` currently runs only `flutter analyze`; add a `flutter test` job and consider `build_runner` codegen validation in CI
- [ ] Configure app metadata, icons, and app display names for each platform; prepare store listing
- [ ] **Checkpoint 8**: green CI (analyze + test), release build succeeds on each platform, and app passes the full manual test matrix

---

## Cross-cutting / ephemeral notes

### Commit hygiene (decided in Milestone 0)
- `tracker/ios/Podfile.lock` is **kept committed** — CocoaPods app best practice keeps the lockfile for reproducible iOS builds.
- `tracker/build/` is gitignored (root `build/` pattern + `tracker/.gitignore` `/build/`); never commit build artifacts.
- `.DS_Store` / macOS junk added to root `.gitignore` (already present in `tracker/.gitignore`).
- `linux/` + `windows/` `generated_plugin_registrant.*` and `generated_plugins.cmake` are regenerated on `flutter pub get` and **are meant to be committed** — expect them to show as modified after dependency changes.



- Codegen: after any change to `@collection`/`@embedded`/`@enumerated` annotations, run `cd tracker && dart run build_runner build`. Generated `*.g.dart` files are excluded from the analyzer and must not be hand-edited.
- State currently survives restarts via `HydratedBloc` (JSON storage dir set up in `main.dart`). Once real `WorkoutSession` records land, reconcile what hydrated state should still cache vs. what belongs in Isar.
- The existing `test/widget_test.dart` is stale (counter smoke test). Replace it early (Milestone 0) so later tests don't build on it.