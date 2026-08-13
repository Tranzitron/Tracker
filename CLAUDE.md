# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A cross-platform (iOS/Android/macOS/Windows/Linux) Flutter workout-tracking app. The Flutter app lives in `tracker/`; the repository root also contains a PowerShell script for running GitHub Actions locally. This is an early-stage work in progress — much of the UI is placeholder scaffolding.

## Commands

The Dart/Flutter app is rooted in `tracker/`; run Flutter/Dart commands from that directory.

```bash
# Install dependencies
cd tracker && flutter pub get

# Static analysis (this is what CI runs)
cd tracker && flutter analyze

# Run tests (single test: `flutter test test/widget_test.dart`)
cd tracker && flutter test

# Regenerate code from Isar/JsonSerializable annotations
cd tracker && dart run build_runner build
```

The only route in the tree is a default `flutter test`; the existing `test/widget_test.dart` is the boilerplate counter-smoke-test and is **outdated** — it does not match the current app (no counter exists). CI (`dart.yml`) runs `flutter pub get` + `flutter analyze` on `ubuntu-latest` with Flutter 3.29.x; it does not run tests.

## Architecture

The app uses **Isar** for local persistence and **Bloc (flutter_bloc + HydratedBloc)** for state management.

**State management**
- `WorkoutCubit` (`lib/pages/workout/workout_cubit.dart`) is the sole cubit. It is a `HydratedCubit<WorkoutState>` — state is JSON-serialized and persisted via `HydratedStorage` to the app-documents directory (set up in `main.dart`). Consequence: the in-progress workout survives app restarts automatically.
- `WorkoutState` is a hand-written plain class with manual `toJson`/`fromJson` (no codegen). It holds `isInProgress`, `startTime`, gym id/name (`gymId`/`gymName`), an optional plan (`planTitle` + `List<PlanExercise>`), and `List<ActiveSet> sets` (the sets logged so far). Idle is the default (`initial()`). Active-set helper types `ActiveSet` / `PlanExercise` are serializable; `ActiveSet.isWarmup` flags `SetType.warmup` (from `workout_set.dart`) for a warm-up indicator.
- **Logging flow**: `startWorkout`/`startPlanWorkout` begin a session (optionally with a split-day plan); `logSet`/`removeSet` mutate the ordered set list; `endWorkout` (async) writes a real `WorkoutSession` to Isar (sets + gym + duration = now−start) via its `TrackerRepository` reference, then resets to idle. Hydrated state caches only the *in-progress* session; completed records live in Isar.
- The cubit holds an optional `TrackerRepository` reference and never opens its own DB connection.
- The cubit is provided app-wide in `main.dart` via `MultiBlocProvider` with `lazy: false`.

**Persistence (Isar) & data layer**
- Isar `@collection` models live in `lib/models/`: `Exercise`, `WorkoutSplit` (with `@embedded` `WorkoutSplitDay` → `@embedded` `ExerciseItem`, which holds `exerciseId` + per-slot guidance), `Gym` (includes a `multiplier` for future machine equivalence), `WorkoutSession` (with `@embedded` `WorkoutSet`, whose `@enumerated SetType` flags warmup). `Exercise` uses `@enumerated` muscle lists plus `@enumerated MovementPattern` and `Equipment` enums. `Muscle`/`MuscleGroup` live in `lib/models/muscle.dart`.
- **Repository layer** (`lib/data/`): pages and cubits never touch `Isar` directly. Each entity has a repository (`ExerciseRepository`, `GymRepository`, `WorkoutSplitRepository`, `WorkoutSessionRepository`, all in `lib/data/repositories.dart`), bundled into a `TrackerRepository` facade. `DbInstance.getIsar` (`lib/data/db.dart`) opens the single instance; it is constructed and injected in `main.dart` and exposed down the tree via the `RepositoryScope` `InheritedWidget` (`lib/data/repository_scope.dart`). `WorkoutCubit` holds an optional `TrackerRepository` reference. Exercise seeding lives in `lib/data/seed.dart`, run on first launch when the table is empty.
- The **`.g.dart` files are generated** — do not edit them by hand. After changing a `@collection`/`@embedded`/`@enumerated` annotation, run `dart run build_runner build` in `tracker/`. The analyzer excludes `*.g.dart`. (Isar 3.1 requires `@enumerated` enum fields to be non-nullable and models must not carry computed getters — the generator rejects both.)
- Host-side `flutter test` needs the Isar native lib: `libisar.dylib` is copied into `tracker/` (gitignored) so tests load it.

