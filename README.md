# Tracker

A new Flutter project.

## Ideas

### Relocate Settings

Put the settings button in the home feed at the top right.
This will give place to put the current workout button in the bottom bar
Home, History, CurrentWorkout, WorkoutsEditor, Exercices

Instead of a standalone foreground page, settings will be a children page of home, just like
NewSplit
is to his parent WorkoutEditor.
That way we can keep for all pages, the standardised back button on the left in the AppBar of
pages, the title, and an optional button.
Also removes the need to find a way to easily show the user that there is a current workout going on
without hiding the page with a floating action button or something of the sort.

- [x] Move settings to Feed
- [ ] Add Current Workout to navigation

## Git hooks

This repo uses **Husky (the Dart package, pub.dev)** to run a `pre-commit`
hook that formats Dart code with `dart fix --apply` (then `dart format .`),
re-staging whatever the formatter touched.

The hook script is **project-specific**: `.husky/pre-commit` is committed to
the repo, so every clone carries the same hook. Git runs it once
`core.hooksPath` points at the `.husky/` directory. On a fresh clone, run:

```bash
git config core.hooksPath .husky   # one-time activation
git commit -m "..."                # dart fix --apply + dart format run here
```
