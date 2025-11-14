# tracker

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
