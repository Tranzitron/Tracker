# ForUI Migration — Checklist

Plan: `~/.claude/plans/make-a-plan-on-starry-origami.md`
A phase counts done only when committed.

## Phases

- [x] Phase 0 — Unblock: repair corrupted import in `new_split_page.dart`
- [x] Phase 1 — Theme bridge: `toApproximateMaterialTheme()` in `main.dart`
- [x] Phase 2 — Custom widgets on FTheme (`line_chart`, `custom_route`, `custom_app_bar`)
- [x] Phase 3 — Form controls (`exercise_picker`, `new_exercise`, `split_day_editor`, `new_split`, `gyms_page`, `graph_editor`, `workout_page`)
- [ ] Phase 4 — Overlays (dialogs → `showFDialog`, snackbars → toasts, sheet, popover menus)
- [ ] Phase 5 — Structure widgets (cards/items, `FTabs`, `FAccordion`, `FSwitch`, color tokens)
- [ ] Phase 6 — Icons (`Icons.*` → `FLucideIcons.*`)
- [ ] Phase 7 — Tests (pumpApp, finder updates)
- [ ] Phase 8 — Cleanup + CI (unused imports, `dart fix` + format, full verification)
- [ ] Final verification — analyze clean, full test suite green, manual walkthrough (5 tabs, both brightnesses, dialog return values)

## Deviations

- Phase 0: the plan's Phase 8 unused-import removal (`forui` in `new_split_page.dart`) done early so the analyze gate is clean. Prior uncommitted conversion work (bottom nav, cards, buttons across ~14 files) landed in the Phase 0 commit per plan risk note "commit uncommitted conversion work first".
- Phase 1: `FThemeData.toApproximateMaterialTheme()` (forui 0.26) returns `material_ui`'s `ThemeData` — a distinct type from the Flutter SDK `ThemeData` that the SDK `MaterialApp.theme` expects (verified with a minimal probe; forui's own example app roots in `material_ui.MaterialApp`). Switching the app root to `material_ui` was judged out of scope. Instead, `main.dart` adds a `_FThemeMaterialBridge.toSdkMaterialTheme()` extension mapping `FColors` onto the SDK `ColorScheme` (plus scaffold/divider colors), preserving the phase's goal: Material widgets inherit the Forui palette.
- Phase 2: Forui 0.26 typography is `typography.body.<size>` / `typography.display.<size>` (`FTypeface` scales xs3–xl8), not flat `textTheme.bodySmall` — Material `bodySmall` mapped to `typography.body.xs`. `custom_app_bar.dart` has no `Theme.of` reads (already converted); the explicit ghost back-button `leading:` is deferred to Phase 6 per the plan's "once icons migrate".
- Phase 3: API notes — `FTextField` takes text changes via `control: FTextFieldControl.managed(controller:, onChange:)` (no top-level `onChanged`); `error:` is a `Widget?`; `FSelect` uses `items: Map<String, T>` + `FSelectControl<T>.lifted`; multi-select uses `FSelectGroup` + `FSelectGroupItemMixin.checkbox` (no public `FSelectGroupItem` class). The workout_test UI test was repointed to `pumpApp()` + nav-bar `onChange(2)` (Phase 7's pattern, pulled forward: FTextField/FCheckbox require the Forui scope the old bare-`MaterialApp` harness lacked); its `setUp` switched to `InMemoryStorage()` (real `HydratedStorage` deadlocks the fake-async pump, per test_helpers docs) and the `addTearDown(cubit.close)` on the pumpApp cubit was dropped — closing a pumped HydratedCubit hangs the fake-async teardown (app_test never closes either). Material `FilterChip` → `FCheckbox` / `FSelectGroup` checkbox items; warm-up badge `Colors.tertiary` mapped to `colors.secondary`.

## Blockers