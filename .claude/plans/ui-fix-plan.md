# UI Fix Plan — Visual QA Sweep 2026-08-30

Source: QA inspection of all 66 screenshots in `tracker/build/test_screenshots/` (22 screens × 320×568 / 800×600 / 1280×720), produced by `pwsh run-visual-tests.ps1`. Fix decisions below were chosen collaboratively; excluded options are recorded at the end.

**Verification protocol for every batch:** re-run `pwsh run-visual-tests.ps1`, inspect the changed captures (Read the PNGs; `manifest.json` maps files to screens), then `cd tracker && flutter analyze && flutter test`. Batches are High → Medium → Low; do not start the next batch until the current gate passes.

---

## Batch 1 — High severity

### 1. Pushed pages render on a black body (Visual Bug, ~30 captures affected)
- **Files:** `007_settings-page`, `008_gyms-page`, `009_progression-page`, `010_new-exercise-page`, `011_exercise-detail-page`, `012_session-detail-page`, `013_split-editor-new`, `014_split-editor-edit`, `015_split-day-editor`, `016_split-day-page` (all sizes).
- **Root cause:** `pushTo` (`lib/pages/custom/custom_route.dart:8`) computes `context.theme.colors.background` but only assigns it to `barrierColor`, which is ignored for opaque routes. Destinations paint no background, so the body is black and forui's dark secondary text becomes near-invisible on it.
- **Chosen fix (central fix in pushTo):** wrap the destination in `ColoredBox(color: backgroundColor, child: destination)` inside `pageBuilder`. ~3 lines; fixes all 8 screens plus any future pushed page automatically.

### 2. Chart y-axis/value labels render as solid gray blocks (Visual Bug)
- **Files:** `001_feed-tab` (all sizes), `009_progression-page` (all sizes, both charts).
- **Root cause:** `LineChart` (`lib/pages/custom/line_chart.dart`) draws axis/value text as gray rectangles clipped at the left edge; no other axis labels or gridlines exist.
- **Chosen fix (paint real y-labels + gridlines):** reserve a left gutter; draw y-axis tick labels and light gridlines via `TextPainter` using theme colors; keep edge clipping safe. Applies to both the Feed progression card and the Progression page.

### 3. "Warm-up" checkbox label collapses to one letter per line (Visual Bug)
- **Files:** `004_workout-tab-in-progress@800x600.png`, `@1280x720.png`.
- **Root cause:** `FCheckbox(label: Text('Warm-up'))` at `lib/pages/workout/workout_page.dart:624` sits unconstrained in a `Row` next to `Spacer()` + `FilledButton('Add set')` — the label gets squeezed to ~1 character per line, inflating row height.
- **Chosen fix (Expanded checkbox):** wrap the `FCheckbox` in `Expanded`, drop the `Spacer`.

### 4. Calendar grid hides behind bottom nav at 1280×720 (Layout Flaw)
- **File:** `003_history-calendar@1280x720.png` — last row (day 31) fully hidden; selected-day pill clipped mid-shape and stretched ~70px tall. Fine at 320 and 800.
- **Root cause:** `HistoryCalendar` (`lib/pages/history/history_calendar.dart`) is a `SingleChildScrollView` + `Column` with no height awareness.
- **Chosen fix (fit-to-height grid):** `LayoutBuilder` sizes day cells from available viewport height: `cellHeight = (height - header - metrics) / rowCount`, clamped to min 36 / max 56px. Even 6-row months fit without clipping or scrolling.

---

## Batch 2 — Medium severity

