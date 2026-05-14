import 'dart:async';

import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/services/metronome_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal holdRest exercise fixture (1 rep, 7 beats, no audio in tests)
const _holdEx = Exercise(
  id: 'test_hold',
  packageId: 'test',
  sequenceNumber: 1,
  titleDe: 'Test', titleEn: 'Test',
  positionInstructionsDe: [], positionInstructionsEn: [],
  movementInstructionsDe: [], movementInstructionsEn: [],
  executionGuideDe: '', executionGuideEn: '',
  durationSeconds: 7, repetitions: 1,
  imagePath: '',
  rhythmType: RhythmType.holdRest,
  holdSeconds: 7, restSeconds: 3,
);

void main() {
  group('MetronomeService — holdRest', () {
    test('emits beats 1..7 then allRepsComplete for 1-rep exercise', () async {
      final svc = MetronomeService(
        tempoSeconds: 0.001,
        restDuration: Duration.zero,
        enableAudio: false,
      );

      final beats = <int>[];
      bool done = false;
      svc.beatStream.listen(beats.add);
      svc.allRepsComplete.listen((_) => done = true);

      await svc.startExercise(_holdEx);

      expect(beats, [1, 2, 3, 4, 5, 6, 7]);
      expect(done, isTrue);
      await svc.dispose();
    });

    test('emits repComplete between reps for multi-rep exercise', () async {
      const ex = Exercise(
        id: 'test_hold3',
        packageId: 'test',
        sequenceNumber: 1,
        titleDe: 'T', titleEn: 'T',
        positionInstructionsDe: [], positionInstructionsEn: [],
        movementInstructionsDe: [], movementInstructionsEn: [],
        executionGuideDe: '', executionGuideEn: '',
        durationSeconds: 7, repetitions: 3,
        imagePath: '',
        rhythmType: RhythmType.holdRest,
      );
      final svc = MetronomeService(
        tempoSeconds: 0.001,
        restDuration: Duration.zero,
        enableAudio: false,
      );

      int repCompleteCount = 0;
      bool done = false;
      svc.repComplete.listen((_) => repCompleteCount++);
      svc.allRepsComplete.listen((_) => done = true);

      await svc.startExercise(ex);

      expect(repCompleteCount, 3);
      expect(done, isTrue);
      await svc.dispose();
    });

    test('dispose cancels running exercise', () async {
      final svc = MetronomeService(
        tempoSeconds: 1.0, // slow — would take 7s normally
        restDuration: const Duration(seconds: 3),
        enableAudio: false,
      );

      bool done = false;
      svc.allRepsComplete.listen((_) => done = true);

      // Start but don't await — dispose immediately
      unawaited(svc.startExercise(_holdEx));
      await Future.delayed(const Duration(milliseconds: 10));
      await svc.dispose();

      // Give any lingering callbacks a moment
      await Future.delayed(const Duration(milliseconds: 20));
      expect(done, isFalse);
    });
  });

  group('MetronomeService — phased', () {
    test('emits phaseTransition between phases', () async {
      const ex = Exercise(
        id: 'test_phased',
        packageId: 'test',
        sequenceNumber: 1,
        titleDe: 'T', titleEn: 'T',
        positionInstructionsDe: [], positionInstructionsEn: [],
        movementInstructionsDe: [], movementInstructionsEn: [],
        executionGuideDe: '', executionGuideEn: '',
        durationSeconds: 6, repetitions: 1,
        imagePath: '',
        rhythmType: RhythmType.phased,
        phases: [
          ExercisePhase(labelDe: 'Hoch', labelEn: 'Up', durationSeconds: 3),
          ExercisePhase(labelDe: 'Runter', labelEn: 'Down', durationSeconds: 3),
        ],
      );
      final svc = MetronomeService(
        tempoSeconds: 0.001,
        restDuration: Duration.zero,
        enableAudio: false,
      );

      int transitionCount = 0;
      bool done = false;
      svc.phaseTransition.listen((_) => transitionCount++);
      svc.allRepsComplete.listen((_) => done = true);

      await svc.startExercise(ex);

      // 1 transition between 2 phases (not after last)
      expect(transitionCount, 1);
      expect(done, isTrue);
      await svc.dispose();
    });
  });
}
