import 'reflex_questionnaire.dart';

class ReflexQuestionnaireScore {
  const ReflexQuestionnaireScore({
    required this.reflexScores,
    required this.warningQuestionIds,
  });

  final Map<PrimitiveReflex, ReflexScoreResult> reflexScores;
  final List<String> warningQuestionIds;
}

class ReflexScoreResult {
  const ReflexScoreResult({
    required this.reflex,
    required this.yesCount,
    required this.answeredCount,
    required this.possibleCount,
    required this.percent,
    required this.band,
  });

  final PrimitiveReflex reflex;
  final int yesCount;
  final int answeredCount;
  final int possibleCount;
  final double percent;
  final ReflexScoreBand band;

  double get coveragePercent =>
      possibleCount == 0 ? 0 : (answeredCount / possibleCount) * 100;

  Map<String, dynamic> toJson() => {
        'reflex': reflex.name,
        'yes_count': yesCount,
        'answered_count': answeredCount,
        'possible_count': possibleCount,
        'percent': percent,
        'coverage_percent': coveragePercent,
        'band': band.name,
      };
}

class ReflexProfileScoringService {
  const ReflexProfileScoringService();

  ReflexQuestionnaireScore score({
    required ReflexQuestionnaireDefinition definition,
    required Map<String, ReflexAnswerValue> answers,
  }) {
    final buckets = <PrimitiveReflex, _ScoreBucket>{
      for (final reflex in PrimitiveReflex.values) reflex: _ScoreBucket(),
    };
    final warningQuestionIds = <String>[];

    for (final question in definition.questions) {
      final answer = answers[question.id];

      if (question.warningRule ==
              ReflexWarningRule.professionalClearanceRequired &&
          answer?.isAffirmative == true) {
        warningQuestionIds.add(question.id);
      }

      if (!question.contributesToScore) continue;

      for (final reflex in question.reflexes) {
        final bucket = buckets[reflex]!;
        bucket.possibleCount += 1;
        if (answer == null || answer.yesNoUnknown == null) continue;
        bucket.answeredCount += 1;
        if (answer.isAffirmative) bucket.yesCount += 1;
      }
    }

    return ReflexQuestionnaireScore(
      warningQuestionIds: warningQuestionIds,
      reflexScores: {
        for (final entry in buckets.entries)
          if (entry.value.possibleCount > 0)
            entry.key: entry.value.toResult(entry.key, definition.scoring),
      },
    );
  }
}

class _ScoreBucket {
  int yesCount = 0;
  int answeredCount = 0;
  int possibleCount = 0;

  ReflexScoreResult toResult(
    PrimitiveReflex reflex,
    ReflexScoringDefinition scoring,
  ) {
    final percent = answeredCount == 0 ? 0.0 : (yesCount / answeredCount) * 100;
    return ReflexScoreResult(
      reflex: reflex,
      yesCount: yesCount,
      answeredCount: answeredCount,
      possibleCount: possibleCount,
      percent: percent,
      band: scoring.bandFor(percent: percent, answeredCount: answeredCount),
    );
  }
}
