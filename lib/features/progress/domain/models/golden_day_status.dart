class GoldenDayStatus {
  final DateTime goldenDayDate;
  final bool hasReachedGoldenDay;
  final int trainingsInCurrentBlock;
  final int currentBlockIndex;
  final List<int> trainingsByBlock;
  final bool isCurrentBlockQualified;
  final bool isDelayed;
  final int qualifiedWeeks;
  final int requiredQualifiedWeeks;
  final int penaltyWeeks;

  const GoldenDayStatus({
    required this.goldenDayDate,
    required this.hasReachedGoldenDay,
    required this.trainingsInCurrentBlock,
    required this.currentBlockIndex,
    required this.trainingsByBlock,
    required this.isCurrentBlockQualified,
    required this.isDelayed,
    required this.qualifiedWeeks,
    required this.requiredQualifiedWeeks,
    required this.penaltyWeeks,
  });
}