**Navigation & UI shell**
- `lib/home_page.dart` implements a 5-tab bottom `NavigationBar` using **nested `Navigator`s** via an `Offstage` `Stack` (`_buildOffstageNavigator`) — each tab keeps its own navigation stack so state survives tab switches. Tabs: Feed(0), History(1), CurrentWorkout(2), Editor/Workout(3), Exercises(4). A `HomePageSingleton` (with a `BiMap<TabName,int>` + `TabName` enum) bridges imperative `changeTab` calls from child pages (e.g. the Feed button and `SplitDayPage` after starting a plan workout).
- `CurrentWorkoutPage` (`lib/pages/workout/current_workout_page.dart`) drives the active session from `WorkoutCubit`: idle → Start (with `promptGym` gym selection, `lib/pages/workout/gym_picker.dart`); in progress → a session header plus one card per plan exercise with an inline weight/reps/warm-up add-set form and per-set remove, ending with a confirm dialog that calls `cubit.endWorkout` (writes the `WorkoutSession`). Sets render a `W` warm-up chip vs `S` working chip. With no plan a free-form panel offers an exercise dropdown. It reads the repository via `RepositoryScope.maybeOf` (nullable) so it degrades gracefully in tests.
- `WorkoutPage` is the splits editor — it loads splits reactively from `repo.splits.watchAll()` and a split-day tile opens `SplitDayPage` (`lib/pages/workout/split_day_page.dart`), a real detail screen that lists the day's exercises and can start that workout as the current plan. `NewSplitPage` is still a stub (Milestone 4).
- `HistoryPage` lists persisted `WorkoutSession` records (title, date, gym, set count, duration) via `repo.sessions.watchAll()` — the full per-session/calendar view is Milestone 5.
- **`CustomAppBar`** (`lib/pages/custom/custom_app_bar.dart`) is the standardized pinned `SliverAppBar` used by screens. It takes a title and an optional record-typed `actionButton: ({String title, VoidCallback onPressed})?`.
- **`pushTo`** (`lib/pages/custom/custom_route.dart`) is the app's slide-transition page push; use it instead of bare `Navigator.push` for consistency. Screens commonly use `CustomScrollView` + `SliverFillRemaining`.

**Placeholder/known-incomplete code** (present in the scaffold, not implemented):
- `lib/pages/workout/new_split_page.dart`: the "New Split" screen is a stub (`Text('asdasd')` + a field) awaiting Milestone 4.
- `ExercisesPage` is an empty-state shell awaiting Milestone 4. `HistoryPage` has a working session list but its full detail + calendar views await Milestone 5.
- `HistoryPage` per-session detail and setting pages' snackbar placeholders are still to be built (Milestones 5/7).
- Hardware directories (`ios/`, `android/`, `macos/`, `windows/`, `linux/`) are stock Flutter platform runners; `tracker/ios/Podfile.lock` and `build/` are committed and may be stale.

## README (planning notes)

The README records intended refactors/features, not current behavior; several are now done: **Settings is a child page of Feed** (via the Feed app-bar action → `pushTo(SettingsPage)`) and the **Current Workout** destination exists as tab 2. The intended bottom-bar layout (Home, History, CurrentWorkout, WorkoutsEditor, Exercices) is implemented.

## Running GitHub Actions locally (repo root)

`run-github-actions-locally.ps1` is a cross-platform (Windows/macOS/Linux) PowerShell script that ensures an Internet connection, then installs (if needed) the `act` CLI (nektos/act) and Docker, starts Docker Desktop/systemctl, then runs the GitHub Actions workflow locally. It self-elevates via `sudo`/RunAs. macOS support is partial and untested. Run as: `pwsh run-github-actions-locally.ps1`.