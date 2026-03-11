import 'package:corejourney/core/training/training_tempo_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('training tempo defaults regression', () {
    test('exercise 1 defaults to 3.0s', () {
      expect(
        resolveInitialTempoSeconds(exerciseNumber: 1),
        3.0,
      );
    });

    test('exercise 6 defaults to 7.0s', () {
      expect(
        resolveInitialTempoSeconds(exerciseNumber: 6),
        7.0,
      );
    });

    test('early exercise clamps low persisted tempo to 1.0s', () {
      expect(
        resolveInitialTempoSeconds(
          exerciseNumber: 2,
          persistedTempoSeconds: 0.2,
        ),
        1.0,
      );
    });

    test('early exercise clamps high persisted tempo to 7.0s', () {
      expect(
        resolveInitialTempoSeconds(
          exerciseNumber: 4,
          persistedTempoSeconds: 9.0,
        ),
        7.0,
      );
    });

    test('late exercise clamps low persisted tempo to 2.0s', () {
      expect(
        resolveInitialTempoSeconds(
          exerciseNumber: 7,
          persistedTempoSeconds: 1.0,
        ),
        2.0,
      );
    });

    test('late exercise keeps valid persisted tempo', () {
      expect(
        resolveInitialTempoSeconds(
          exerciseNumber: 6,
          persistedTempoSeconds: 3.5,
        ),
        3.5,
      );
    });
  });
}
