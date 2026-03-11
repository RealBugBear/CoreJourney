import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../progress/domain/services/progress_service.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../domain/models/exercise.dart';

enum TrainingScreenType {
  intro,
  position, // Position screen (Ausgangsposition)
  movement, // Movement description (Bewegung)
  exercise, // Actual exercise execution
  outro
}

enum TrainingMode {
  tutorial,
  routine,
}

class TrainingFlowState {
  final int currentExerciseIndex; // 0-6
  final TrainingScreenType screenType;
  final bool isCompleted;
  final TrainingMode mode;
  final bool compactTutorial;

  const TrainingFlowState({
    required this.currentExerciseIndex,
    required this.screenType,
    required this.isCompleted,
    required this.mode,
    this.compactTutorial = false,
  });

  TrainingFlowState copyWith({
    int? currentExerciseIndex,
    TrainingScreenType? screenType,
    bool? isCompleted,
    TrainingMode? mode,
    bool? compactTutorial,
  }) {
    return TrainingFlowState(
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      screenType: screenType ?? this.screenType,
      isCompleted: isCompleted ?? this.isCompleted,
      mode: mode ?? this.mode,
      compactTutorial: compactTutorial ?? this.compactTutorial,
    );
  }

  Exercise? getCurrentExercise() {
    if (currentExerciseIndex >= 0 && currentExerciseIndex < exercises.length) {
      return exercises[currentExerciseIndex];
    }
    return null;
  }

  bool get isLastExercise => currentExerciseIndex == exercises.length - 1;
}

class TrainingFlowNotifier extends StateNotifier<TrainingFlowState> {
  final ProgressService _progressService;

  TrainingFlowNotifier(this._progressService)
      : super(const TrainingFlowState(
          currentExerciseIndex: 0,
          screenType: TrainingScreenType.intro,
          isCompleted: false,
          mode: TrainingMode.tutorial,
          compactTutorial: false,
        ));

  void startTraining({
    TrainingMode mode = TrainingMode.tutorial,
    bool compactTutorial = false,
  }) {
    final initialScreen = mode == TrainingMode.routine
        ? TrainingScreenType.exercise
        : TrainingScreenType.intro;
    state = TrainingFlowState(
      currentExerciseIndex: 0,
      screenType: initialScreen,
      isCompleted: false,
      mode: mode,
      compactTutorial: compactTutorial,
    );
  }

  void nextScreen() {
    if (state.isCompleted) return;

    switch (state.screenType) {
      case TrainingScreenType.intro:
        // Intro → Position 1 (tutorial) or Exercise 1 (routine)
        state = state.copyWith(
          currentExerciseIndex: 0,
          screenType: state.mode == TrainingMode.routine
              ? TrainingScreenType.exercise
              : state.compactTutorial
                  ? TrainingScreenType.movement
                  : TrainingScreenType.position,
        );
        break;

      case TrainingScreenType.position:
        // Position → Movement
        state = state.copyWith(
          screenType: TrainingScreenType.movement,
        );
        break;

      case TrainingScreenType.movement:
        // Movement → Exercise
        state = state.copyWith(
          screenType: TrainingScreenType.exercise,
        );
        break;

      case TrainingScreenType.exercise:
        // Exercise → Next Position or Outro
        if (state.isLastExercise) {
          // Last exercise → Outro
          state = state.copyWith(
            screenType: TrainingScreenType.outro,
          );
        } else {
          // Next screen depends on selected mode.
          state = state.copyWith(
            currentExerciseIndex: state.currentExerciseIndex + 1,
            screenType: state.mode == TrainingMode.routine
                ? TrainingScreenType.exercise
                : state.compactTutorial
                    ? TrainingScreenType.movement
                    : TrainingScreenType.position,
          );
        }
        break;

      case TrainingScreenType.outro:
        // Outro → Completed
        _completeTrainingAndFinish();
        break;
    }
  }

  Future<void> _completeTrainingAndFinish() async {
    await _completeTraining();
    state = state.copyWith(isCompleted: true);
  }

  void previousScreen() {
    switch (state.screenType) {
      case TrainingScreenType.intro:
        // Can't go back from intro
        break;

      case TrainingScreenType.position:
        if (state.mode == TrainingMode.routine) {
          if (state.currentExerciseIndex == 0) {
            state = state.copyWith(screenType: TrainingScreenType.intro);
          } else {
            state = state.copyWith(
              currentExerciseIndex: state.currentExerciseIndex - 1,
              screenType: TrainingScreenType.exercise,
            );
          }
          break;
        }
        // Position → Previous Exercise or Intro
        if (state.currentExerciseIndex == 0) {
          // First position → Intro
          state = state.copyWith(
            screenType: TrainingScreenType.intro,
          );
        } else {
          // Previous exercise
          state = state.copyWith(
            currentExerciseIndex: state.currentExerciseIndex - 1,
            screenType: TrainingScreenType.exercise,
          );
        }
        break;

      case TrainingScreenType.movement:
        if (state.mode == TrainingMode.routine) {
          state = state.copyWith(
            screenType: TrainingScreenType.exercise,
          );
          break;
        }
        // Movement → Position
        state = state.copyWith(
          screenType: TrainingScreenType.position,
        );
        break;

      case TrainingScreenType.exercise:
        if (state.mode == TrainingMode.routine) {
          if (state.currentExerciseIndex == 0) {
            // In hands-free quick mode, don't bounce back to intro.
            return;
          } else {
            state = state.copyWith(
              currentExerciseIndex: state.currentExerciseIndex - 1,
              screenType: TrainingScreenType.exercise,
            );
          }
        } else {
          // Exercise → Movement
          state = state.copyWith(
            screenType: TrainingScreenType.movement,
          );
        }
        break;

      case TrainingScreenType.outro:
        // Outro → Last Exercise
        state = state.copyWith(
          currentExerciseIndex: exercises.length - 1,
          screenType: TrainingScreenType.exercise,
        );
        break;
    }
  }

  Future<void> _completeTraining() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Record training session in progress tracking
      await _progressService.recordTrainingSession(user.uid);

      debugPrint('[TrainingFlow] Training session recorded successfully');
    } catch (e) {
      debugPrint('[TrainingFlow] Error recording training session: $e');
    }
  }

  void reset() {
    state = const TrainingFlowState(
      currentExerciseIndex: 0,
      screenType: TrainingScreenType.intro,
      isCompleted: false,
      mode: TrainingMode.tutorial,
      compactTutorial: false,
    );
  }
}

final trainingFlowProvider =
    StateNotifierProvider<TrainingFlowNotifier, TrainingFlowState>((ref) {
  final progressService = ref.watch(progressServiceProvider);

  return TrainingFlowNotifier(progressService);
});
