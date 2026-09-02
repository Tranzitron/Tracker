// Layout overflow sweep (Windows desktop regression).
// ignore_for_file: avoid_print
//
// Pumps the full app stack (ForUI desktop theme, real Isar data) at the window
// sizes a Windows desktop session can hit - the 320x568 minimum set by
// `window_size`, a small 800x600 window and the 1280x720 default - and visits
// every page, dialog and sheet. Any RenderFlex/RenderBox overflow throws
// through FlutterError and fails the sweep; the last "SWEEP:" line names the
// offending page.
//
// The test font is wider than Inter, so this over-reports relative to real
// Windows rendering - a deliberate safety margin.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:tracker/data/repositories/tracker_repository.dart';
import 'package:tracker/data/services/seed.dart';
import 'package:tracker/domain/models/exercise.dart';
import 'package:tracker/domain/models/graph_config.dart';
import 'package:tracker/domain/models/gym.dart';
import 'package:tracker/domain/models/workout_session.dart';
import 'package:tracker/domain/models/workout_set.dart';
import 'package:tracker/domain/models/workout_split.dart';
import 'package:tracker/main.dart';
import 'package:tracker/ui/analytics/widgets/graph_editor.dart';
import 'package:tracker/ui/analytics/widgets/progression_page.dart';
import 'package:tracker/ui/core/ui/repository_scope.dart';
import 'package:tracker/ui/exercises/widgets/exercise_detail_page.dart';
import 'package:tracker/ui/exercises/widgets/exercises_page.dart';
import 'package:tracker/ui/exercises/widgets/new_exercise_page.dart';
import 'package:tracker/ui/feed/widgets/feed_page.dart';
import 'package:tracker/ui/history/widgets/calendar/history_calendar.dart';
import 'package:tracker/ui/history/widgets/history_page.dart';
import 'package:tracker/ui/history/widgets/session_detail_page.dart';
import 'package:tracker/ui/settings/view_models/settings_cubit.dart';
import 'package:tracker/ui/settings/widgets/gyms_page.dart';
import 'package:tracker/ui/settings/widgets/settings_page.dart';
import 'package:tracker/ui/workout/view_models/workout_cubit.dart';
import 'package:tracker/ui/workout/widgets/editor_page.dart';
import 'package:tracker/ui/workout/widgets/exercise_picker_page.dart';
import 'package:tracker/ui/workout/widgets/gym_picker.dart';
import 'package:tracker/ui/workout/widgets/new_split_page.dart';
import 'package:tracker/ui/workout/widgets/split_day_editor_page.dart';
import 'package:tracker/ui/workout/widgets/split_day_page.dart';
import 'package:tracker/ui/workout/widgets/workout_page.dart';

import '../../testing/fakes/in_memory_storage.dart';
import '../../testing/test_fixtures.dart';
import '../../testing/test_fonts.dart';
import '../../testing/test_helpers.dart';

const _sizes = <(String, double, double)>[
  ('320x568-min', 320, 568),
  ('480x800-tall', 480, 800),
  ('640x720-snap-half', 640, 720),
  ('800x600-small', 800, 600),
  ('1280x720-default', 1280, 720),
  ('1920x1080-maximized', 1920, 1080),
];

void _mark(String what) => print('SWEEP: $what');

