import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../progress/domain/services/progress_service.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../domain/models/exercise.dart';

enum TrainingScreenType { 
  intro, 
  position,      // Position screen (Ausgangsposition)
  movement,      // Movement description (Bewegung)
  exercise,      // Actual exercise execution
  outro 
}


class TrainingFlowState {
  final int currentExerciseIndex; // 0-6
  final TrainingScreenType screenType;
  final bool isCompleted;

  const TrainingFlowState({
    required this.currentExerciseIndex,
    required this.screenType,
    required this.isCompleted,
  });

  TrainingFlowState copyWith({
    int? currentExerciseIndex,
    TrainingScreenType? screenType,
    bool? isCompleted,
  }) {
    return TrainingFlowState(
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      screenType: screenType ?? this.screenType,
      isCompleted: isCompleted ?? this.isCompleted,
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
        ));


  void startTraining() {
    state = const TrainingFlowState(
      currentExerciseIndex: 0,
      screenType: TrainingScreenType.intro,
      isCompleted: false,
    );
  }

  void nextScreen() {
    if (state.isCompleted) return;

    switch (state.screenType) {
      case TrainingScreenType.intro:
        // Intro → Position 1
        state = state.copyWith(
          currentExerciseIndex: 0,
          screenType: TrainingScreenType.position,
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
          // Next position
          state = state.copyWith(
            currentExerciseIndex: state.currentExerciseIndex + 1,
            screenType: TrainingScreenType.position,
          );
        }
        break;

      case TrainingScreenType.outro:
        // Outro → Completed
        _completeTraining();
        state = state.copyWith(isCompleted: true);
        break;
    }
  }

  void previousScreen() {
    switch (state.screenType) {
      case TrainingScreenType.intro:
        // Can't go back from intro
        break;

      case TrainingScreenType.position:
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
        // Movement → Position
        state = state.copyWith(
          screenType: TrainingScreenType.position,
        );
        break;

      case TrainingScreenType.exercise:
        // Exercise → Movement
        state = state.copyWith(
          screenType: TrainingScreenType.movement,
        );
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
    );
  }
}

final trainingFlowProvider =
    StateNotifierProvider<TrainingFlowNotifier, TrainingFlowState>((ref) {
  final progressService = ref.watch(progressServiceProvider);

  return TrainingFlowNotifier(progressService);
});

