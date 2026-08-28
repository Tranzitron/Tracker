# ForUI Migration — Checklist

Plan: `~/.claude/plans/make-a-plan-on-starry-origami.md`
A phase counts done only when committed.

## Phases

- [x] Phase 0 — Unblock: repair corrupted import in `new_split_page.dart`
- [ ] Phase 1 — Theme bridge: `toApproximateMaterialTheme()` in `main.dart`
- [ ] Phase 2 — Custom widgets on FTheme (`line_chart`, `custom_route`, `custom_app_bar`)
- [ ] Phase 3 — Form controls (`exercise_picker`, `new_exercise`, `split_day_editor`, `new_split`, `gyms_page`, `graph_editor`, `workout_page`)
- [ ] Phase 4 — Overlays (dialogs → `showFDialog`, snackbars → toasts, sheet, popover menus)
- [ ] Phase 5 — Structure widgets (cards/items, `FTabs`, `FAccordion`, `FSwitch`, color tokens)
- [ ] Phase 6 — Icons (`Icons.*` → `FLucideIcons.*`)
- [ ] Phase 7 — Tests (pumpApp, finder updates)
- [ ] Phase 8 — Cleanup + CI (unused imports, `dart fix` + format, full verification)
- [ ] Final verification — analyze clean, full test suite green, manual walkthrough (5 tabs, both brightnesses, dialog return values)

## Deviations

- Phase 0: the plan's Phase 8 unused-import removal (`forui` in `new_split_page.dart`) done early so the analyze gate is clean. Prior uncommitted conversion work (bottom nav, cards, buttons across ~14 files) landed in the Phase 0 commit per plan risk note "commit uncommitted conversion work first".

## Blockers