import 'package:hydrated_bloc/hydrated_bloc.dart';

class WorkoutState {
  final bool isInProgress;
  final DateTime? startTime;
  final List<String> completedExercises;

  WorkoutState({
    required this.isInProgress,
    this.startTime,
    this.completedExercises = const [],
  });

  factory WorkoutState.initial() => WorkoutState(
        isInProgress: true,
        startTime: DateTime.now(),
        completedExercises: [],
      );

  Map<String, dynamic> toJson() => {
        'isInProgress': isInProgress,
        'startTime': startTime?.toIso8601String(),
        'completedExercises': completedExercises,
      };

  factory WorkoutState.fromJson(Map<String, dynamic> json) => WorkoutState(
        isInProgress: json['isInProgress'] as bool,
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'])
            : null,
        completedExercises: List<String>.from(json['completedExercises'] ?? []),
      );

  WorkoutState copyWith({
    bool? isInProgress,
    DateTime? startTime,
    List<String>? completedExercises,
  }) {
    return WorkoutState(
      isInProgress: isInProgress ?? this.isInProgress,
      startTime: startTime ?? this.startTime,
      completedExercises: completedExercises ?? this.completedExercises,
    );
  }
}

class WorkoutCubit extends HydratedCubit<WorkoutState> {
  WorkoutCubit() : super(WorkoutState.initial());

  void startWorkout() {
    emit(WorkoutState(isInProgress: true, startTime: DateTime.now()));
  }

  void completeExercise(String exerciseName) {
    emit(
      state.copyWith(
        completedExercises: [...state.completedExercises, exerciseName],
      ),
    );
  }

  // void endWorkout() {
  //   emit(WorkoutState.initial());
  // }
  void endWorkout() {
    emit(WorkoutState(isInProgress: false));
  }

  @override
  WorkoutState fromJson(Map<String, dynamic> json) {
    return WorkoutState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WorkoutState state) {
    return state.toJson();
  }
}