void main() {
  setUpAll(initIsarCore);

  for (final (label, width, height) in _sizes) {
    testWidgets('no overflow at $label', (tester) async {
      await tester.runAsync(loadTestFonts);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Isar calls are real async IO: they must run inside `runAsync` or
      // they never complete in the testWidgets fake-async zone.
      late TrackerRepository repo;
      late Isar isar;
      late SweepFixtures fixtures;
      await tester.runAsync(() async {
        isar = await openTestIsar([
          ExerciseSchema,
          GymSchema,
          WorkoutSplitSchema,
          WorkoutSessionSchema,
        ], name: 'isar_$label');
        repo = TrackerRepository(isar);
        await seedExercisesIfNeeded(repo);
        fixtures = await seedSweepFixtures(repo);
      });
      // No isar.close() teardown: Isar's native close never completes inside
      // the fake-async zone, stalling the suite. The temp DB dies with the
      // test process.

      HydratedBloc.storage = InMemoryStorage();
      final cubit = WorkoutCubit(repository: repo);
      addTearDown(cubit.close);
      cubit.startPlanWorkout(
        title: 'Push Pull Legs · Day 1',
        exercises: [
          PlanExercise(exerciseId: fixtures.benchId, name: 'Bench Press'),
          PlanExercise(
            exerciseId: fixtures.inclineId,
            name: 'Incline Bench Press',
            order: 1,
          ),
        ],
        gym: fixtures.secondaryGym,
      );
      cubit.logSet(
        exerciseId: fixtures.benchId,
        exerciseName: 'Bench Press',
        weight: 80,
        reps: 8,
      );
      cubit.logSet(
        exerciseId: fixtures.benchId,
        exerciseName: 'Bench Press',
        weight: 60,
        reps: 10,
        type: SetType.warmup,
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<WorkoutCubit>.value(value: cubit),
            BlocProvider<SettingsCubit>(
              create: (_) => SettingsCubit()
                ..addGraph(
                  const GraphConfig(title: 'Strength - upper body progression'),
                ),
              lazy: false,
            ),
          ],
          child: RepositoryScope(repository: repo, child: const MyApp()),
        ),
      );

      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );

      // Real delays outside the fake-async zone let Isar's real watcher
      // events reach the StreamBuilders; a plain pump then renders. (No
      // pumpAndSettle: loading spinners animate forever under fake time.)
      Future<void> settle() async {
        for (var i = 0; i < 2; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)),
          );
          await tester.pump();
        }
      }

      await settle();

      Future<void> visit(String page, Widget pageWidget) async {
        _mark('$page @ $label');
        unawaited(
          navigator.push(MaterialPageRoute<void>(builder: (_) => pageWidget)),
        );
        await settle();
        navigator.pop();
        await settle();
      }

      // Tab roots.
      await visit('FeedPage', const FeedPage());
      await visit('HistoryPage', const HistoryPage());
      await visit('WorkoutPage (in progress)', const WorkoutPage());
      await visit('EditorPage', const EditorPage());
      await visit('ExercisesPage', const ExercisesPage());

      // Pushed pages.
      await visit('SettingsPage', const SettingsPage());
      await visit('GymsPage', const GymsPage());
      await visit('ProgressionPage', const ProgressionPage());
      await visit('NewExercisePage', const NewExercisePage());
      await visit(
        'ExerciseDetailPage',
        ExerciseDetailPage(exercise: fixtures.bench),
      );
      await visit(
        'SessionDetailPage',
        SessionDetailPage(session: fixtures.session, gymName: 'Iron Temple'),
      );
      await visit(
        'HistoryCalendar',
        // Standalone HistoryCalendar has no FTabs Material ancestor here;
        // the real app hosts it inside the History page's tabs.
        Material(
          type: MaterialType.transparency,
          child: HistoryCalendar(
            sessions: fixtures.allSessions,
            gymNames: fixtures.gymNames,
          ),
        ),
      );
      await visit('SplitEditorPage (new)', const SplitEditorPage());
      await visit(
        'SplitEditorPage (edit)',
        SplitEditorPage(split: fixtures.split),
      );
      await visit(
        'SplitDayEditorPage',
        SplitDayEditorPage(day: fixtures.split.splitDays.first),
      );
      await visit(
        'SplitDayPage',
        SplitDayPage(
          splitTitle: fixtures.split.title,
          day: fixtures.split.splitDays.first,
        ),
      );
      await visit('ExercisePickerPage', const ExercisePickerPage());

      // Dialogs and sheets. These open from the tab page's nested navigator
      // (how the app really presents them), so pop via that navigator.
      final pageContext = tester.element(find.byType(FeedPage));

      Future<void> openAndClose(
        String what,
        Future<void> Function() open,
      ) async {
        _mark('$what @ $label');
        unawaited(open());
        await settle();
        Navigator.of(pageContext).pop();
        await settle();
      }

      await openAndClose(
        'GraphEditor dialog',
        () => showFDialog<void>(
          context: pageContext,
          builder: (_, _, _) => GraphEditor(
            exercises: fixtures.exercises,
            initial: const GraphConfig(title: 'Strength - upper body'),
          ),
        ),
      );
      await openAndClose(
        'EditGymDialog',
        () => showFDialog<void>(
          context: pageContext,
          builder: (_, _, _) => EditGymDialog(
            title: 'Edit Gym',
            initial: Gym(
              name: 'Very Long Gym Name - Westfield Century City',
              description: 'Busy hours',
              order: 1,
            ),
          ),
        ),
      );
      await openAndClose(
        'Gym picker sheet',
        () => promptGym(pageContext, fixtures.allGyms),
      );

      // End-workout confirmation dialog (in-progress WorkoutPage).
      _mark('End-workout dialog @ $label');
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const WorkoutPage()),
        ),
      );
      await settle();
      await tester.ensureVisible(find.text('End Workout'));
      await settle();
      await tester.tap(find.text('End Workout'));
      await settle();
      await tester.tap(find.text('Keep going'));
      await settle();

      await tester.runAsync(cubit.endWorkout);
      _mark('done @ $label');

      // Fire any pending hydration-debounce timers before the binding checks
      // for leaked timers, and restore the platform override before the
      // foundation invariant check (addTearDown runs too late for both).
      await tester.pump(const Duration(seconds: 5));
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
