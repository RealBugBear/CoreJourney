class MoodDailyAggregate {
  final int dayKey;
  final DateTime day;
  final double? mood;
  final double? energy;
  final double? stress;

  const MoodDailyAggregate({
    required this.dayKey,
    required this.day,
    this.mood,
    this.energy,
    this.stress,
  });
}
