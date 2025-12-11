import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/training_flow_provider.dart';
import 'training_intro_screen.dart';
import 'training_position_screen.dart';
import 'training_movement_screen.dart';
import 'training_exercise_screen.dart';
import 'training_outro_screen.dart';

class TrainingFlowScreen extends ConsumerWidget {
  const TrainingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(trainingFlowProvider);
    final flowNotifier = ref.read(trainingFlowProvider.notifier);

    // If completed, navigate back to dashboard
    if (flowState.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(true); // Return true to indicate completion
      });
    }

    return _buildCurrentScreen(context, flowState, flowNotifier);
  }

  Widget _buildCurrentScreen(
    BuildContext context,
    TrainingFlowState state,
    TrainingFlowNotifier notifier,
  ) {
    switch (state.screenType) {
      case TrainingScreenType.intro:
        return TrainingIntroScreen(
          onStart: () => notifier.nextScreen(),
        );

      case TrainingScreenType.position:
        final exercise = state.getCurrentExercise();
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Fehler: Übung nicht gefunden')),
          );
        }
        return TrainingPositionScreen(
          exercise: exercise,
          onContinue: () => notifier.nextScreen(),
        );

      case TrainingScreenType.movement:
        final exercise = state.getCurrentExercise();
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Fehler: Übung nicht gefunden')),
          );
        }
        return TrainingMovementScreen(
          exercise: exercise,
          onContinue: () => notifier.nextScreen(),
        );

      case TrainingScreenType.exercise:
        final exercise = state.getCurrentExercise();
        if (exercise == null) {
          return const Scaffold(
            body: Center(child: Text('Fehler: Übung nicht gefunden')),
          );
        }
        return TrainingExerciseScreen(
          exercise: exercise,
          isLastExercise: state.isLastExercise,
          onComplete: () => notifier.nextScreen(),
        );

      case TrainingScreenType.outro:
        return TrainingOutroScreen(
          onFinish: () => notifier.nextScreen(),
        );
    }
  }
}