### 5. Validation error overlaps "Use a template" button (Layout Flaw)
- **Files:** `013_split-editor-new` (all sizes). Red "cannot be empty" renders inside the button's top half; at 320 it also starts flush at x≈0, breaking the 16px margin.
- **Context:** the error is already passed via `FTextField`'s `error:` slot (`lib/pages/workout/new_split_page.dart:216`) but still collides.
- **Chosen fix (check forui error API first):** fetch current forui documentation for `FTextField` error/description layout via Context7 before touching spacing; then apply the idiomatic fix (reserve the error region's height even when null, or use the correct forui slot/typography).

### 6+7. Gym-picker sheet: heading overprints Feed page + 30px gap above nav (Visual Bug / Layout Flaw)
- **Files:** `020_gym-picker-sheet@320x568.png` / `@800x600.png` (overprint), `@800x600.png` (gap + clipped row subtitle), `@1280x720.png` (heading inside chart card bounds).
- **Root cause:** the sheet builder (`lib/pages/workout/gym_picker.dart:24-37`) returns a bare `Column` — heading and rows are not inside a real sheet container.
- **Chosen fix (rebuild as real bottom sheet):** standard `showModalBottomSheet` with themed opaque background + `SafeArea`; heading and gym rows live inside the sheet container; content sits flush on the nav. Fixes both issues together.

### 8. Warm-up "W" badge nearly invisible (Visual Bug)
- **Files:** `012_session-detail-page` (all sizes).
- **Root cause:** badge fill uses `theme.colors.secondary` (light gray on white). Same pattern in `_WarmupChip` (`lib/pages/history/session_detail_page.dart:219`) and `_WarmupBadge` (`lib/pages/workout/workout_page.dart:530`).
- **Chosen fix (contrast-safe token swap):** use `theme.colors.muted` (or equivalent muted/foreground pairing) with matching foreground text color so the badge reads on white cards.

---

## Batch 3 — Low severity

### 9. Placeholder pluralization "(s)" (Data Anomaly)
- "3 set(s)", "2 set(s)", "0 set(s)" in History/Workout headers; "2 exercise(s)" in split editor (`014`); "Log 2 set(s) and save this workout to history." in the end dialog (`021`). Feed has the opposite bug: "1 sets".
- **Chosen fix (tiny helper):** add `String plural(String noun, int n) => n == 1 ? '1 $noun' : '$n ${noun}s';` to a format util; swap the ~6 call sites (Feed, History, Workout, split editor, end-workout dialog).

### 10. App-bar title indented ~85px with no back button (Layout Flaw)
- **Files:** `005_editor-tab`, `006_exercises-tab`, `022_workout-tab-idle` (all sizes; also visible in `020` backgrounds). Title sits ~57px right of the body content margin at 1280.
- **Root cause:** `CustomAppBar` (`lib/pages/custom/custom_app_bar.dart`) puts the title in `FlexibleSpaceBar`, which centers/indents it.
- **Chosen fix (title in the Row):** drop `FlexibleSpaceBar`; render the title directly in the app bar's `Row` (conditional back button leading, action trailing) so it aligns exactly with the body margin. **Note:** this touches every screen's header — the post-batch sweep must check all captures.

### 11. Full-bleed stretch at 1280 wide (UX Concern)
- **Files:** `005`, `006`, `007`, `008`, `010`, `011`, `017` at 1280×720 — ~1250px buttons, ~620px segmented halves, ~1250px text fields, ~420px stat cards.
- **Chosen fix (shared max-width container):** new reusable `MaxWidth` widget (Center + ConstrainedBox, max ~720px), wrapped around tab bodies and pushed-page content. Mobile sizes unaffected.

### 12. Stat-card rows bulge when a label wraps (Layout Flaw)
- **Files:** `009_progression-page@320x568.png`, `011_exercise-detail-page@320x568.png` — middle "Peak volume" card taller than neighbors.
- **Chosen fix (IntrinsicHeight row):** wrap the stat-card `Row` in `IntrinsicHeight` with `crossAxisAlignment: stretch` (in `lib/pages/analytics/progression_page.dart` and `lib/pages/exercises/exercise_detail_page.dart`).

### 13. Seeded timestamps drift between capture sizes (Data Anomaly, test infra)
- `002`/`004`/`012` show 06:53/08:53 at 320×568 vs 06:54/08:54 at larger sizes — fixtures derive times from wall clock per test, breaking pixel-diff determinism.
- **Chosen fix (single captured 'now' + offsets):** capture `DateTime.now()` once (setUpAll or a top-level `final` in `test/helpers/test_fixtures.dart`) and seed all sessions as fixed offsets from it.

### 14. Unlabeled trash icon floating in end-workout dialog (UX Concern)
- **Files:** `021_end-workout-dialog` (all sizes) — large blank region with a bare red discard icon.
- **Chosen fix (icon + tooltip only):** keep the icon; add `Tooltip` + `Semantics` label and tighten the dialog's empty space. No relabeling.

### 15. Edit-gym value hard-clips at 320 (UX Concern)
- `019_edit-gym-dialog@320x568.png` shows "Very Long Gym Name — W" with no ellipsis. Text fields normally scroll on focus, so this may be capture-only.
- **Chosen fix (verify against forui first):** check forui `FTextField` docs for value-scrolling/ellipsis behavior; change code only if interactive clipping is confirmed.

### 16. Polish bundle (partially selected)
- **Selected:** darken inactive bottom-nav label color (unreadably faint, all screens); link seeded sessions' sets to real exercise IDs in `test/helpers/test_fixtures.dart` (fixes `011` showing "0 sessions" and `012` sets named "Exercise 1"/"Exercise 2"); verify `016` "Start this workout" CTA contrast after fix 1 (should be resolved by the background fix — code only if still broken).
- **Not selected:** Feed chevron gap at 320 (excluded), intl plural infrastructure (deferred).

---

## Verification workflow (chosen)

Sweep per batch: implement High → run `pwsh run-visual-tests.ps1` + inspect changed captures + `flutter analyze` + `flutter test` → then Medium → same gate → then Low → same gate.

## Excluded / rejected options (for the record)

- Fix 1: FScaffold per page (rejected), opaque:false + barrierColor (rejected).
- Fix 2: min/max captions only, no labels (rejected).
- Fix 3: Wrap-instead-of-Row, two-row layout (rejected).
- Fix 4: cap cell height, scroll-to-selected-day (rejected).
- Fix 5: bigger static gap, reserve-space-without-doc-check (rejected in favor of docs-first).
- Fix 6+7: minimal wrap patch, popover (rejected).
- Fix 8: border + text label, FBadge (rejected).
- Fix 9: intl plural messages, defer (rejected).
- Fix 10: retune FlexibleSpaceBar, leave as-is (rejected).
- Fix 11: patch worst screens only, defer (rejected).
- Fix 12: fixed card height, leave as-is (rejected).
- Fix 13: pin absolute dates, defer (rejected — using single captured now + offsets instead).
- Fix 14: labeled Discard button, remove discard (rejected).
- Fix 15: accept as-is, echo value below field (rejected — docs-first).
