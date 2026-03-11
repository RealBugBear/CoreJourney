import 'package:corejourney/features/progress/domain/services/progress_service.dart';
import 'package:corejourney/features/training/presentation/providers/training_flow_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProgressService extends Mock implements ProgressService {}

void main() {
  late TrainingFlowNotifier notifier;
  late MockProgressService progressService;

  setUp(() {
    progressService = MockProgressService();
    notifier = TrainingFlowNotifier(progressService);
  });

  group('TrainingFlowNotifier regression', () {
    test('routine starts directly in exercise', () {
      notifier.startTraining(mode: TrainingMode.routine);

      expect(notifier.state.mode, TrainingMode.routine);
      expect(notifier.state.screenType, TrainingScreenType.exercise);
      expect(notifier.state.currentExerciseIndex, 0);
    });

    test('tutorial normal goes intro -> position', () {
      notifier.startTraining(
          mode: TrainingMode.tutorial, compactTutorial: false);
      notifier.nextScreen();

      expect(notifier.state.screenType, TrainingScreenType.position);
      expect(notifier.state.currentExerciseIndex, 0);
    });

    test('tutorial compact goes intro -> movement', () {
      notifier.startTraining(
          mode: TrainingMode.tutorial, compactTutorial: true);
      notifier.nextScreen();

      expect(notifier.state.screenType, TrainingScreenType.movement);
      expect(notifier.state.currentExerciseIndex, 0);
    });

    test('tutorial compact next exercise returns to movement step', () {
      notifier.startTraining(
          mode: TrainingMode.tutorial, compactTutorial: true);
      notifier.nextScreen(); // intro -> movement
      notifier.nextScreen(); // movement -> exercise
      notifier.nextScreen(); // exercise -> next movement (exercise 2)

      expect(notifier.state.currentExerciseIndex, 1);
      expect(notifier.state.screenType, TrainingScreenType.movement);
    });

    test('routine previous on first exercise stays on first exercise', () {
      notifier.startTraining(mode: TrainingMode.routine);
      notifier.previousScreen();

      expect(notifier.state.currentExerciseIndex, 0);
      expect(notifier.state.screenType, TrainingScreenType.exercise);
    });
  });
}
