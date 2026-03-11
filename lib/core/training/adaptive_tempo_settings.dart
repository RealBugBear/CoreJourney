import 'package:shared_preferences/shared_preferences.dart';

import 'training_tempo_defaults.dart';

class AdaptiveTempoSettings {
  static const String _tempoKeyPrefix = 'adaptive_tempo_exercise_';

  static String _tempoKey(int exerciseNumber) =>
      '$_tempoKeyPrefix$exerciseNumber';

  static double? tempoForExerciseOrNull(
    SharedPreferences prefs,
    int exerciseNumber,
  ) {
    return prefs.getDouble(_tempoKey(exerciseNumber));
  }

  static Future<void> saveTempoForExercise(
    SharedPreferences prefs, {
    required int exerciseNumber,
    required double tempoSeconds,
  }) {
    final clamped = tempoSeconds.clamp(
      minTempoForExercise(exerciseNumber),
      maxTempoForExercise(exerciseNumber),
    );
    return prefs.setDouble(_tempoKey(exerciseNumber), clamped);
  }
}
