double defaultTempoForExercise(int exerciseNumber) {
  return exerciseNumber <= 5 ? 3.0 : 7.0;
}

double minTempoForExercise(int exerciseNumber) {
  return exerciseNumber <= 5 ? 1.0 : 2.0;
}

double maxTempoForExercise(int exerciseNumber) {
  return exerciseNumber <= 5 ? 7.0 : 12.0;
}

double resolveInitialTempoSeconds({
  required int exerciseNumber,
  double? persistedTempoSeconds,
}) {
  final raw = persistedTempoSeconds ?? defaultTempoForExercise(exerciseNumber);
  return raw.clamp(
    minTempoForExercise(exerciseNumber),
    maxTempoForExercise(exerciseNumber),
  );
}
