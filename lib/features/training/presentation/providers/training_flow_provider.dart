import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';

// Which screen to show in the training flow
enum TrainingFlowStep {
  disclaimer,   // first-ever session only
  intro,        // session title + day + mode
  video,        // tutorial only
  position,     // tutorial only
  preparation,  // tutorial only
  movement,     // all modes — the actual exercise timer
  rest,         // brief rest between exercises
  outro,        // completion screen
}

class TrainingFlowState {
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final TrainingFlowStep step;
  final TrainingSessionMode mode;
  final bool showDisclaimer;
  final List<String> completedExerciseIds;
  final bool isComplete;

  const TrainingFlowState({
    required this.exercises,
    this.currentExerciseIndex = 0,
    this.step = TrainingFlowStep.intro,
    this.mode = TrainingSessionMode.tutorial,
    this.showDisclaimer = false,
    this.completedExerciseIds = const [],
    this.isComplete = false,
  });

  Exercise get currentExercise => exercises[currentExerciseIndex];
  bool get isLastExercise => currentExerciseIndex >= exercises.length - 1;
  int get totalExercises => exercises.length;
  double get progressFraction =>
      exercises.isEmpty ? 0 : currentExerciseIndex / exercises.length;

  TrainingFlowState copyWith({
    int? currentExerciseIndex,
    TrainingFlowStep? step,
    TrainingSessionMode? mode,
    bool? showDisclaimer,
    List<String>? completedExerciseIds,
    bool? isComplete,
  }) {
    return TrainingFlowState(
      exercises: exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      step: step ?? this.step,
      mode: mode ?? this.mode,
      showDisclaimer: showDisclaimer ?? this.showDisclaimer,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class TrainingFlowNotifier extends StateNotifier<TrainingFlowState> {
  TrainingFlowNotifier({
    required List<Exercise> exercises,
    required TrainingSessionMode mode,
    required bool requiresDisclaimer,
  }) : super(TrainingFlowState(
          exercises: exercises,
          mode: mode,
          showDisclaimer: requiresDisclaimer,
          step: requiresDisclaimer
              ? TrainingFlowStep.disclaimer
              : TrainingFlowStep.intro,
        ));

  void acceptDisclaimer() {
    state = state.copyWith(
      showDisclaimer: false,
      step: TrainingFlowStep.intro,
    );
  }

  void startSession() {
    state = state.copyWith(
      step: state.mode == TrainingSessionMode.tutorial
          ? TrainingFlowStep.video
          : TrainingFlowStep.movement,
    );
  }

  void videoReady() {
    state = state.copyWith(step: TrainingFlowStep.position);
  }

  void positionReady() {
    state = state.copyWith(step: TrainingFlowStep.preparation);
  }

  void preparationReady() {
    state = state.copyWith(step: TrainingFlowStep.movement);
  }

  void exerciseComplete() {
    final completed = [
      ...state.completedExerciseIds,
      state.currentExercise.id,
    ];

    if (state.isLastExercise) {
      state = state.copyWith(
        completedExerciseIds: completed,
        step: TrainingFlowStep.outro,
        isComplete: true,
      );
    } else {
      state = state.copyWith(
        completedExerciseIds: completed,
        currentExerciseIndex: state.currentExerciseIndex + 1,
        step: TrainingFlowStep.rest,
      );
    }
  }

  void restComplete() {
    state = state.copyWith(
      step: state.mode == TrainingSessionMode.tutorial
          ? TrainingFlowStep.video
          : TrainingFlowStep.movement,
    );
  }

  void setMode(TrainingSessionMode mode) {
    state = state.copyWith(mode: mode);
  }
}

List<Exercise> _exercisesForPackage(String packageId) {
  switch (packageId) {
    case 'spinal_galant':
      return spinalGalantExercises;
    case 'tlr':
      return tlrExercises;
    case 'moro':
    default:
      return moroExercises;
  }
}

final trainingFlowProvider = StateNotifierProvider.autoDispose
    .family<TrainingFlowNotifier, TrainingFlowState, String>((ref, packageId) {
  return TrainingFlowNotifier(
    exercises: _exercisesForPackage(packageId),
    mode: TrainingSessionMode.tutorial,
    requiresDisclaimer: false, // TODO: check progress entry
  );
});
